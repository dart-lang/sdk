// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

// For `AllocateObjectInstr::WillAllocateNewOrRemembered`
#include "vm/compiler/backend/il.h"

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/stub_code_compiler.h"

#if defined(TARGET_ARCH_IA32)

#include "vm/class_id.h"
#include "vm/code_entry_kind.h"
#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/constants.h"
#include "vm/ffi_callback_metadata.h"
#include "vm/instructions.h"
#include "vm/static_type_exactness_state.h"
#include "vm/tags.h"

#define __ assembler->

namespace dart {
namespace compiler {

// Ensures that [EAX] is a new object, if not it will be added to the remembered
// set via a leaf runtime call.
//
// WARNING: This might clobber all registers except for [EAX], [THR] and [FP].
// The caller should simply call LeaveFrame() and return.
void StubCodeCompiler::EnsureIsNewOrRemembered(bool preserve_registers) {
  // If the object is not remembered we call a leaf-runtime to add it to the
  // remembered set.
  Label done;
  __ testl(EAX, Immediate(1 << target::ObjectAlignment::kNewObjectBitPosition));
  __ BranchIf(NOT_ZERO, &done);

  {
    LeafRuntimeScope rt(assembler,
                        /*frame_size=*/2 * target::kWordSize,
                        preserve_registers);
    __ movl(Address(ESP, 1 * target::kWordSize), THR);
    __ movl(Address(ESP, 0 * target::kWordSize), EAX);
    rt.Call(kEnsureRememberedAndMarkingDeferredRuntimeEntry, 2);
  }

  __ Bind(&done);
}

// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of last argument in argument array.
//   ESP + 4*EDX : address of first argument in argument array.
//   ESP + 4*EDX + 4 : address of return value.
//   ECX : address of the runtime function to call.
//   EDX : number of arguments to the call.
// Must preserve callee saved registers EDI and EBX.
void StubCodeCompiler::GenerateCallToRuntimeStub() {
  const intptr_t thread_offset = target::NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = target::NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = target::NativeArguments::argv_offset();
  const intptr_t retval_offset = target::NativeArguments::retval_offset();

  __ movl(CODE_REG,
          Address(THR, target::Thread::call_to_runtime_stub_offset()));
  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ movl(Address(THR, target::Thread::top_exit_frame_info_offset()), EBP);

  // Mark that the thread exited generated code through a runtime call.
  __ movl(Address(THR, target::Thread::exit_through_ffi_offset()),
          Immediate(target::Thread::exit_through_runtime_call()));

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
  __ AddImmediate(
      ESP,
      Immediate(-static_cast<int32_t>(target::NativeArguments::StructSize())));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call runtime.
  __ movl(Address(ESP, thread_offset), THR);  // Set thread in NativeArgs.
  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  __ movl(Address(ESP, argc_tag_offset), EDX);  // Set argc in NativeArguments.
  // Compute argv.
  __ leal(EAX,
          Address(EBP, EDX, TIMES_4,
                  target::frame_layout.param_end_from_fp * target::kWordSize));
  __ movl(Address(ESP, argv_offset), EAX);  // Set argv in NativeArguments.
  __ addl(EAX,
          Immediate(1 * target::kWordSize));  // Retval is next to 1st argument.
  __ movl(Address(ESP, retval_offset), EAX);  // Set retval in NativeArguments.
  __ call(ECX);

  __ movl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Mark that the thread has not exited generated Dart code.
  __ movl(Address(THR, target::Thread::exit_through_ffi_offset()),
          Immediate(0));

  // Reset exit frame information in Isolate's mutator thread structure.
  __ movl(Address(THR, target::Thread::top_exit_frame_info_offset()),
          Immediate(0));

  __ LeaveFrame();

  // The following return can jump to a lazy-deopt stub, which assumes EAX
  // contains a return value and will save it in a GC-visible way.  We therefore
  // have to ensure EAX does not contain any garbage value left from the C
  // function we called (which has return type "void").
  // (See GenerateDeoptimizationSequence::saved_result_slot_from_fp.)
  __ xorl(EAX, EAX);
  __ ret();
}

void StubCodeCompiler::GenerateEnterSafepointStub() {
  __ pushal();
  __ subl(SPREG, Immediate(8));
  __ movsd(Address(SPREG, 0), XMM0);

  __ EnterFrame(0);
  __ ReserveAlignedFrameSpace(0);
  __ movl(EAX, Address(THR, kEnterSafepointRuntimeEntry.OffsetFromThread()));
  __ call(EAX);
  __ LeaveFrame();

  __ movsd(XMM0, Address(SPREG, 0));
  __ addl(SPREG, Immediate(8));
  __ popal();
  __ ret();
}

static void GenerateExitSafepointStubCommon(Assembler* assembler,
                                            uword runtime_entry_offset) {
  __ pushal();
  __ subl(SPREG, Immediate(8));
  __ movsd(Address(SPREG, 0), XMM0);

  __ EnterFrame(0);
  __ ReserveAlignedFrameSpace(0);

  // Set the execution state to VM while waiting for the safepoint to end.
  // This isn't strictly necessary but enables tests to check that we're not
  // in native code anymore. See tests/ffi/function_gc_test.dart for example.
  __ movl(Address(THR, target::Thread::execution_state_offset()),
          Immediate(target::Thread::vm_execution_state()));

  __ movl(EAX, Address(THR, runtime_entry_offset));
  __ call(EAX);
  __ LeaveFrame();

  __ movsd(XMM0, Address(SPREG, 0));
  __ addl(SPREG, Immediate(8));
  __ popal();
  __ ret();
}

void StubCodeCompiler::GenerateExitSafepointStub() {
  GenerateExitSafepointStubCommon(
      assembler, kExitSafepointRuntimeEntry.OffsetFromThread());
}

void StubCodeCompiler::GenerateExitSafepointIgnoreUnwindInProgressStub() {
  GenerateExitSafepointStubCommon(
      assembler,
      kExitSafepointIgnoreUnwindInProgressRuntimeEntry.OffsetFromThread());
}

void StubCodeCompiler::GenerateLoadBSSEntry(BSS::Relocation relocation,
                                            Register dst,
                                            Register tmp) {
  // Only used in AOT.
  __ Breakpoint();
}

// Calls a native function inside a safepoint.
//
// On entry:
//   Stack: set up for native call
//   EAX: target to call
//
// On exit:
//   Stack: preserved
//   EBX: clobbered (even though it's normally callee-saved)
void StubCodeCompiler::GenerateCallNativeThroughSafepointStub() {
  __ popl(EBX);

  __ movl(ECX, compiler::Immediate(target::Thread::exit_through_ffi()));
  __ TransitionGeneratedToNative(EAX, FPREG, ECX /*volatile*/,
                                 /*enter_safepoint=*/true);
  __ call(EAX);
  __ TransitionNativeToGenerated(ECX /*volatile*/, /*leave_safepoint=*/true);

  __ jmp(EBX);
}

void StubCodeCompiler::GenerateFfiCallbackTrampolineStub() {
  Label ret_4;

  // EAX is volatile and doesn't hold any arguments.
  COMPILE_ASSERT(!IsArgumentRegister(EAX) && !IsCalleeSavedRegister(EAX));

  Label body, load_tramp_addr;
  const intptr_t kCallLength = 5;
  for (intptr_t i = 0; i < FfiCallbackMetadata::NumCallbackTrampolinesPerPage();
       ++i) {
    // The FfiCallbackMetadata table is keyed by the trampoline entry point. So
    // look up the current PC, then jump to the shared section. There's no easy
    // way to get the PC in ia32 so we have to do a call, grab the return adress
    // from the stack, then return here (mismatched call/ret causes problems),
    // then jump to the shared section.
    const intptr_t size_before = __ CodeSize();
    __ call(&load_tramp_addr);
    const intptr_t size_after = __ CodeSize();
    ASSERT_EQUAL(size_after - size_before, kCallLength);
    __ jmp(&body);
  }

  ASSERT_EQUAL(__ CodeSize(),
               FfiCallbackMetadata::kNativeCallbackTrampolineSize *
                   FfiCallbackMetadata::NumCallbackTrampolinesPerPage());

  const intptr_t shared_stub_start = __ CodeSize();

  __ Bind(&load_tramp_addr);
  // Load the return adress into EAX, and subtract the size of the call
  // instruction. This is our original trampoline address.
  __ movl(EAX, Address(SPREG, 0));
  __ subl(EAX, Immediate(kCallLength));
  __ ret();

  __ Bind(&body);

  // Save THR and EBX which are callee-saved.
  __ pushl(THR);
  __ pushl(EBX);

  // THR & return address
  COMPILE_ASSERT(FfiCallbackMetadata::kNativeCallbackTrampolineStackDelta == 4);

  // Load the thread, verify the callback ID and exit the safepoint.
  //
  // We exit the safepoint inside DLRT_GetFfiCallbackMetadata in order to safe
  // code size on this shared stub.
  {
    __ EnterFrame(0);
    // entry_point, trampoline_type, &trampoline_type, &entry_point, trampoline
    //                              ^------ GetFfiCallbackMetadata args ------^
    __ ReserveAlignedFrameSpace(5 * target::kWordSize);

    // Trampoline arg.
    __ movl(Address(SPREG, 0 * target::kWordSize), EAX);

    // Pointer to trampoline type stack slot.
    __ movl(EAX, SPREG);
    __ addl(EAX, Immediate(3 * target::kWordSize));
    __ movl(Address(SPREG, 2 * target::kWordSize), EAX);

    // Pointer to entry point stack slot.
    __ addl(EAX, Immediate(target::kWordSize));
    __ movl(Address(SPREG, 1 * target::kWordSize), EAX);

    __ movl(EAX,
            Immediate(reinterpret_cast<int64_t>(DLRT_GetFfiCallbackMetadata)));
    __ call(EAX);
    __ movl(THR, EAX);

    // Save the trampoline type in EBX, and the entry point in ECX.
    __ movl(EBX, Address(SPREG, 3 * target::kWordSize));
    __ movl(ECX, Address(SPREG, 4 * target::kWordSize));

    __ LeaveFrame();

    // Save the trampoline type to the stack, because we'll need it after the
    // call to decide whether to ret() or ret(4).
    __ pushl(EBX);
  }

  COMPILE_ASSERT(!IsCalleeSavedRegister(ECX) && !IsArgumentRegister(ECX));
  COMPILE_ASSERT(ECX != THR);

  // On entry to the function, there will be two extra slots on the stack:
  // the saved THR and the return address. The target will know to skip them.
  __ call(ECX);

  // Takes care to not clobber *any* registers (besides scratch).
  __ EnterFullSafepoint(/*scratch=*/ECX);

  // Pop the trampoline type into ECX.
  __ popl(ECX);

  // Restore callee-saved registers.
  __ popl(EBX);
  __ popl(THR);

  __ cmpl(ECX, Immediate(static_cast<uword>(
                   FfiCallbackMetadata::TrampolineType::kSync)));
  __ j(NOT_EQUAL, &ret_4, Assembler::kNearJump);
  __ ret();

  __ Bind(&ret_4);
  __ ret(Immediate(4));

  // 'kNativeCallbackSharedStubSize' is an upper bound because the exact
  // instruction size can vary slightly based on OS calling conventions.
  ASSERT_LESS_OR_EQUAL(__ CodeSize() - shared_stub_start,
                       FfiCallbackMetadata::kNativeCallbackSharedStubSize);
  ASSERT_LESS_OR_EQUAL(__ CodeSize(), FfiCallbackMetadata::kPageSize);

#if defined(DEBUG)
  while (__ CodeSize() < FfiCallbackMetadata::kPageSize) {
    __ Breakpoint();
  }
#endif
}

void StubCodeCompiler::GenerateSharedStubGeneric(
    bool save_fpu_registers,
    intptr_t self_code_stub_offset_from_thread,
    bool allow_return,
    std::function<void()> perform_runtime_call) {
  // Only used in AOT.
  __ Breakpoint();
}

void StubCodeCompiler::GenerateSharedStub(
    bool save_fpu_registers,
    const RuntimeEntry* target,
    intptr_t self_code_stub_offset_from_thread,
    bool allow_return,
    bool store_runtime_result_in_result_register) {
  // Only used in AOT.
  __ Breakpoint();
}

void StubCodeCompiler::GenerateRangeError(bool with_fpu_regs) {
  // Only used in AOT.
  __ Breakpoint();
}

void StubCodeCompiler::GenerateWriteError(bool with_fpu_regs) {
  // Only used in AOT.
  __ Breakpoint();
}

void StubCodeCompiler::GenerateDispatchTableNullErrorStub() {
  // Only used in AOT.
  __ Breakpoint();
}

// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of return value.
//   EAX : address of first argument in argument array.
//   ECX : address of the native function to call.
//   EDX : argc_tag including number of arguments and function kind.
static void GenerateCallNativeWithWrapperStub(Assembler* assembler,
                                              Address wrapper_address) {
  const intptr_t native_args_struct_offset =
      target::NativeEntry::kNumCallWrapperArguments * target::kWordSize;
  const intptr_t thread_offset =
      target::NativeArguments::thread_offset() + native_args_struct_offset;
  const intptr_t argc_tag_offset =
      target::NativeArguments::argc_tag_offset() + native_args_struct_offset;
  const intptr_t argv_offset =
      target::NativeArguments::argv_offset() + native_args_struct_offset;
  const intptr_t retval_offset =
      target::NativeArguments::retval_offset() + native_args_struct_offset;

  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to dart VM code.
  __ movl(Address(THR, target::Thread::top_exit_frame_info_offset()), EBP);

  // Mark that the thread exited generated code through a runtime call.
  __ movl(Address(THR, target::Thread::exit_through_ffi_offset()),
          Immediate(target::Thread::exit_through_runtime_call()));

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
  __ AddImmediate(
      ESP,
      Immediate(-static_cast<int32_t>(target::NativeArguments::StructSize()) -
                (2 * target::kWordSize)));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass NativeArguments structure by value and call native function.
  // Set thread in NativeArgs.
  __ movl(Address(ESP, thread_offset), THR);
  // Set argc in NativeArguments.
  __ movl(Address(ESP, argc_tag_offset), EDX);
  // Set argv in NativeArguments.
  __ movl(Address(ESP, argv_offset), EAX);
  // Compute return value addr.
  __ leal(EAX, Address(EBP, (target::frame_layout.param_end_from_fp + 1) *
                                target::kWordSize));
  // Set retval in NativeArguments.
  __ movl(Address(ESP, retval_offset), EAX);
  // Pointer to the NativeArguments.
  __ leal(EAX, Address(ESP, 2 * target::kWordSize));
  // Pass the pointer to the NativeArguments.
  __ movl(Address(ESP, 0), EAX);

  __ movl(Address(ESP, target::kWordSize), ECX);  // Function to call.
  __ call(wrapper_address);

  __ movl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Mark that the thread has not exited generated Dart code.
  __ movl(Address(THR, target::Thread::exit_through_ffi_offset()),
          Immediate(0));

  // Reset exit frame information in Isolate's mutator thread structure.
  __ movl(Address(THR, target::Thread::top_exit_frame_info_offset()),
          Immediate(0));

  __ LeaveFrame();
  __ ret();
}

void StubCodeCompiler::GenerateCallNoScopeNativeStub() {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::no_scope_native_wrapper_entry_point_offset()));
}

void StubCodeCompiler::GenerateCallAutoScopeNativeStub() {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::auto_scope_native_wrapper_entry_point_offset()));
}

// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of return value.
//   EAX : address of first argument in argument array.
//   ECX : address of the native function to call.
//   EDX : argc_tag including number of arguments and function kind.
void StubCodeCompiler::GenerateCallBootstrapNativeStub() {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::bootstrap_native_wrapper_entry_point_offset()));
}

// Input parameters:
//   ARGS_DESC_REG: arguments descriptor array.
void StubCodeCompiler::GenerateCallStaticFunctionStub() {
  __ EnterStubFrame();
  __ pushl(ARGS_DESC_REG);  // Preserve arguments descriptor array.
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  __ popl(EAX);  // Get Code object result.
  __ popl(ARGS_DESC_REG);  // Restore arguments descriptor array.
  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveFrame();

  __ jmp(FieldAddress(EAX, target::Code::entry_point_offset()));
}

// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// ARGS_DESC_REG: arguments descriptor array.
void StubCodeCompiler::GenerateFixCallersTargetStub() {
  Label monomorphic;
  __ BranchOnMonomorphicCheckedEntryJIT(&monomorphic);

  // This was a static call.
  __ EnterStubFrame();
  __ pushl(ARGS_DESC_REG);  // Preserve arguments descriptor array.
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  __ popl(EAX);  // Get Code object.
  __ popl(ARGS_DESC_REG);  // Restore arguments descriptor array.
  __ movl(EAX, FieldAddress(EAX, target::Code::entry_point_offset()));
  __ LeaveFrame();
  __ jmp(EAX);
  __ int3();

  __ Bind(&monomorphic);
  // This was a switchable call.
  __ EnterStubFrame();
  __ pushl(Immediate(0));  // Result slot.
  __ pushl(EBX);           // Preserve receiver.
  __ pushl(ECX);           // Old cache value (also 2nd return value).
  __ CallRuntime(kFixCallersTargetMonomorphicRuntimeEntry, 2);
  __ popl(ECX);       // Get target cache object.
  __ popl(EBX);       // Restore receiver.
  __ popl(CODE_REG);  // Get target Code object.
  __ movl(EAX, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                          CodeEntryKind::kMonomorphic)));
  __ LeaveFrame();
  __ jmp(EAX);
  __ int3();
}

// Called from object allocate instruction when the allocation stub has been
// disabled.
void StubCodeCompiler::GenerateFixAllocationStubTargetStub() {
  __ EnterStubFrame();
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  __ popl(EAX);  // Get Code object.
  __ movl(EAX, FieldAddress(EAX, target::Code::entry_point_offset()));
  __ LeaveFrame();
  __ jmp(EAX);
  __ int3();
}

// Called from object allocate instruction when the allocation stub for a
// generic class has been disabled.
void StubCodeCompiler::GenerateFixParameterizedAllocationStubTargetStub() {
  __ EnterStubFrame();
  // Preserve type arguments register.
  __ pushl(AllocateObjectABI::kTypeArgumentsReg);
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  __ popl(EAX);  // Get Code object.
  // Restore type arguments register.
  __ popl(AllocateObjectABI::kTypeArgumentsReg);
  __ movl(EAX, FieldAddress(EAX, target::Code::entry_point_offset()));
  __ LeaveFrame();
  __ jmp(EAX);
  __ int3();
}

// Input parameters:
//   EDX: smi-tagged argument count, may be zero.
//   EBP[target::frame_layout.param_end_from_fp + 1]: last argument.
// Uses EAX, EBX, ECX, EDX, EDI.
static void PushArrayOfArguments(Assembler* assembler) {
  // Allocate array to store arguments of caller.
  const Immediate& raw_null = Immediate(target::ToRawPointer(NullObject()));
  __ movl(ECX, raw_null);  // Null element type for raw Array.
  __ Call(StubCodeAllocateArray());
  __ SmiUntag(EDX);
  // EAX: newly allocated array.
  // EDX: length of the array (was preserved by the stub).
  __ pushl(EAX);  // Array is in EAX and on top of stack.
  __ leal(EBX,
          Address(EBP, EDX, TIMES_4,
                  target::frame_layout.param_end_from_fp * target::kWordSize));
  __ leal(ECX, FieldAddress(EAX, target::Array::data_offset()));
  // EBX: address of first argument on stack.
  // ECX: address of first argument in array.
  Label loop, loop_condition;
  __ jmp(&loop_condition, Assembler::kNearJump);
  __ Bind(&loop);
  __ movl(EDI, Address(EBX, 0));
  // Generational barrier is needed, array is not necessarily in new space.
  __ StoreIntoObject(EAX, Address(ECX, 0), EDI);
  __ AddImmediate(ECX, Immediate(target::kWordSize));
  __ AddImmediate(EBX, Immediate(-target::kWordSize));
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
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - EAX);
  const intptr_t saved_exception_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - EAX);
  const intptr_t saved_stacktrace_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - EDX);
  // Result in EAX is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    if (i == CODE_REG) {
      // Save the original value of CODE_REG pushed before invoking this stub
      // instead of the value used to call this stub.
      __ pushl(Address(EBP, 2 * target::kWordSize));
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

  {
    __ movl(ECX, ESP);  // Preserve saved registers block.
    LeafRuntimeScope rt(assembler,
                        /*frame_size=*/2 * target::kWordSize,
                        /*preserve_registers=*/false);
    bool is_lazy =
        (kind == kLazyDeoptFromReturn) || (kind == kLazyDeoptFromThrow);
    __ movl(Address(ESP, 0 * target::kWordSize),
            ECX);  // Start of register block.
    __ movl(Address(ESP, 1 * target::kWordSize), Immediate(is_lazy ? 1 : 0));
    rt.Call(kDeoptimizeCopyFrameRuntimeEntry, 2);
    // Result (EAX) is stack-size (FP - SP) in bytes.
  }

  if (kind == kLazyDeoptFromReturn) {
    // Restore result into EBX temporarily.
    __ movl(EBX, Address(EBP, saved_result_slot_from_fp * target::kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into EBX temporarily.
    __ movl(EBX,
            Address(EBP, saved_exception_slot_from_fp * target::kWordSize));
    __ movl(ECX,
            Address(EBP, saved_stacktrace_slot_from_fp * target::kWordSize));
  }

  __ LeaveDartFrame();
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
  {
    LeafRuntimeScope rt(assembler,
                        /*frame_size=*/1 * target::kWordSize,
                        /*preserve_registers=*/false);
    __ movl(Address(ESP, 0), EBP);  // Pass last FP as parameter on stack.
    rt.Call(kDeoptimizeFillFrameRuntimeEntry, 1);
  }
  if (kind == kLazyDeoptFromReturn) {
    // Restore result into EBX.
    __ movl(EBX, Address(EBP, target::frame_layout.first_local_from_fp *
                                  target::kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into EBX.
    __ movl(EBX, Address(EBP, target::frame_layout.first_local_from_fp *
                                  target::kWordSize));
    __ movl(ECX, Address(EBP, (target::frame_layout.first_local_from_fp - 1) *
                                  target::kWordSize));
  }
  // Code above cannot cause GC.
  __ LeaveDartFrame();

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
  __ pushl(Immediate(target::ToRawSmi(0)));  // Space for the result.
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
  __ LeaveStubFrame();

  __ popl(ECX);       // Pop return address.
  __ addl(ESP, EBX);  // Remove materialization arguments.
  __ pushl(ECX);      // Push return address.
  // The caller is responsible for emitting the return instruction.
}

// EAX: result, must be preserved
void StubCodeCompiler::GenerateDeoptimizeLazyFromReturnStub() {
  // Return address for "call" to deopt stub.
  __ pushl(Immediate(kZapReturnAddress));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromReturn);
  __ ret();
}

// EAX: exception, must be preserved
// EDX: stacktrace, must be preserved
void StubCodeCompiler::GenerateDeoptimizeLazyFromThrowStub() {
  // Return address for "call" to deopt stub.
  __ pushl(Immediate(kZapReturnAddress));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromThrow);
  __ ret();
}

void StubCodeCompiler::GenerateDeoptimizeStub() {
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);
  __ ret();
}

static void GenerateNoSuchMethodDispatcherCode(Assembler* assembler) {
  __ EnterStubFrame();
  __ movl(EDX, FieldAddress(
                   ECX, target::CallSiteData::arguments_descriptor_offset()));

  // Load the receiver.
  __ movl(EDI, FieldAddress(EDX, target::ArgumentsDescriptor::size_offset()));
  __ movl(EAX,
          Address(EBP, EDI, TIMES_HALF_WORD_SIZE,
                  target::frame_layout.param_end_from_fp * target::kWordSize));
  __ pushl(Immediate(0));  // Setup space on stack for result.
  __ pushl(EAX);           // Receiver.
  __ pushl(ECX);           // ICData/MegamorphicCache.
  __ pushl(EDX);           // Arguments descriptor array.

  // Adjust arguments count.
  __ cmpl(
      FieldAddress(EDX, target::ArgumentsDescriptor::type_args_len_offset()),
      Immediate(0));
  __ movl(EDX, EDI);
  Label args_count_ok;
  __ j(EQUAL, &args_count_ok, Assembler::kNearJump);
  __ addl(EDX, Immediate(target::ToRawSmi(1)));  // Include the type arguments.
  __ Bind(&args_count_ok);

  // EDX: Smi-tagged arguments array length.
  PushArrayOfArguments(assembler);
  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromCallStubRuntimeEntry, kNumArgs);
  __ Drop(4);
  __ popl(EAX);  // Return value.
  __ LeaveFrame();
  __ ret();
}

static void GenerateDispatcherCode(Assembler* assembler,
                                   Label* call_target_function) {
  __ Comment("NoSuchMethodDispatch");
  // When lazily generated invocation dispatchers are disabled, the
  // miss-handler may return null.
  const Immediate& raw_null = Immediate(target::ToRawPointer(NullObject()));
  __ cmpl(EAX, raw_null);
  __ j(NOT_EQUAL, call_target_function);
  GenerateNoSuchMethodDispatcherCode(assembler);
}

void StubCodeCompiler::GenerateNoSuchMethodDispatcherStub() {
  GenerateNoSuchMethodDispatcherCode(assembler);
}

// Called for inline allocation of arrays.
// Input registers (preserved):
//   AllocateArrayABI::kLengthReg: array length as Smi.
//   AllocateArrayABI::kTypeArgumentsReg: type arguments of array.
// Output registers:
//   AllocateArrayABI::kResultReg: newly allocated array.
// Clobbered:
//   EBX, EDI
void StubCodeCompiler::GenerateAllocateArrayStub() {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;
    // Compute the size to be allocated, it is based on the array length
    // and is computed as:
    // RoundedAllocationSize(
    //     (array_length * kwordSize) + target::Array::header_size()).
    // Assert that length is a Smi.
    __ testl(AllocateArrayABI::kLengthReg, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, &slow_case);

    // Check for maximum allowed length.
    const Immediate& max_len =
        Immediate(target::ToRawSmi(target::Array::kMaxNewSpaceElements));
    __ cmpl(AllocateArrayABI::kLengthReg, max_len);
    __ j(ABOVE, &slow_case);

    NOT_IN_PRODUCT(__ MaybeTraceAllocation(kArrayCid, &slow_case,
                                           AllocateArrayABI::kResultReg));

    const intptr_t fixed_size_plus_alignment_padding =
        target::Array::header_size() +
        target::ObjectAlignment::kObjectAlignment - 1;
    // AllocateArrayABI::kLengthReg is Smi.
    __ leal(EBX, Address(AllocateArrayABI::kLengthReg, TIMES_2,
                         fixed_size_plus_alignment_padding));
    ASSERT(kSmiTagShift == 1);
    __ andl(EBX, Immediate(-target::ObjectAlignment::kObjectAlignment));

    // AllocateArrayABI::kTypeArgumentsReg: array type arguments.
    // AllocateArrayABI::kLengthReg: array length as Smi.
    // EBX: allocation size.

    const intptr_t cid = kArrayCid;
    __ movl(AllocateArrayABI::kResultReg,
            Address(THR, target::Thread::top_offset()));
    __ addl(EBX, AllocateArrayABI::kResultReg);
    __ j(CARRY, &slow_case);

    // Check if the allocation fits into the remaining space.
    // AllocateArrayABI::kResultReg: potential new object start.
    // EBX: potential next object start.
    // AllocateArrayABI::kTypeArgumentsReg: array type arguments.
    // AllocateArrayABI::kLengthReg: array length as Smi).
    __ cmpl(EBX, Address(THR, target::Thread::end_offset()));
    __ j(ABOVE_EQUAL, &slow_case);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    __ movl(Address(THR, target::Thread::top_offset()), EBX);
    __ subl(EBX, AllocateArrayABI::kResultReg);
    __ addl(AllocateArrayABI::kResultReg, Immediate(kHeapObjectTag));

    // Initialize the tags.
    // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
    // EBX: allocation size.
    // AllocateArrayABI::kTypeArgumentsReg: array type arguments.
    // AllocateArrayABI::kLengthReg: array length as Smi.
    {
      Label size_tag_overflow, done;
      __ movl(EDI, EBX);
      __ cmpl(EDI, Immediate(target::UntaggedObject::kSizeTagMaxSizeTag));
      __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
      __ shll(EDI, Immediate(target::UntaggedObject::kTagBitsSizeTagPos -
                             target::ObjectAlignment::kObjectAlignmentLog2));
      __ jmp(&done, Assembler::kNearJump);

      __ Bind(&size_tag_overflow);
      __ movl(EDI, Immediate(0));
      __ Bind(&done);

      // Get the class index and insert it into the tags.
      uword tags = target::MakeTagWordForNewSpaceObject(cid, 0);
      __ orl(EDI, Immediate(tags));
      __ movl(FieldAddress(AllocateArrayABI::kResultReg,
                           target::Object::tags_offset()),
              EDI);  // Tags.
    }
    // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
    // EBX: allocation size.
    // AllocateArrayABI::kTypeArgumentsReg: array type arguments.
    // AllocateArrayABI::kLengthReg: Array length as Smi (preserved).
    // Store the type argument field.
    // No generational barrier needed, since we store into a new object.
    __ StoreIntoObjectNoBarrier(
        AllocateArrayABI::kResultReg,
        FieldAddress(AllocateArrayABI::kResultReg,
                     target::Array::type_arguments_offset()),
        AllocateArrayABI::kTypeArgumentsReg);

    // Set the length field.
    __ StoreIntoObjectNoBarrier(AllocateArrayABI::kResultReg,
                                FieldAddress(AllocateArrayABI::kResultReg,
                                             target::Array::length_offset()),
                                AllocateArrayABI::kLengthReg);

    // Initialize all array elements to raw_null.
    // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
    // EBX: allocation size.
    // EDI: iterator which initially points to the start of the variable
    // data area to be initialized.
    // AllocateArrayABI::kTypeArgumentsReg: array type arguments.
    // AllocateArrayABI::kLengthReg: array length as Smi.
    __ leal(EBX, FieldAddress(AllocateArrayABI::kResultReg, EBX, TIMES_1, 0));
    __ leal(EDI, FieldAddress(AllocateArrayABI::kResultReg,
                              target::Array::header_size()));
    Label loop;
    __ Bind(&loop);
    for (intptr_t offset = 0; offset < target::kObjectAlignment;
         offset += target::kWordSize) {
      // No generational barrier needed, since we are storing null.
      __ StoreIntoObjectNoBarrier(AllocateArrayABI::kResultReg,
                                  Address(EDI, offset), NullObject());
    }
    // Safe to only check every kObjectAlignment bytes instead of each word.
    ASSERT(kAllocationRedZoneSize >= target::kObjectAlignment);
    __ addl(EDI, Immediate(target::kObjectAlignment));
    __ cmpl(EDI, EBX);
    __ j(UNSIGNED_LESS, &loop);
    __ ret();

    // Unable to allocate the array using the fast inline code, just call
    // into the runtime.
    __ Bind(&slow_case);
  }
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ pushl(AllocateArrayABI::kLengthReg);         // Array length as Smi.
  __ pushl(AllocateArrayABI::kTypeArgumentsReg);  // Type arguments.
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);
  __ popl(AllocateArrayABI::kTypeArgumentsReg);  // Pop type arguments.
  __ popl(AllocateArrayABI::kLengthReg);         // Pop array length argument.
  __ popl(AllocateArrayABI::kResultReg);  // Pop return value from return slot.

  // Write-barrier elimination might be enabled for this array (depending on the
  // array length). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(assembler);

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
void StubCodeCompiler::GenerateInvokeDartCodeStub() {
  const intptr_t kTargetCodeOffset = 2 * target::kWordSize;
  const intptr_t kArgumentsDescOffset = 3 * target::kWordSize;
  const intptr_t kArgumentsOffset = 4 * target::kWordSize;
  const intptr_t kThreadOffset = 5 * target::kWordSize;
  __ EnterFrame(0);

  // Push code object to PC marker slot.
  __ movl(EAX, Address(EBP, kThreadOffset));
  __ pushl(Address(EAX, target::Thread::invoke_dart_code_stub_offset()));

  // Save C++ ABI callee-saved registers.
  __ pushl(EBX);
  __ pushl(ESI);
  __ pushl(EDI);

  // Set up THR, which caches the current thread in Dart code.
  __ movl(THR, EAX);

#if defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Save the current VMTag on the stack.
  __ movl(ECX, Assembler::VMTagAddress());
  __ pushl(ECX);

  // Save top resource and top exit frame info. Use EDX as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ movl(EDX, Address(THR, target::Thread::top_resource_offset()));
  __ pushl(EDX);
  __ movl(Address(THR, target::Thread::top_resource_offset()), Immediate(0));
  __ movl(EAX, Address(THR, target::Thread::exit_through_ffi_offset()));
  __ pushl(EAX);
  __ movl(Address(THR, target::Thread::exit_through_ffi_offset()),
          Immediate(0));
  // The constant target::frame_layout.exit_link_slot_from_entry_fp must be
  // kept in sync with the code below.
  ASSERT(target::frame_layout.exit_link_slot_from_entry_fp == -8);
  __ movl(EDX, Address(THR, target::Thread::top_exit_frame_info_offset()));
  __ pushl(EDX);
  __ movl(Address(THR, target::Thread::top_exit_frame_info_offset()),
          Immediate(0));

  // In debug mode, verify that we've pushed the top exit frame info at the
  // correct offset from FP.
  __ EmitEntryFrameVerification();

  // Mark that the thread is executing Dart code. Do this after initializing the
  // exit link for the profiler.
  __ movl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Load arguments descriptor array into EDX.
  __ movl(EDX, Address(EBP, kArgumentsDescOffset));

  // Load number of arguments into EBX and adjust count for type arguments.
  __ movl(EBX, FieldAddress(EDX, target::ArgumentsDescriptor::count_offset()));
  __ cmpl(
      FieldAddress(EDX, target::ArgumentsDescriptor::type_args_len_offset()),
      Immediate(0));
  Label args_count_ok;
  __ j(EQUAL, &args_count_ok, Assembler::kNearJump);
  __ addl(EBX, Immediate(target::ToRawSmi(1)));  // Include the type arguments.
  __ Bind(&args_count_ok);
  // Save number of arguments as Smi on stack, replacing ArgumentsDesc.
  __ movl(Address(EBP, kArgumentsDescOffset), EBX);
  __ SmiUntag(EBX);

  // Set up arguments for the dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ testl(EBX, EBX);  // check if there are arguments.
  __ j(ZERO, &done_push_arguments, Assembler::kNearJump);
  __ movl(EAX, Immediate(0));

  // Compute address of 'arguments array' data area into EDI.
  __ movl(EDI, Address(EBP, kArgumentsOffset));
  __ leal(EDI, FieldAddress(EDI, target::Array::data_offset()));

  __ Bind(&push_arguments);
  __ movl(ECX, Address(EDI, EAX, TIMES_4, 0));
  __ pushl(ECX);
  __ incl(EAX);
  __ cmpl(EAX, EBX);
  __ j(LESS, &push_arguments, Assembler::kNearJump);
  __ Bind(&done_push_arguments);

  // Call the dart code entrypoint.
  __ movl(EAX, Address(EBP, kTargetCodeOffset));
  __ call(FieldAddress(EAX, target::Code::entry_point_offset()));

  // Read the saved number of passed arguments as Smi.
  __ movl(EDX, Address(EBP, kArgumentsDescOffset));
  // Get rid of arguments pushed on the stack.
  __ leal(ESP, Address(ESP, EDX, TIMES_2, 0));  // EDX is a Smi.

  // Restore the saved top exit frame info and top resource back into the
  // Isolate structure.
  __ popl(Address(THR, target::Thread::top_exit_frame_info_offset()));
  __ popl(Address(THR, target::Thread::exit_through_ffi_offset()));
  __ popl(Address(THR, target::Thread::top_resource_offset()));

  // Restore the current VMTag from the stack.
  __ popl(Assembler::VMTagAddress());

#if defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Restore C++ ABI callee-saved registers.
  __ popl(EDI);
  __ popl(ESI);
  __ popl(EBX);

  // Restore the frame pointer.
  __ LeaveFrame();

  __ ret();
}

// Helper to generate space allocation of context stub.
// This does not initialise the fields of the context.
// Input:
// EDX: number of context variables.
// Output:
// EAX: new allocated Context object.
// Clobbered:
// EBX
static void GenerateAllocateContextSpaceStub(Assembler* assembler,
                                             Label* slow_case) {
  // First compute the rounded instance size.
  // EDX: number of context variables.
  intptr_t fixed_size_plus_alignment_padding =
      (target::Context::header_size() +
       target::ObjectAlignment::kObjectAlignment - 1);
  __ leal(EBX, Address(EDX, TIMES_4, fixed_size_plus_alignment_padding));
  __ andl(EBX, Immediate(-target::ObjectAlignment::kObjectAlignment));

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(kContextCid, slow_case, EAX));

  // Now allocate the object.
  // EDX: number of context variables.
  __ movl(EAX, Address(THR, target::Thread::top_offset()));
  __ addl(EBX, EAX);
  // Check if the allocation fits into the remaining space.
  // EAX: potential new object.
  // EBX: potential next object start.
  // EDX: number of context variables.
  __ cmpl(EBX, Address(THR, target::Thread::end_offset()));
#if defined(DEBUG)
  static auto const kJumpLength = Assembler::kFarJump;
#else
  static auto const kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
  __ j(ABOVE_EQUAL, slow_case, kJumpLength);

  // Successfully allocated the object, now update top to point to
  // next object start and initialize the object.
  // EAX: new object.
  // EBX: next object start.
  // EDX: number of context variables.
  __ movl(Address(THR, target::Thread::top_offset()), EBX);
  // EBX: Size of allocation in bytes.
  __ subl(EBX, EAX);
  __ addl(EAX, Immediate(kHeapObjectTag));
  // Generate isolate-independent code to allow sharing between isolates.

  // Calculate the size tag.
  // EAX: new object.
  // EDX: number of context variables.
  {
    Label size_tag_overflow, done;
    __ leal(EBX, Address(EDX, TIMES_4, fixed_size_plus_alignment_padding));
    __ andl(EBX, Immediate(-target::ObjectAlignment::kObjectAlignment));
    __ cmpl(EBX, Immediate(target::UntaggedObject::kSizeTagMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shll(EBX, Immediate(target::UntaggedObject::kTagBitsSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2));
    __ jmp(&done);

    __ Bind(&size_tag_overflow);
    // Set overflow size tag value.
    __ movl(EBX, Immediate(0));

    __ Bind(&done);
    // EAX: new object.
    // EDX: number of context variables.
    // EBX: size and bit tags.
    uword tags = target::MakeTagWordForNewSpaceObject(kContextCid, 0);
    __ orl(EBX, Immediate(tags));
    __ movl(FieldAddress(EAX, target::Object::tags_offset()), EBX);  // Tags.
  }

  // Setup up number of context variables field.
  // EAX: new object.
  // EDX: number of context variables as integer value (not object).
  __ movl(FieldAddress(EAX, target::Context::num_variables_offset()), EDX);
}

// Called for inline allocation of contexts.
// Input:
// EDX: number of context variables.
// Output:
// EAX: new allocated Context object.
// Clobbered:
// EBX, EDX
void StubCodeCompiler::GenerateAllocateContextStub() {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    GenerateAllocateContextSpaceStub(assembler, &slow_case);

    // Setup the parent field.
    // EAX: new object.
    // EDX: number of context variables.
    // No generational barrier needed, since we are storing null.
    __ StoreIntoObjectNoBarrier(
        EAX, FieldAddress(EAX, target::Context::parent_offset()), NullObject());

    // Initialize the context variables.
    // EAX: new object.
    // EDX: number of context variables.
    {
      Label loop, entry;
      __ leal(EBX, FieldAddress(EAX, target::Context::variable_offset(0)));

      __ jmp(&entry, Assembler::kNearJump);
      __ Bind(&loop);
      __ decl(EDX);
      // No generational barrier needed, since we are storing null.
      __ StoreIntoObjectNoBarrier(EAX, Address(EBX, EDX, TIMES_4, 0),
                                  NullObject());
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

  // Write-barrier elimination might be enabled for this context (depending on
  // the size). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(/*preserve_registers=*/false);

  // EAX: new object
  // Restore the frame pointer.
  __ LeaveFrame();

  __ ret();
}

// Called for clone of contexts.
// Input:
//   ECX: context variable.
// Output:
//   EAX: new allocated Context object.
// Clobbered:
//   EBX, ECX, EDX
void StubCodeCompiler::GenerateCloneContextStub() {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    // Load num. variable in the existing context.
    __ movl(EDX, FieldAddress(ECX, target::Context::num_variables_offset()));

    GenerateAllocateContextSpaceStub(assembler, &slow_case);

    // Setup the parent field.
    // EAX: new object.
    // ECX: old object to clone.
    __ movl(EBX, FieldAddress(ECX, target::Context::parent_offset()));
    __ StoreIntoObjectNoBarrier(
        EAX, FieldAddress(EAX, target::Context::parent_offset()), EBX);

    // Initialize the context variables.
    // EAX: new context.
    // ECX: context to clone.
    // EDX: number of context variables.
    {
      Label loop, entry;
      __ jmp(&entry, Assembler::kNearJump);

      __ Bind(&loop);
      __ decl(EDX);

      __ movl(EBX, FieldAddress(ECX, EDX, TIMES_4,
                                target::Context::variable_offset(0)));
      __ StoreIntoObjectNoBarrier(
          EAX,
          FieldAddress(EAX, EDX, TIMES_4, target::Context::variable_offset(0)),
          EBX);

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
  __ pushl(ECX);
  __ CallRuntime(kCloneContextRuntimeEntry, 1);  // Allocate context.
  __ popl(EAX);  // Pop number of context variables argument.
  __ popl(EAX);  // Pop the new context object.

  // Write-barrier elimination might be enabled for this context (depending on
  // the size). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(/*preserve_registers=*/false);

  // EAX: new object
  // Restore the frame pointer.
  __ LeaveFrame();
  __ ret();
}

void StubCodeCompiler::GenerateWriteBarrierWrappersStub() {
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if ((kDartAvailableCpuRegs & (1 << i)) == 0) continue;

    Register reg = static_cast<Register>(i);
    intptr_t start = __ CodeSize();
    __ pushl(kWriteBarrierObjectReg);
    __ movl(kWriteBarrierObjectReg, reg);
    __ call(Address(THR, target::Thread::write_barrier_entry_point_offset()));
    __ popl(kWriteBarrierObjectReg);
    __ ret();
    intptr_t end = __ CodeSize();

    ASSERT_EQUAL(end - start, kStoreBufferWrapperSize);
    RELEASE_ASSERT(end - start == kStoreBufferWrapperSize);
  }
}

// Helper stub to implement Assembler::StoreIntoObject/Array.
// Input parameters:
//   EDX: Object (old)
//   EBX: Value (old or new)
//   EDI: Slot
// If EAX is new, add EDX to the store buffer. Otherwise EAX is old, mark EAX
// and add it to the mark list.
COMPILE_ASSERT(kWriteBarrierObjectReg == EDX);
COMPILE_ASSERT(kWriteBarrierValueReg == EBX);
COMPILE_ASSERT(kWriteBarrierSlotReg == EDI);
static void GenerateWriteBarrierStubHelper(Assembler* assembler, bool cards) {
  // Save values being destroyed.
  __ pushl(EAX);
  __ pushl(ECX);

  Label add_to_mark_stack, remember_card, lost_race;
  __ testl(EBX, Immediate(1 << target::ObjectAlignment::kNewObjectBitPosition));
  __ j(ZERO, &add_to_mark_stack);

  if (cards) {
    __ testl(FieldAddress(EDX, target::Object::tags_offset()),
             Immediate(1 << target::UntaggedObject::kCardRememberedBit));
    __ j(NOT_ZERO, &remember_card, Assembler::kFarJump);  // Unlikely.
  } else {
#if defined(DEBUG)
    Label ok;
    __ testl(FieldAddress(EDX, target::Object::tags_offset()),
             Immediate(1 << target::UntaggedObject::kCardRememberedBit));
    __ j(ZERO, &ok, Assembler::kFarJump);
    __ Stop("Wrong barrier");
    __ Bind(&ok);
#endif
  }

  // Atomically clear kOldAndNotRememberedBit.
  Label retry;
  __ movl(EAX, FieldAddress(EDX, target::Object::tags_offset()));
  __ Bind(&retry);
  __ movl(ECX, EAX);
  __ testl(ECX,
           Immediate(1 << target::UntaggedObject::kOldAndNotRememberedBit));
  __ j(ZERO, &lost_race);  // Remembered by another thread.
  __ andl(ECX,
          Immediate(~(1 << target::UntaggedObject::kOldAndNotRememberedBit)));
  // Cmpxchgl: compare value = implicit operand EAX, new value = ECX.
  // On failure, EAX is updated with the current value.
  __ LockCmpxchgl(FieldAddress(EDX, target::Object::tags_offset()), ECX);
  __ j(NOT_EQUAL, &retry, Assembler::kNearJump);

  // Load the StoreBuffer block out of the thread. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  // Spilled: EAX, ECX
  // EDX: Address being stored
  __ movl(EAX, Address(THR, target::Thread::store_buffer_block_offset()));
  __ movl(ECX, Address(EAX, target::StoreBufferBlock::top_offset()));
  __ movl(
      Address(EAX, ECX, TIMES_4, target::StoreBufferBlock::pointers_offset()),
      EDX);

  // Increment top_ and check for overflow.
  // Spilled: EAX, ECX
  // ECX: top_
  // EAX: StoreBufferBlock
  Label overflow;
  __ incl(ECX);
  __ movl(Address(EAX, target::StoreBufferBlock::top_offset()), ECX);
  __ cmpl(ECX, Immediate(target::StoreBufferBlock::kSize));
  // Restore values.
  // Spilled: EAX, ECX
  __ popl(ECX);
  __ popl(EAX);
  __ j(EQUAL, &overflow, Assembler::kNearJump);
  __ ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&overflow);
  {
    LeafRuntimeScope rt(assembler,
                        /*frame_size=*/1 * target::kWordSize,
                        /*preserve_registers=*/true);
    __ movl(Address(ESP, 0), THR);  // Push the thread as the only argument.
    rt.Call(kStoreBufferBlockProcessRuntimeEntry, 1);
  }
  __ ret();

  __ Bind(&add_to_mark_stack);
  // Atomically clear kOldAndNotMarkedBit.
  Label retry_marking, marking_overflow;
  __ movl(EAX, FieldAddress(EBX, target::Object::tags_offset()));
  __ Bind(&retry_marking);
  __ movl(ECX, EAX);
  __ testl(ECX, Immediate(1 << target::UntaggedObject::kOldAndNotMarkedBit));
  __ j(ZERO, &lost_race);  // Marked by another thread.
  __ andl(ECX, Immediate(~(1 << target::UntaggedObject::kOldAndNotMarkedBit)));
  // Cmpxchgq: compare value = implicit operand EAX, new value = ECX.
  // On failure, EAX is updated with the current value.
  __ LockCmpxchgl(FieldAddress(EBX, target::Object::tags_offset()), ECX);
  __ j(NOT_EQUAL, &retry_marking, Assembler::kNearJump);

  __ movl(EAX, Address(THR, target::Thread::marking_stack_block_offset()));
  __ movl(ECX, Address(EAX, target::MarkingStackBlock::top_offset()));
  __ movl(
      Address(EAX, ECX, TIMES_4, target::MarkingStackBlock::pointers_offset()),
      EBX);
  __ incl(ECX);
  __ movl(Address(EAX, target::MarkingStackBlock::top_offset()), ECX);
  __ cmpl(ECX, Immediate(target::MarkingStackBlock::kSize));
  __ popl(ECX);  // Unspill.
  __ popl(EAX);  // Unspill.
  __ j(EQUAL, &marking_overflow, Assembler::kNearJump);
  __ ret();

  __ Bind(&marking_overflow);
  {
    LeafRuntimeScope rt(assembler,
                        /*frame_size=*/1 * target::kWordSize,
                        /*preserve_registers=*/true);
    __ movl(Address(ESP, 0), THR);  // Push the thread as the only argument.
    rt.Call(kMarkingStackBlockProcessRuntimeEntry, 1);
  }
  __ ret();

  __ Bind(&lost_race);
  __ popl(ECX);  // Unspill.
  __ popl(EAX);  // Unspill.
  __ ret();

  if (cards) {
    Label remember_card_slow;

    // Get card table.
    __ Bind(&remember_card);
    __ movl(EAX, EDX);                              // Object.
    __ andl(EAX, Immediate(target::kPageMask));     // Page.
    __ cmpl(Address(EAX, target::Page::card_table_offset()), Immediate(0));
    __ j(EQUAL, &remember_card_slow, Assembler::kNearJump);

    // Dirty the card. Not atomic: we assume mutable arrays are not shared
    // between threads.
    __ pushl(EBX);
    __ subl(EDI, EAX);  // Offset in page.
    __ movl(EAX,
            Address(EAX, target::Page::card_table_offset()));  // Card table.
    __ movl(ECX, EDI);
    __ shrl(EDI,
            Immediate(target::Page::kBytesPerCardLog2 +
                      target::kBitsPerWordLog2));  // Word offset.
    __ shrl(ECX, Immediate(target::Page::kBytesPerCardLog2));
    __ movl(EBX, Immediate(1));
    __ shll(EBX, ECX);  // Bit mask. (Shift amount is mod 32.)
    __ orl(Address(EAX, EDI, TIMES_4, 0), EBX);
    __ popl(EBX);
    __ popl(ECX);
    __ popl(EAX);
    __ ret();

    // Card table not yet allocated.
    __ Bind(&remember_card_slow);

    {
      LeafRuntimeScope rt(assembler,
                          /*frame_size=*/2 * target::kWordSize,
                          /*preserve_registers=*/true);
      __ movl(Address(ESP, 0 * target::kWordSize), EDX);  // Object
      __ movl(Address(ESP, 1 * target::kWordSize), EDI);  // Slot
      rt.Call(kRememberCardRuntimeEntry, 2);
    }
    __ popl(ECX);
    __ popl(EAX);
    __ ret();
  }
}

void StubCodeCompiler::GenerateWriteBarrierStub() {
  GenerateWriteBarrierStubHelper(assembler, false);
}

void StubCodeCompiler::GenerateArrayWriteBarrierStub() {
  GenerateWriteBarrierStubHelper(assembler, true);
}

void StubCodeCompiler::GenerateAllocateObjectStub() {
  __ int3();
}

void StubCodeCompiler::GenerateAllocateObjectParameterizedStub() {
  __ int3();
}

void StubCodeCompiler::GenerateAllocateObjectSlowStub() {
  __ int3();
}

// Called for inline allocation of objects.
// Input parameters:
//   ESP : points to return address.
//   AllocateObjectABI::kTypeArgumentsPos : type arguments object
//                                          (only if class is parameterized).
// Uses AllocateObjectABI::kResultReg, EBX, ECX, EDI as temporary registers.
// Returns patch_code_pc offset where patching code for disabling the stub
// has been generated (similar to regularly generated Dart code).
void StubCodeCompiler::GenerateAllocationStubForClass(
    UnresolvedPcRelativeCalls* unresolved_calls,
    const Class& cls,
    const Code& allocate_object,
    const Code& allocat_object_parametrized) {
  const Immediate& raw_null = Immediate(target::ToRawPointer(NullObject()));
  // The generated code is different if the class is parameterized.
  const bool is_cls_parameterized = target::Class::NumTypeArguments(cls) > 0;
  ASSERT(!is_cls_parameterized || target::Class::TypeArgumentsFieldOffset(
                                      cls) != target::Class::kNoTypeArguments);
  // kInlineInstanceSize is a constant used as a threshold for determining
  // when the object initialization should be done as a loop or as
  // straight line code.
  const int kInlineInstanceSize = 12;  // In words.
  const intptr_t instance_size = target::Class::GetInstanceSize(cls);
  ASSERT(instance_size > 0);

  // AllocateObjectABI::kTypeArgumentsReg: new object type arguments
  //                                       (if is_cls_parameterized).
  if (!FLAG_use_slow_path && FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size) &&
      !target::Class::TraceAllocation(cls)) {
    Label slow_case;
    // Allocate the object and update top to point to
    // next object start and initialize the allocated object.
    // AllocateObjectABI::kTypeArgumentsReg: new object type arguments
    //                                       (if is_cls_parameterized).
    __ movl(AllocateObjectABI::kResultReg,
            Address(THR, target::Thread::top_offset()));
    __ leal(EBX, Address(AllocateObjectABI::kResultReg, instance_size));
    // Check if the allocation fits into the remaining space.
    // AllocateObjectABI::kResultReg: potential new object start.
    // EBX: potential next object start.
    __ cmpl(EBX, Address(THR, target::Thread::end_offset()));
    __ j(ABOVE_EQUAL, &slow_case);
    __ movl(Address(THR, target::Thread::top_offset()), EBX);

    // AllocateObjectABI::kResultReg: new object start (untagged).
    // EBX: next object start.
    // AllocateObjectABI::kTypeArgumentsReg: new object type arguments
    //                                       (if is_cls_parameterized).
    // Set the tags.
    ASSERT(target::Class::GetId(cls) != kIllegalCid);
    uword tags = target::MakeTagWordForNewSpaceObject(target::Class::GetId(cls),
                                                      instance_size);
    __ movl(
        Address(AllocateObjectABI::kResultReg, target::Object::tags_offset()),
        Immediate(tags));
    __ addl(AllocateObjectABI::kResultReg, Immediate(kHeapObjectTag));

    // Initialize the remaining words of the object.

    // AllocateObjectABI::kResultReg: new object (tagged).
    // EBX: next object start.
    // AllocateObjectABI::kTypeArgumentsReg: new object type arguments
    //                                       (if is_cls_parameterized).
    // First try inlining the initialization without a loop.
    if (instance_size < (kInlineInstanceSize * target::kWordSize)) {
      // Check if the object contains any non-header fields.
      // Small objects are initialized using a consecutive set of writes.
      for (intptr_t current_offset = target::Instance::first_field_offset();
           current_offset < instance_size;
           current_offset += target::kWordSize) {
        __ StoreIntoObjectNoBarrier(
            AllocateObjectABI::kResultReg,
            FieldAddress(AllocateObjectABI::kResultReg, current_offset),
            NullObject());
      }
    } else {
      __ leal(ECX, FieldAddress(AllocateObjectABI::kResultReg,
                                target::Instance::first_field_offset()));
      // Loop until the whole object is initialized.
      // AllocateObjectABI::kResultReg: new object (tagged).
      // EBX: next object start.
      // ECX: next word to be initialized.
      // AllocateObjectABI::kTypeArgumentsReg: new object type arguments
      //                                       (if is_cls_parameterized).
      Label loop;
      __ Bind(&loop);
      for (intptr_t offset = 0; offset < target::kObjectAlignment;
           offset += target::kWordSize) {
        __ StoreIntoObjectNoBarrier(AllocateObjectABI::kResultReg,
                                    Address(ECX, offset), NullObject());
      }
      // Safe to only check every kObjectAlignment bytes instead of each word.
      ASSERT(kAllocationRedZoneSize >= target::kObjectAlignment);
      __ addl(ECX, Immediate(target::kObjectAlignment));
      __ cmpl(ECX, EBX);
      __ j(UNSIGNED_LESS, &loop);
    }
    if (is_cls_parameterized) {
      // AllocateObjectABI::kResultReg: new object (tagged).
      // AllocateObjectABI::kTypeArgumentsReg: new object type arguments.
      // Set the type arguments in the new object.
      const intptr_t offset = target::Class::TypeArgumentsFieldOffset(cls);
      __ StoreIntoObjectNoBarrier(
          AllocateObjectABI::kResultReg,
          FieldAddress(AllocateObjectABI::kResultReg, offset),
          AllocateObjectABI::kTypeArgumentsReg);
    }
    // Done allocating and initializing the instance.
    // AllocateObjectABI::kResultReg: new object (tagged).
    __ ret();

    __ Bind(&slow_case);
  }
  // If is_cls_parameterized:
  //   AllocateObjectABI::kTypeArgumentsReg: new object type arguments.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ pushl(raw_null);  // Setup space on stack for return value.
  __ PushObject(
      CastHandle<Object>(cls));  // Push class of object to be allocated.
  if (is_cls_parameterized) {
    // Push type arguments of object to be allocated.
    __ pushl(AllocateObjectABI::kTypeArgumentsReg);
  } else {
    __ pushl(raw_null);  // Push null type arguments.
  }
  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);  // Allocate object.
  __ popl(AllocateObjectABI::kResultReg);          // Drop type arguments.
  __ popl(AllocateObjectABI::kResultReg);          // Drop class.
  __ popl(AllocateObjectABI::kResultReg);          // Pop allocated object.

  if (AllocateObjectInstr::WillAllocateNewOrRemembered(cls)) {
    // Write-barrier elimination is enabled for [cls] and we therefore need to
    // ensure that the object is in new-space or has remembered bit set.
    EnsureIsNewOrRemembered(/*preserve_registers=*/false);
  }

  // AllocateObjectABI::kResultReg: new object
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
void StubCodeCompiler::GenerateCallClosureNoSuchMethodStub() {
  __ EnterStubFrame();

  // Load the receiver.
  __ movl(EDI, FieldAddress(EDX, target::ArgumentsDescriptor::size_offset()));
  __ movl(EAX,
          Address(EBP, EDI, TIMES_2,
                  target::frame_layout.param_end_from_fp * target::kWordSize));

  // Load the function.
  __ movl(EBX, FieldAddress(EAX, target::Closure::function_offset()));

  __ pushl(Immediate(0));  // Setup space on stack for result from noSuchMethod.
  __ pushl(EAX);           // Receiver.
  __ pushl(EBX);           // Function.
  __ pushl(EDX);           // Arguments descriptor array.

  // Adjust arguments count.
  __ cmpl(
      FieldAddress(EDX, target::ArgumentsDescriptor::type_args_len_offset()),
      Immediate(0));
  __ movl(EDX, EDI);
  Label args_count_ok;
  __ j(EQUAL, &args_count_ok, Assembler::kNearJump);
  __ addl(EDX, Immediate(target::ToRawSmi(1)));  // Include the type arguments.
  __ Bind(&args_count_ok);

  // EDX: Smi-tagged arguments array length.
  PushArrayOfArguments(assembler);

  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromPrologueRuntimeEntry, kNumArgs);
  // noSuchMethod on closures always throws an error, so it will never return.
  __ int3();
}

// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCodeCompiler::GenerateOptimizedUsageCounterIncrement() {
  Register ic_reg = ECX;
  Register func_reg = EAX;
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
  __ incl(FieldAddress(func_reg, target::Function::usage_counter_offset()));
}

// Loads function into 'temp_reg'.
void StubCodeCompiler::GenerateUsageCounterIncrement(Register temp_reg) {
  if (FLAG_optimization_counter_threshold >= 0) {
    Register func_reg = temp_reg;
    ASSERT(func_reg != IC_DATA_REG);
    __ Comment("Increment function counter");
    __ movl(func_reg,
            FieldAddress(IC_DATA_REG, target::ICData::owner_offset()));
    __ incl(FieldAddress(func_reg, target::Function::usage_counter_offset()));
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
  __ movl(EAX, Address(ESP, +2 * target::kWordSize));  // Left
  __ movl(EDI, Address(ESP, +1 * target::kWordSize));  // Right
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
    case Token::kLT: {
      Label done, is_true;
      __ cmpl(EAX, EDI);
      __ setcc(GREATER_EQUAL, AL);
      __ movzxb(EAX, AL);  // EAX := EAX < EDI ? 0 : 1
      __ movl(EAX,
              Address(THR, EAX, TIMES_4, target::Thread::bool_true_offset()));
      ASSERT(target::Thread::bool_true_offset() + 4 ==
             target::Thread::bool_false_offset());
      break;
    }
    case Token::kEQ: {
      Label done, is_true;
      __ cmpl(EAX, EDI);
      __ setcc(NOT_EQUAL, AL);
      __ movzxb(EAX, AL);  // EAX := EAX == EDI ? 0 : 1
      __ movl(EAX,
              Address(THR, EAX, TIMES_4, target::Thread::bool_true_offset()));
      ASSERT(target::Thread::bool_true_offset() + 4 ==
             target::Thread::bool_false_offset());
      break;
    }
    default:
      UNIMPLEMENTED();
  }

  // ECX: IC data object.
  __ movl(EBX, FieldAddress(ECX, target::ICData::entries_offset()));
  // EBX: ic_data_array with check entries: classes and target functions.
  __ leal(EBX, FieldAddress(EBX, target::Array::data_offset()));
#if defined(DEBUG)
  // Check that first entry is for Smi/Smi.
  Label error, ok;
  const Immediate& imm_smi_cid = Immediate(target::ToRawSmi(kSmiCid));
  __ cmpl(Address(EBX, 0 * target::kWordSize), imm_smi_cid);
  __ j(NOT_EQUAL, &error, Assembler::kNearJump);
  __ cmpl(Address(EBX, 1 * target::kWordSize), imm_smi_cid);
  __ j(EQUAL, &ok, Assembler::kNearJump);
  __ Bind(&error);
  __ Stop("Incorrect IC data");
  __ Bind(&ok);
#endif
  if (FLAG_optimization_counter_threshold >= 0) {
    const intptr_t count_offset =
        target::ICData::CountIndexFor(num_args) * target::kWordSize;
    // Update counter, ignore overflow.
    __ addl(Address(EBX, count_offset), Immediate(target::ToRawSmi(1)));
  }
  __ ret();
}

// Generate inline cache check for 'num_args'.
//  EBX: receiver (if instance call)
//  ECX: ICData
//  ESP[0]: return address
// Control flow:
// - If receiver is null -> jump to IC miss.
// - If receiver is Smi -> load Smi class.
// - If receiver is not-Smi -> load receiver's class.
// - Check if 'num_args' (including receiver) match any IC data group.
// - Match found -> jump to target.
// - Match not found -> jump to IC miss.
void StubCodeCompiler::GenerateNArgsCheckInlineCacheStub(
    intptr_t num_args,
    const RuntimeEntry& handle_ic_miss,
    Token::Kind kind,
    Optimized optimized,
    CallType type,
    Exactness exactness) {
  GenerateNArgsCheckInlineCacheStubForEntryKind(num_args, handle_ic_miss, kind,
                                                optimized, type, exactness,
                                                CodeEntryKind::kNormal);
  __ BindUncheckedEntryPoint();
  GenerateNArgsCheckInlineCacheStubForEntryKind(num_args, handle_ic_miss, kind,
                                                optimized, type, exactness,
                                                CodeEntryKind::kUnchecked);
}

void StubCodeCompiler::GenerateNArgsCheckInlineCacheStubForEntryKind(
    intptr_t num_args,
    const RuntimeEntry& handle_ic_miss,
    Token::Kind kind,
    Optimized optimized,
    CallType type,
    Exactness exactness,
    CodeEntryKind entry_kind) {
  if (optimized == kOptimized) {
    GenerateOptimizedUsageCounterIncrement();
  } else {
    GenerateUsageCounterIncrement(/* scratch */ EAX);
  }

  ASSERT(exactness == kIgnoreExactness);  // Unimplemented.
  ASSERT(num_args == 1 || num_args == 2);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ movl(EAX, FieldAddress(ECX, target::ICData::state_bits_offset()));
    ASSERT(target::ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andl(EAX, Immediate(target::ICData::NumArgsTestedMask()));
    __ cmpl(EAX, Immediate(num_args));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

#if !defined(PRODUCT)
  Label stepping, done_stepping;
  if (optimized == kUnoptimized) {
    __ Comment("Check single stepping");
    __ LoadIsolate(EAX);
    __ cmpb(Address(EAX, target::Isolate::single_step_offset()), Immediate(0));
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
  __ movl(
      ARGS_DESC_REG,
      FieldAddress(ECX, target::CallSiteData::arguments_descriptor_offset()));
  // Loop that checks if there is an IC data match.
  Label loop, found, miss;
  // ECX: IC data object (preserved).
  __ movl(EBX, FieldAddress(ECX, target::ICData::entries_offset()));
  // EBX: ic_data_array with check entries: classes and target functions.
  __ leal(EBX, FieldAddress(EBX, target::Array::data_offset()));
  // EBX: points directly to the first ic data array element.

  // Get argument descriptor into EAX.  In the 1-argument case this is the
  // last time we need the argument descriptor, and we reuse EAX for the
  // class IDs from the IC descriptor.  In the 2-argument case we preserve
  // the argument descriptor in EAX.
  __ movl(EAX, FieldAddress(ARGS_DESC_REG,
                            target::ArgumentsDescriptor::count_offset()));
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
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(num_args) * target::kWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(num_args) * target::kWordSize;
  const intptr_t entry_size = target::ICData::TestEntryLengthFor(
                                  num_args, exactness == kCheckExactness) *
                              target::kWordSize;

  __ Bind(&loop);
  for (int unroll = optimize ? 4 : 2; unroll >= 0; unroll--) {
    Label update;
    if (num_args == 1) {
      __ movl(EDI, Address(EBX, 0));
      __ cmpl(EDI, EAX);                    // Class id match?
      __ j(EQUAL, &found);                  // Break.
      __ addl(EBX, Immediate(entry_size));  // Next entry.
      __ cmpl(EDI, Immediate(target::ToRawSmi(kIllegalCid)));  // Done?
    } else {
      ASSERT(num_args == 2);
      // Load receiver into EDI.
      __ movl(EDI, Address(ESP, EAX, TIMES_2, 0));
      __ LoadTaggedClassIdMayBeSmi(EDI, EDI);
      __ cmpl(EDI, Address(EBX, 0));  // Class id match?
      __ j(NOT_EQUAL, &update);       // Continue.

      // Load second argument into EDI.
      __ movl(EDI, Address(ESP, EAX, TIMES_2, -target::kWordSize));
      __ LoadTaggedClassIdMayBeSmi(EDI, EDI);
      __ cmpl(EDI, Address(EBX, target::kWordSize));  // Class id match?
      __ j(EQUAL, &found);                            // Break.

      __ Bind(&update);
      __ addl(EBX, Immediate(entry_size));  // Next entry.
      __ cmpl(Address(EBX, -entry_size),
              Immediate(target::ToRawSmi(kIllegalCid)));  // Done?
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
  __ movl(EAX, FieldAddress(ARGS_DESC_REG,
                            target::ArgumentsDescriptor::count_offset()));
  __ leal(EAX, Address(ESP, EAX, TIMES_2, 0));  // EAX is Smi.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ pushl(ARGS_DESC_REG);  // Preserve arguments descriptor array.
  __ pushl(ECX);           // Preserve IC data object.
  __ pushl(Immediate(0));  // Result slot.
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ movl(EBX, Address(EAX, -target::kWordSize * i));
    __ pushl(EBX);
  }
  __ pushl(ECX);  // Pass IC data object.
  __ CallRuntime(handle_ic_miss, num_args + 1);
  // Remove the call arguments pushed earlier, including the IC data object.
  for (intptr_t i = 0; i < num_args + 1; i++) {
    __ popl(EAX);
  }
  __ popl(FUNCTION_REG);  // Pop returned function object into EAX.
  __ popl(ECX);  // Restore IC data array.
  __ popl(ARGS_DESC_REG);  // Restore arguments descriptor array.
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
    __ addl(Address(EBX, count_offset), Immediate(target::ToRawSmi(1)));
  }

  __ movl(FUNCTION_REG, Address(EBX, target_offset));
  __ Bind(&call_target_function);
  __ Comment("Call target");
  // EAX: Target function.
  __ jmp(FieldAddress(FUNCTION_REG,
                      target::Function::entry_point_offset(entry_kind)));

#if !defined(PRODUCT)
  if (optimized == kUnoptimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    __ pushl(EBX);  // Preserve receiver.
    __ pushl(ECX);  // Preserve ICData.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ popl(ECX);  // Restore ICData.
    __ popl(EBX);  // Restore receiver.
    __ LeaveFrame();
    __ jmp(&done_stepping);
  }
#endif
}

// EBX: receiver
// ECX: ICData
// ESP[0]: return address
void StubCodeCompiler::GenerateOneArgCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

// EBX: receiver
// ECX: ICData
// ESP[0]: return address
void StubCodeCompiler::GenerateOneArgCheckInlineCacheWithExactnessCheckStub() {
  __ Stop("Unimplemented");
}

void StubCodeCompiler::GenerateAllocateMintSharedWithFPURegsStub() {
  __ Stop("Unimplemented");
}

void StubCodeCompiler::GenerateAllocateMintSharedWithoutFPURegsStub() {
  __ Stop("Unimplemented");
}

// EBX: receiver
// ECX: ICData
// ESP[0]: return address
void StubCodeCompiler::GenerateTwoArgsCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

// EBX: receiver
// ECX: ICData
// ESP[0]: return address
void StubCodeCompiler::GenerateSmiAddInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kADD, kUnoptimized,
      kInstanceCall, kIgnoreExactness);
}

// EBX: receiver
// ECX: ICData
// ESP[0]: return address
void StubCodeCompiler::GenerateSmiLessInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kLT, kUnoptimized,
      kInstanceCall, kIgnoreExactness);
}

// EBX: receiver
// ECX: ICData
// ESP[0]: return address
void StubCodeCompiler::GenerateSmiEqualInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ, kUnoptimized,
      kInstanceCall, kIgnoreExactness);
}

// EBX: receiver
// ECX: ICData
// EAX: Function
// ESP[0]: return address
void StubCodeCompiler::GenerateOneArgOptimizedCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL, kOptimized,
      kInstanceCall, kIgnoreExactness);
}

// EBX: receiver
// ECX: ICData
// EAX: Function
// ESP[0]: return address
void StubCodeCompiler::
    GenerateOneArgOptimizedCheckInlineCacheWithExactnessCheckStub() {
  __ Stop("Unimplemented");
}

// EBX: receiver
// ECX: ICData
// EAX: Function
// ESP[0]: return address
void StubCodeCompiler::GenerateTwoArgsOptimizedCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kIgnoreExactness);
}

// ECX: ICData
// ESP[0]: return address
static void GenerateZeroArgsUnoptimizedStaticCallForEntryKind(
    StubCodeCompiler* stub_code_compiler,
    CodeEntryKind entry_kind) {
  stub_code_compiler->GenerateUsageCounterIncrement(/* scratch */ EAX);
  auto* const assembler = stub_code_compiler->assembler;

#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ movl(EBX, FieldAddress(ECX, target::ICData::state_bits_offset()));
    ASSERT(target::ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andl(EBX, Immediate(target::ICData::NumArgsTestedMask()));
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
  __ cmpb(Address(EAX, target::Isolate::single_step_offset()), Immediate(0));
  __ j(NOT_EQUAL, &stepping, Assembler::kNearJump);
  __ Bind(&done_stepping);
#endif

  // ECX: IC data object (preserved).
  __ movl(EBX, FieldAddress(ECX, target::ICData::entries_offset()));
  // EBX: ic_data_array with entries: target functions and count.
  __ leal(EBX, FieldAddress(EBX, target::Array::data_offset()));
  // EBX: points directly to the first ic data array element.
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(0) * target::kWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(0) * target::kWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    // Increment count for this call, ignore overflow.
    __ addl(Address(EBX, count_offset), Immediate(target::ToRawSmi(1)));
  }

  // Load arguments descriptor into EDX.
  __ movl(
      ARGS_DESC_REG,
      FieldAddress(ECX, target::CallSiteData::arguments_descriptor_offset()));

  // Get function and call it, if possible.
  __ movl(FUNCTION_REG, Address(EBX, target_offset));
  __ jmp(FieldAddress(FUNCTION_REG,
                      target::Function::entry_point_offset(entry_kind)));

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

void StubCodeCompiler::GenerateZeroArgsUnoptimizedStaticCallStub() {
  GenerateZeroArgsUnoptimizedStaticCallForEntryKind(this,
                                                    CodeEntryKind::kNormal);
  __ BindUncheckedEntryPoint();
  GenerateZeroArgsUnoptimizedStaticCallForEntryKind(this,
                                                    CodeEntryKind::kUnchecked);
}

// ECX: ICData
// ESP[0]: return address
void StubCodeCompiler::GenerateOneArgUnoptimizedStaticCallStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kStaticCall, kIgnoreExactness);
}

// ECX: ICData
// ESP[0]: return address
void StubCodeCompiler::GenerateTwoArgsUnoptimizedStaticCallStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kStaticCall, kIgnoreExactness);
}

// Stub for compiling a function and jumping to the compiled code.
// ARGS_DESC_REG: Arguments descriptor.
// FUNCTION_REG: Function.
void StubCodeCompiler::GenerateLazyCompileStub() {
  __ EnterStubFrame();
  __ pushl(ARGS_DESC_REG);  // Preserve arguments descriptor array.
  __ pushl(FUNCTION_REG);   // Pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ popl(FUNCTION_REG);   // Restore function.
  __ popl(ARGS_DESC_REG);  // Restore arguments descriptor array.
  __ LeaveFrame();

  __ jmp(FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
}

// ECX: Contains an ICData.
void StubCodeCompiler::GenerateICCallBreakpointStub() {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ pushl(EBX);           // Preserve receiver.
  __ pushl(ECX);           // Preserve ICData.
  __ pushl(Immediate(0));  // Room for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popl(EAX);  // Code of original stub.
  __ popl(ECX);  // Restore ICData.
  __ popl(EBX);  // Restore receiver.
  __ LeaveFrame();
  // Jump to original stub.
  __ jmp(FieldAddress(EAX, target::Code::entry_point_offset()));
#endif  // defined(PRODUCT)
}

void StubCodeCompiler::GenerateUnoptStaticCallBreakpointStub() {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ pushl(ECX);           // Preserve ICData.
  __ pushl(Immediate(0));  // Room for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popl(EAX);  // Code of original stub.
  __ popl(ECX);  // Restore ICData.
  __ LeaveFrame();
  // Jump to original stub.
  __ jmp(FieldAddress(EAX, target::Code::entry_point_offset()));
#endif  // defined(PRODUCT)
}

void StubCodeCompiler::GenerateRuntimeCallBreakpointStub() {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  // Room for result. Debugger stub returns address of the
  // unpatched runtime stub.
  __ pushl(Immediate(0));  // Room for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popl(EAX);  // Code of the original stub
  __ LeaveFrame();
  // Jump to original stub.
  __ jmp(FieldAddress(EAX, target::Code::entry_point_offset()));
#endif  // defined(PRODUCT)
}

// Called only from unoptimized code.
void StubCodeCompiler::GenerateDebugStepCheckStub() {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(EAX);
  __ movzxb(EAX, Address(EAX, target::Isolate::single_step_offset()));
  __ cmpl(EAX, Immediate(0));
  __ j(NOT_EQUAL, &stepping, Assembler::kNearJump);
  __ Bind(&done_stepping);
  __ ret();

  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveFrame();
  __ jmp(&done_stepping, Assembler::kNearJump);
#endif  // defined(PRODUCT)
}

// Constants used for generating subtype test cache lookup stubs.
// We represent the depth of as a depth from the top of the stack at the
// start of the stub. That is, depths for input values are non-negative and
// depths for values pushed during the stub are negative.

struct STCInternal : AllStatic {
  // Used to initialize depths for conditionally-pushed values.
  static constexpr intptr_t kNoDepth = kIntptrMin;

  // These inputs are always on the stack when the SubtypeNTestCacheStub is
  // called. These absolute depths will be converted to relative depths within
  // the stub to compensate for additional pushed values.
  static constexpr intptr_t kFunctionTypeArgumentsDepth = 1;
  static constexpr intptr_t kInstantiatorTypeArgumentsDepth = 2;
  static constexpr intptr_t kDestinationTypeDepth = 3;
  static constexpr intptr_t kInstanceDepth = 4;
  static constexpr intptr_t kCacheDepth = 5;

  // Non-stack values are stored in non-kInstanceReg registers from TypeTestABI.
  static constexpr Register kCacheArrayReg =
      TypeTestABI::kInstantiatorTypeArgumentsReg;
  static constexpr Register kScratchReg = TypeTestABI::kSubtypeTestCacheReg;
  static constexpr Register kInstanceCidOrSignatureReg =
      TypeTestABI::kFunctionTypeArgumentsReg;
  static constexpr Register kInstanceInstantiatorTypeArgumentsReg =
      TypeTestABI::kDstTypeReg;
};

static void GenerateSubtypeTestCacheLoop(
    Assembler* assembler,
    int n,
    intptr_t original_tos_offset,
    intptr_t parent_function_type_args_depth,
    intptr_t delayed_type_args_depth,
    Label* found,
    Label* not_found,
    Label* next_iteration) {
  const auto& raw_null = Immediate(target::ToRawPointer(NullObject()));

  // Compares a value at the given depth from the stack to the value in src.
  auto compare_to_stack = [&](Register src, intptr_t depth) {
    ASSERT(original_tos_offset + depth >= 0);
    __ CompareToStack(src, original_tos_offset + depth);
  };

  __ LoadAcquireCompressed(
      STCInternal::kScratchReg, STCInternal::kCacheArrayReg,
      target::kCompressedWordSize *
          target::SubtypeTestCache::kInstanceCidOrSignature);
  __ cmpl(STCInternal::kScratchReg, raw_null);
  __ j(EQUAL, not_found, Assembler::kNearJump);
  __ cmpl(STCInternal::kScratchReg, STCInternal::kInstanceCidOrSignatureReg);
  if (n == 1) {
    __ j(EQUAL, found, Assembler::kNearJump);
    return;
  }
  __ j(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ cmpl(STCInternal::kInstanceInstantiatorTypeArgumentsReg,
          Address(STCInternal::kCacheArrayReg,
                  target::kWordSize *
                      target::SubtypeTestCache::kInstanceTypeArguments));
  if (n == 2) {
    __ j(EQUAL, found, Assembler::kNearJump);
    return;
  }
  __ j(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ movl(STCInternal::kScratchReg,
          Address(STCInternal::kCacheArrayReg,
                  target::kWordSize *
                      target::SubtypeTestCache::kInstantiatorTypeArguments));
  compare_to_stack(STCInternal::kScratchReg,
                   STCInternal::kInstantiatorTypeArgumentsDepth);
  if (n == 3) {
    __ j(EQUAL, found, Assembler::kNearJump);
    return;
  }
  __ j(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ movl(STCInternal::kScratchReg,
          Address(STCInternal::kCacheArrayReg,
                  target::kWordSize *
                      target::SubtypeTestCache::kFunctionTypeArguments));
  compare_to_stack(STCInternal::kScratchReg,
                   STCInternal::kFunctionTypeArgumentsDepth);
  if (n == 4) {
    __ j(EQUAL, found, Assembler::kNearJump);
    return;
  }
  __ j(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ movl(
      STCInternal::kScratchReg,
      Address(
          STCInternal::kCacheArrayReg,
          target::kWordSize *
              target::SubtypeTestCache::kInstanceParentFunctionTypeArguments));
  compare_to_stack(STCInternal::kScratchReg, parent_function_type_args_depth);
  if (n == 5) {
    __ j(EQUAL, found, Assembler::kNearJump);
    return;
  }
  __ j(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ movl(
      STCInternal::kScratchReg,
      Address(
          STCInternal::kCacheArrayReg,
          target::kWordSize *
              target::SubtypeTestCache::kInstanceDelayedFunctionTypeArguments));
  compare_to_stack(STCInternal::kScratchReg, delayed_type_args_depth);
  if (n == 6) {
    __ j(EQUAL, found, Assembler::kNearJump);
    return;
  }
  __ j(NOT_EQUAL, next_iteration, Assembler::kNearJump);
  __ movl(
      STCInternal::kScratchReg,
      Address(STCInternal::kCacheArrayReg,
              target::kWordSize * target::SubtypeTestCache::kDestinationType));
  compare_to_stack(STCInternal::kScratchReg,
                   STCInternal::kDestinationTypeDepth);
  __ j(EQUAL, found, Assembler::kNearJump);
}

// Used to check class and type arguments. Arguments passed on stack:
// TOS + 0: return address.
// TOS + 1: function type arguments (only used if n >= 4, can be raw_null).
// TOS + 2: instantiator type arguments (only used if n >= 3, can be raw_null).
// TOS + 3: destination_type (only used if n >= 7).
// TOS + 4: instance.
// TOS + 5: SubtypeTestCache.
//
// No registers are preserved by this stub.
//
// Result in SubtypeTestCacheReg::kResultReg: null -> not found, otherwise
// result (true or false).
void StubCodeCompiler::GenerateSubtypeNTestCacheStub(Assembler* assembler,
                                                     int n) {
  ASSERT(n == 1 || n == 2 || n == 4 || n == 6 || n == 7);

  const auto& raw_null = Immediate(target::ToRawPointer(NullObject()));

  __ LoadFromStack(TypeTestABI::kInstanceReg, STCInternal::kInstanceDepth);

  // Loop initialization (moved up here to avoid having all dependent loads
  // after each other)
  __ LoadFromStack(STCInternal::kCacheArrayReg, STCInternal::kCacheDepth);
#if defined(DEBUG)
  // Verify the STC we received has exactly as many inputs as this stub expects.
  Label search_stc;
  __ LoadFromSlot(STCInternal::kScratchReg, STCInternal::kCacheArrayReg,
                  Slot::SubtypeTestCache_num_inputs());
  __ CompareImmediate(STCInternal::kScratchReg, n);
  __ BranchIf(EQUAL, &search_stc, Assembler::kNearJump);
  __ Breakpoint();
  __ Bind(&search_stc);
#endif
  // We avoid a load-acquire barrier here by relying on the fact that all other
  // loads from the array are data-dependent loads.
  __ movl(STCInternal::kCacheArrayReg,
          FieldAddress(STCInternal::kCacheArrayReg,
                       target::SubtypeTestCache::cache_offset()));

  // There is a maximum size for linear caches that is smaller than the size
  // of any hash-based cache, so we check the size of the backing array to
  // determine if this is a linear or hash-based cache.
  __ LoadFromSlot(STCInternal::kScratchReg, STCInternal::kCacheArrayReg,
                  Slot::Array_length());
  __ CompareImmediate(STCInternal::kScratchReg,
                      target::ToRawSmi(SubtypeTestCache::kMaxLinearCacheSize));
  // For IA32, we never handle hash caches in the stub, as there's too much
  // register pressure.
  Label is_linear;
  __ BranchIf(LESS_EQUAL, &is_linear, Assembler::kNearJump);
  // Return null so that we'll continue to the runtime for hash-based caches.
  __ movl(TypeTestABI::kSubtypeTestCacheResultReg, raw_null);
  __ ret();
  __ Bind(&is_linear);
  __ AddImmediate(STCInternal::kCacheArrayReg,
                  target::Array::data_offset() - kHeapObjectTag);

  Label loop, not_closure;
  if (n >= 4) {
    __ LoadClassIdMayBeSmi(STCInternal::kInstanceCidOrSignatureReg,
                           TypeTestABI::kInstanceReg);
  } else {
    __ LoadClassId(STCInternal::kInstanceCidOrSignatureReg,
                   TypeTestABI::kInstanceReg);
  }
  __ cmpl(STCInternal::kInstanceCidOrSignatureReg, Immediate(kClosureCid));
  __ j(NOT_EQUAL, &not_closure, Assembler::kNearJump);

  // Closure handling.
  {
    __ movl(STCInternal::kInstanceCidOrSignatureReg,
            FieldAddress(TypeTestABI::kInstanceReg,
                         target::Closure::function_offset()));
    __ movl(STCInternal::kInstanceCidOrSignatureReg,
            FieldAddress(STCInternal::kInstanceCidOrSignatureReg,
                         target::Function::signature_offset()));
    if (n >= 2) {
      __ movl(
          STCInternal::kInstanceInstantiatorTypeArgumentsReg,
          FieldAddress(TypeTestABI::kInstanceReg,
                       target::Closure::instantiator_type_arguments_offset()));
    }
    if (n >= 5) {
      __ pushl(FieldAddress(TypeTestABI::kInstanceReg,
                            target::Closure::function_type_arguments_offset()));
    }
    if (n >= 6) {
      __ pushl(FieldAddress(TypeTestABI::kInstanceReg,
                            target::Closure::delayed_type_arguments_offset()));
    }
    __ jmp(&loop, Assembler::kNearJump);
  }

  // Non-Closure handling.
  {
    __ Bind(&not_closure);
    if (n >= 2) {
      Label has_no_type_arguments;
      __ LoadClassById(STCInternal::kScratchReg,
                       STCInternal::kInstanceCidOrSignatureReg);
      __ movl(STCInternal::kInstanceInstantiatorTypeArgumentsReg, raw_null);
      __ movl(
          STCInternal::kScratchReg,
          FieldAddress(STCInternal::kScratchReg,
                       target::Class::
                           host_type_arguments_field_offset_in_words_offset()));
      __ cmpl(STCInternal::kScratchReg,
              Immediate(target::Class::kNoTypeArguments));
      __ j(EQUAL, &has_no_type_arguments, Assembler::kNearJump);
      __ movl(STCInternal::kInstanceInstantiatorTypeArgumentsReg,
              FieldAddress(TypeTestABI::kInstanceReg, STCInternal::kScratchReg,
                           TIMES_4, 0));
      __ Bind(&has_no_type_arguments);
    }
    __ SmiTag(STCInternal::kInstanceCidOrSignatureReg);
    if (n >= 5) {
      __ pushl(raw_null);  // parent function.
    }
    if (n >= 6) {
      __ pushl(raw_null);  // delayed.
    }
  }

  // Offset of the original top of the stack from the current top of stack.
  intptr_t original_tos_offset = 0;

  // Additional data conditionally stored on the stack use negative depths
  // that will be non-negative when adjusted for original_tos_offset. We
  // initialize conditionally pushed values to kNoInput for extra checking.
  intptr_t kInstanceParentFunctionTypeArgumentsDepth = STCInternal::kNoDepth;
  intptr_t kInstanceDelayedFunctionTypeArgumentsDepth = STCInternal::kNoDepth;

  // Now that instance handling is done, both the delayed and parent function
  // type arguments stack slots have been set, so any input uses must be
  // offset by the new values and the new values can now be accessed in
  // the following code without issue when n >= 6.
  if (n >= 5) {
    original_tos_offset++;
    kInstanceParentFunctionTypeArgumentsDepth = -original_tos_offset;
  }
  if (n >= 6) {
    original_tos_offset++;
    kInstanceDelayedFunctionTypeArgumentsDepth = -original_tos_offset;
  }

  Label found, not_found, done, next_iteration;

  // Loop header.
  __ Bind(&loop);
  GenerateSubtypeTestCacheLoop(assembler, n, original_tos_offset,
                               kInstanceParentFunctionTypeArgumentsDepth,
                               kInstanceDelayedFunctionTypeArgumentsDepth,
                               &found, &not_found, &next_iteration);
  __ Bind(&next_iteration);
  __ addl(STCInternal::kCacheArrayReg,
          Immediate(target::kWordSize *
                    target::SubtypeTestCache::kTestEntryLength));
  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&found);
  if (n >= 5) {
    __ Drop(original_tos_offset);
  }
  __ movl(TypeTestABI::kSubtypeTestCacheResultReg,
          Address(STCInternal::kCacheArrayReg,
                  target::kWordSize * target::SubtypeTestCache::kTestResult));
  __ ret();

  __ Bind(&not_found);
  if (n >= 5) {
    __ Drop(original_tos_offset);
  }
  // In the not found case, even though the field that determines occupancy was
  // null, another thread might be updating the cache and in the middle of
  // filling in the entry. Thus, we load the null object explicitly instead of
  // just using the (possibly mid-update) test result field.
  __ movl(TypeTestABI::kSubtypeTestCacheResultReg, raw_null);
  __ ret();
}

// Return the current stack pointer address, used to do stack alignment checks.
// TOS + 0: return address
// Result in EAX.
void StubCodeCompiler::GenerateGetCStackPointerStub() {
  __ leal(EAX, Address(ESP, target::kWordSize));
  __ ret();
}

// Jump to a frame on the call stack.
// TOS + 0: return address
// TOS + 1: program_counter
// TOS + 2: stack_pointer
// TOS + 3: frame_pointer
// TOS + 4: thread
// No Result.
void StubCodeCompiler::GenerateJumpToFrameStub() {
  __ movl(THR, Address(ESP, 4 * target::kWordSize));  // Load target thread.
  __ movl(EBP,
          Address(ESP, 3 * target::kWordSize));  // Load target frame_pointer.
  __ movl(EBX,
          Address(ESP, 1 * target::kWordSize));  // Load target PC into EBX.
  __ movl(ESP,
          Address(ESP, 2 * target::kWordSize));  // Load target stack_pointer.
#if defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  Label exit_through_non_ffi;
  // Check if we exited generated from FFI. If so do transition - this is needed
  // because normally runtime calls transition back to generated via destructor
  // of TransitionGeneratedToVM/Native that is part of runtime boilerplate
  // code (see DEFINE_RUNTIME_ENTRY_IMPL in runtime_entry.h). Ffi calls don't
  // have this boilerplate, don't have this stack resource, have to transition
  // explicitly.
  __ cmpl(compiler::Address(
              THR, compiler::target::Thread::exit_through_ffi_offset()),
          compiler::Immediate(target::Thread::exit_through_ffi()));
  __ j(NOT_EQUAL, &exit_through_non_ffi, compiler::Assembler::kNearJump);
  __ TransitionNativeToGenerated(ECX, /*leave_safepoint=*/true,
                                 /*ignore_unwind_in_progress=*/true);
  __ Bind(&exit_through_non_ffi);

  // Set tag.
  __ movl(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));
  // Clear top exit frame.
  __ movl(Address(THR, target::Thread::top_exit_frame_info_offset()),
          Immediate(0));
  __ jmp(EBX);  // Jump to the exception handler code.
}

// Run an exception handler.  Execution comes from JumpToFrame stub.
//
// The arguments are stored in the Thread object.
// No result.
void StubCodeCompiler::GenerateRunExceptionHandlerStub() {
  ASSERT(kExceptionObjectReg == EAX);
  ASSERT(kStackTraceObjectReg == EDX);
  __ movl(EBX, Address(THR, target::Thread::resume_pc_offset()));

  ASSERT(target::CanLoadFromThread(NullObject()));
  __ movl(ECX, Address(THR, target::Thread::OffsetFromThread(NullObject())));

  // Load the exception from the current thread.
  Address exception_addr(THR, target::Thread::active_exception_offset());
  __ movl(kExceptionObjectReg, exception_addr);
  __ movl(exception_addr, ECX);

  // Load the stacktrace from the current thread.
  Address stacktrace_addr(THR, target::Thread::active_stacktrace_offset());
  __ movl(kStackTraceObjectReg, stacktrace_addr);
  __ movl(stacktrace_addr, ECX);

  __ jmp(EBX);  // Jump to continuation point.
}

// Deoptimize a frame on the call stack before rewinding.
// The arguments are stored in the Thread object.
// No result.
void StubCodeCompiler::GenerateDeoptForRewindStub() {
  // Push the deopt pc.
  __ pushl(Address(THR, target::Thread::resume_pc_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);

  // After we have deoptimized, jump to the correct frame.
  __ EnterStubFrame();
  __ CallRuntime(kRewindPostDeoptRuntimeEntry, 0);
  __ LeaveFrame();
  __ int3();
}

// Calls to the runtime to optimize the given function.
// EBX: function to be reoptimized.
// ARGS_DESC_REG: argument descriptor (preserved).
void StubCodeCompiler::GenerateOptimizeFunctionStub() {
  __ movl(CODE_REG, Address(THR, target::Thread::optimize_stub_offset()));
  __ EnterStubFrame();
  __ pushl(ARGS_DESC_REG);
  __ pushl(Immediate(0));  // Setup space on stack for return value.
  __ pushl(EBX);
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ popl(EAX);  // Discard argument.
  __ popl(FUNCTION_REG);   // Get Function object
  __ popl(ARGS_DESC_REG);  // Restore argument descriptor.
  __ LeaveFrame();
  __ movl(CODE_REG,
          FieldAddress(FUNCTION_REG, target::Function::code_offset()));
  __ jmp(FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
  __ int3();
}

// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Return ZF set.
// Note: A Mint cannot contain a value that would fit in Smi.
static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right,
                                                 const Register temp) {
  Label reference_compare, done, check_mint;
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
  __ movl(temp, FieldAddress(left, target::Double::value_offset() +
                                       0 * target::kWordSize));
  __ cmpl(temp, FieldAddress(right, target::Double::value_offset() +
                                        0 * target::kWordSize));
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ movl(temp, FieldAddress(left, target::Double::value_offset() +
                                       1 * target::kWordSize));
  __ cmpl(temp, FieldAddress(right, target::Double::value_offset() +
                                        1 * target::kWordSize));
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid, temp);
  __ j(NOT_EQUAL, &reference_compare, Assembler::kNearJump);
  __ CompareClassId(right, kMintCid, temp);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ movl(temp, FieldAddress(left, target::Mint::value_offset() +
                                       0 * target::kWordSize));
  __ cmpl(temp, FieldAddress(right, target::Mint::value_offset() +
                                        0 * target::kWordSize));
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ movl(temp, FieldAddress(left, target::Mint::value_offset() +
                                       1 * target::kWordSize));
  __ cmpl(temp, FieldAddress(right, target::Mint::value_offset() +
                                        1 * target::kWordSize));
  __ jmp(&done, Assembler::kNearJump);

  __ Bind(&reference_compare);
  __ cmpl(left, right);
  __ Bind(&done);
}

// Called only from unoptimized code. All relevant registers have been saved.
// TOS + 0: return address
// TOS + 1: right argument.
// TOS + 2: left argument.
// Returns ZF set.
void StubCodeCompiler::GenerateUnoptimizedIdenticalWithNumberCheckStub() {
#if !defined(PRODUCT)
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(EAX);
  __ movzxb(EAX, Address(EAX, target::Isolate::single_step_offset()));
  __ cmpl(EAX, Immediate(0));
  __ j(NOT_EQUAL, &stepping);
  __ Bind(&done_stepping);
#endif

  const Register left = EAX;
  const Register right = EDX;
  const Register temp = ECX;
  __ movl(left, Address(ESP, 2 * target::kWordSize));
  __ movl(right, Address(ESP, 1 * target::kWordSize));
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
void StubCodeCompiler::GenerateOptimizedIdenticalWithNumberCheckStub() {
  const Register left = EAX;
  const Register right = EDX;
  const Register temp = ECX;
  __ movl(left, Address(ESP, 2 * target::kWordSize));
  __ movl(right, Address(ESP, 1 * target::kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp);
  __ ret();
}

// Called from megamorphic calls.
//  EBX: receiver (passed to target)
//  IC_DATA_REG: target::MegamorphicCache (preserved)
// Passed to target:
//  EBX: target entry point
//  FUNCTION_REG: target function
//  ARGS_DESC_REG: argument descriptor
void StubCodeCompiler::GenerateMegamorphicCallStub() {
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
  __ pushl(EBX);  // save receiver
  __ movl(EBX,
          FieldAddress(IC_DATA_REG, target::MegamorphicCache::mask_offset()));
  __ movl(EDI, FieldAddress(IC_DATA_REG,
                            target::MegamorphicCache::buckets_offset()));
  // EDI: cache buckets array.
  // EBX: mask as a smi.

  // Tag cid as a smi.
  __ addl(EAX, EAX);

  // Compute the table index.
  ASSERT(target::MegamorphicCache::kSpreadFactor == 7);
  // Use leal and subl multiply with 7 == 8 - 1.
  __ leal(EDX, Address(EAX, TIMES_8, 0));
  __ subl(EDX, EAX);

  Label loop;
  __ Bind(&loop);
  __ andl(EDX, EBX);

  const intptr_t base = target::Array::data_offset();
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
  __ movl(FUNCTION_REG,
          FieldAddress(EDI, EDX, TIMES_4, base + target::kWordSize));
  __ movl(ARGS_DESC_REG,
          FieldAddress(IC_DATA_REG,
                       target::CallSiteData::arguments_descriptor_offset()));
  __ popl(EBX);  // restore receiver
  __ jmp(FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));

  __ Bind(&probe_failed);
  // Probe failed, check if it is a miss.
  __ cmpl(FieldAddress(EDI, EDX, TIMES_4, base),
          Immediate(target::ToRawSmi(kIllegalCid)));
  Label miss;
  __ j(ZERO, &miss, Assembler::kNearJump);

  // Try next entry in the table.
  __ AddImmediate(EDX, Immediate(target::ToRawSmi(1)));
  __ jmp(&loop);

  // Load cid for the Smi case.
  __ Bind(&smi_case);
  __ movl(EAX, Immediate(kSmiCid));
  __ jmp(&cid_loaded);

  __ Bind(&miss);
  __ popl(EBX);  // restore receiver
  GenerateSwitchableCallMissStub();
}

void StubCodeCompiler::GenerateICCallThroughCodeStub() {
  __ int3();  // AOT only.
}

void StubCodeCompiler::GenerateMonomorphicSmiableCheckStub() {
  __ int3();  // AOT only.
}

// Called from switchable IC calls.
//  EBX: receiver
void StubCodeCompiler::GenerateSwitchableCallMissStub() {
  __ movl(CODE_REG,
          Address(THR, target::Thread::switchable_call_miss_stub_offset()));
  __ EnterStubFrame();
  __ pushl(EBX);  // Preserve receiver.

  __ pushl(Immediate(0));  // Result slot.
  __ pushl(Immediate(0));  // Arg0: stub out.
  __ pushl(EBX);           // Arg1: Receiver
  __ CallRuntime(kSwitchableCallMissRuntimeEntry, 2);
  __ popl(ECX);
  __ popl(CODE_REG);  // result = stub
  __ popl(ECX);       // result = IC

  __ popl(EBX);  // Restore receiver.
  __ LeaveFrame();

  __ movl(EAX, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                          CodeEntryKind::kNormal)));
  __ jmp(EAX);
}

void StubCodeCompiler::GenerateSingleTargetCallStub() {
  __ int3();  // AOT only.
}

static ScaleFactor GetScaleFactor(intptr_t size) {
  switch (size) {
    case 1:
      return TIMES_1;
    case 2:
      return TIMES_2;
    case 4:
      return TIMES_4;
    case 8:
      return TIMES_8;
    case 16:
      return TIMES_16;
  }
  UNREACHABLE();
  return static_cast<ScaleFactor>(0);
}

void StubCodeCompiler::GenerateAllocateTypedDataArrayStub(intptr_t cid) {
  const intptr_t element_size = TypedDataElementSizeInBytes(cid);
  const intptr_t max_len = TypedDataMaxNewSpaceElements(cid);
  ScaleFactor scale_factor = GetScaleFactor(element_size);

  COMPILE_ASSERT(AllocateTypedDataArrayABI::kLengthReg == EAX);
  COMPILE_ASSERT(AllocateTypedDataArrayABI::kResultReg == EAX);

  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    // Save length argument for possible runtime call, as
    // EAX is clobbered.
    Label call_runtime;
    __ pushl(AllocateTypedDataArrayABI::kLengthReg);

    NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, &call_runtime, ECX));
    __ movl(EDI, AllocateTypedDataArrayABI::kLengthReg);
    /* Check that length is a positive Smi. */
    /* EDI: requested array length argument. */
    __ testl(EDI, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, &call_runtime);
    __ SmiUntag(EDI);
    /* Check for length >= 0 && length <= max_len. */
    /* EDI: untagged array length. */
    __ cmpl(EDI, Immediate(max_len));
    __ j(ABOVE, &call_runtime);
    /* Special case for scaling by 16. */
    if (scale_factor == TIMES_16) {
      /* double length of array. */
      __ addl(EDI, EDI);
      /* only scale by 8. */
      scale_factor = TIMES_8;
    }

    const intptr_t fixed_size_plus_alignment_padding =
        target::TypedData::HeaderSize() +
        target::ObjectAlignment::kObjectAlignment - 1;
    __ leal(EDI, Address(EDI, scale_factor, fixed_size_plus_alignment_padding));
    __ andl(EDI, Immediate(-target::ObjectAlignment::kObjectAlignment));
    __ movl(EAX, Address(THR, target::Thread::top_offset()));
    __ movl(EBX, EAX);
    /* EDI: allocation size. */
    __ addl(EBX, EDI);
    __ j(CARRY, &call_runtime);

    /* Check if the allocation fits into the remaining space. */
    /* EAX: potential new object start. */
    /* EBX: potential next object start. */
    /* EDI: allocation size. */
    __ cmpl(EBX, Address(THR, target::Thread::end_offset()));
    __ j(ABOVE_EQUAL, &call_runtime);

    /* Successfully allocated the object(s), now update top to point to */
    /* next object start and initialize the object. */
    __ movl(Address(THR, target::Thread::top_offset()), EBX);
    __ addl(EAX, Immediate(kHeapObjectTag));

    /* Initialize the tags. */
    /* EAX: new object start as a tagged pointer. */
    /* EBX: new object end address. */
    /* EDI: allocation size. */
    {
      Label size_tag_overflow, done;
      __ cmpl(EDI, Immediate(target::UntaggedObject::kSizeTagMaxSizeTag));
      __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
      __ shll(EDI, Immediate(target::UntaggedObject::kTagBitsSizeTagPos -
                             target::ObjectAlignment::kObjectAlignmentLog2));
      __ jmp(&done, Assembler::kNearJump);
      __ Bind(&size_tag_overflow);
      __ movl(EDI, Immediate(0));
      __ Bind(&done);
      /* Get the class index and insert it into the tags. */
      uword tags =
          target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
      __ orl(EDI, Immediate(tags));
      __ movl(FieldAddress(EAX, target::Object::tags_offset()),
              EDI); /* Tags. */
    }

    /* Set the length field. */
    /* EAX: new object start as a tagged pointer. */
    /* EBX: new object end address. */
    __ popl(EDI); /* Array length. */
    __ StoreIntoObjectNoBarrier(
        EAX, FieldAddress(EAX, target::TypedDataBase::length_offset()), EDI);

    /* Initialize all array elements to 0. */
    /* EAX: new object start as a tagged pointer. */
    /* EBX: new object end address. */
    /* EDI: iterator which initially points to the start of the variable */
    /* ECX: scratch register. */
    /* data area to be initialized. */
    __ xorl(ECX, ECX); /* Zero. */
    __ leal(EDI, FieldAddress(EAX, target::TypedData::HeaderSize()));
    __ StoreInternalPointer(
        EAX, FieldAddress(EAX, target::PointerBase::data_offset()), EDI);
    Label loop;
    __ Bind(&loop);
    for (intptr_t offset = 0; offset < target::kObjectAlignment;
         offset += target::kWordSize) {
      __ movl(Address(EDI, offset), ECX);
    }
    // Safe to only check every kObjectAlignment bytes instead of each word.
    ASSERT(kAllocationRedZoneSize >= target::kObjectAlignment);
    __ addl(EDI, Immediate(target::kObjectAlignment));
    __ cmpl(EDI, EBX);
    __ j(UNSIGNED_LESS, &loop);

    __ ret();

    __ Bind(&call_runtime);
    __ popl(AllocateTypedDataArrayABI::kLengthReg);
  }

  __ EnterStubFrame();
  __ PushObject(Object::null_object());  // Make room for the result.
  __ pushl(Immediate(target::ToRawSmi(cid)));
  __ pushl(AllocateTypedDataArrayABI::kLengthReg);
  __ CallRuntime(kAllocateTypedDataRuntimeEntry, 2);
  __ Drop(2);  // Drop arguments.
  __ popl(AllocateTypedDataArrayABI::kResultReg);
  __ LeaveStubFrame();
  __ ret();
}

}  // namespace compiler

}  // namespace dart

#endif  // defined(TARGET_ARCH_IA32)
