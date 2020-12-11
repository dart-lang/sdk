// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"
#include "vm/globals.h"

// For `AllocateObjectInstr::WillAllocateNewOrRemembered`
// For `GenericCheckBoundInstr::UseUnboxedRepresentation`
#include "vm/compiler/backend/il.h"

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/backend/locations.h"
#include "vm/compiler/stub_code_compiler.h"

#if defined(TARGET_ARCH_X64)

#include "vm/class_id.h"
#include "vm/code_entry_kind.h"
#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/constants.h"
#include "vm/instructions.h"
#include "vm/static_type_exactness_state.h"
#include "vm/tags.h"

#define __ assembler->

namespace dart {

DEFINE_FLAG(bool, inline_alloc, true, "Inline allocation of objects.");
DEFINE_FLAG(bool,
            use_slow_path,
            false,
            "Set to true for debugging & verifying the slow paths.");
DECLARE_FLAG(bool, precompiled_mode);

namespace compiler {

// Ensures that [RAX] is a new object, if not it will be added to the remembered
// set via a leaf runtime call.
//
// WARNING: This might clobber all registers except for [RAX], [THR] and [FP].
// The caller should simply call LeaveStubFrame() and return.
static void EnsureIsNewOrRemembered(Assembler* assembler,
                                    bool preserve_registers = true) {
  // If the object is not remembered we call a leaf-runtime to add it to the
  // remembered set.
  Label done;
  __ testq(RAX, Immediate(1 << target::ObjectAlignment::kNewObjectBitPosition));
  __ BranchIf(NOT_ZERO, &done);

  if (preserve_registers) {
    __ EnterCallRuntimeFrame(0);
  } else {
    __ ReserveAlignedFrameSpace(0);
  }
  __ movq(CallingConventions::kArg1Reg, RAX);
  __ movq(CallingConventions::kArg2Reg, THR);
  __ CallRuntime(kEnsureRememberedAndMarkingDeferredRuntimeEntry, 2);
  if (preserve_registers) {
    __ LeaveCallRuntimeFrame();
  }

  __ Bind(&done);
}

// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of last argument in argument array.
//   RSP + 8*R10 : address of first argument in argument array.
//   RSP + 8*R10 + 8 : address of return value.
//   RBX : address of the runtime function to call.
//   R10 : number of arguments to the call.
// Must preserve callee saved registers R12 and R13.
void StubCodeCompiler::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t thread_offset = target::NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = target::NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = target::NativeArguments::argv_offset();
  const intptr_t retval_offset = target::NativeArguments::retval_offset();

  __ movq(CODE_REG,
          Address(THR, target::Thread::call_to_runtime_stub_offset()));
  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ movq(Address(THR, target::Thread::top_exit_frame_info_offset()), RBP);

  // Mark that the thread exited generated code through a runtime call.
  __ movq(Address(THR, target::Thread::exit_through_ffi_offset()),
          Immediate(target::Thread::exit_through_runtime_call()));

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
  __ subq(RSP, Immediate(target::NativeArguments::StructSize()));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass target::NativeArguments structure by value and call runtime.
  __ movq(Address(RSP, thread_offset), THR);  // Set thread in NativeArgs.
  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  __ movq(Address(RSP, argc_tag_offset),
          R10);  // Set argc in target::NativeArguments.
  // Compute argv.
  __ leaq(RAX,
          Address(RBP, R10, TIMES_8,
                  target::frame_layout.param_end_from_fp * target::kWordSize));
  __ movq(Address(RSP, argv_offset),
          RAX);  // Set argv in target::NativeArguments.
  __ addq(RAX,
          Immediate(1 * target::kWordSize));  // Retval is next to 1st argument.
  __ movq(Address(RSP, retval_offset),
          RAX);  // Set retval in target::NativeArguments.
#if defined(TARGET_OS_WINDOWS)
  ASSERT(target::NativeArguments::StructSize() >
         CallingConventions::kRegisterTransferLimit);
  __ movq(CallingConventions::kArg1Reg, RSP);
#endif
  __ CallCFunction(RBX);

  // Mark that the thread is executing Dart code.
  __ movq(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Mark that the thread has not exited generated Dart code.
  __ movq(Address(THR, target::Thread::exit_through_ffi_offset()),
          Immediate(0));

  // Reset exit frame information in Isolate's mutator thread structure.
  __ movq(Address(THR, target::Thread::top_exit_frame_info_offset()),
          Immediate(0));

  // Restore the global object pool after returning from runtime (old space is
  // moving, so the GOP could have been relocated).
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ movq(PP, Address(THR, target::Thread::global_object_pool_offset()));
  }

  __ LeaveStubFrame();

  // The following return can jump to a lazy-deopt stub, which assumes RAX
  // contains a return value and will save it in a GC-visible way.  We therefore
  // have to ensure RAX does not contain any garbage value left from the C
  // function we called (which has return type "void").
  // (See GenerateDeoptimizationSequence::saved_result_slot_from_fp.)
  __ xorq(RAX, RAX);
  __ ret();
}

void StubCodeCompiler::GenerateSharedStubGeneric(
    Assembler* assembler,
    bool save_fpu_registers,
    intptr_t self_code_stub_offset_from_thread,
    bool allow_return,
    std::function<void()> perform_runtime_call) {
  // We want the saved registers to appear like part of the caller's frame, so
  // we push them before calling EnterStubFrame.
  const RegisterSet saved_registers(
      kDartAvailableCpuRegs, save_fpu_registers ? kAllFpuRegistersList : 0);
  __ PushRegisters(saved_registers);

  const intptr_t kSavedCpuRegisterSlots =
      Utils::CountOneBitsWord(kDartAvailableCpuRegs);
  const intptr_t kSavedFpuRegisterSlots =
      save_fpu_registers
          ? kNumberOfFpuRegisters * kFpuRegisterSize / target::kWordSize
          : 0;
  const intptr_t kAllSavedRegistersSlots =
      kSavedCpuRegisterSlots + kSavedFpuRegisterSlots;

  // Copy down the return address so the stack layout is correct.
  __ pushq(Address(RSP, kAllSavedRegistersSlots * target::kWordSize));
  __ movq(CODE_REG, Address(THR, self_code_stub_offset_from_thread));
  __ EnterStubFrame();
  perform_runtime_call();
  if (!allow_return) {
    __ Breakpoint();
    return;
  }
  __ LeaveStubFrame();
  // Copy up the return address (in case it was changed).
  __ popq(TMP);
  __ movq(Address(RSP, kAllSavedRegistersSlots * target::kWordSize), TMP);
  __ PopRegisters(saved_registers);
  __ ret();
}

void StubCodeCompiler::GenerateSharedStub(
    Assembler* assembler,
    bool save_fpu_registers,
    const RuntimeEntry* target,
    intptr_t self_code_stub_offset_from_thread,
    bool allow_return,
    bool store_runtime_result_in_result_register) {
  auto perform_runtime_call = [&]() {
    if (store_runtime_result_in_result_register) {
      __ PushImmediate(Immediate(0));
    }
    __ CallRuntime(*target, /*argument_count=*/0);
    if (store_runtime_result_in_result_register) {
      __ PopRegister(RAX);
      __ movq(Address(RBP, target::kWordSize *
                               StubCodeCompiler::WordOffsetFromFpToCpuRegister(
                                   SharedSlowPathStubABI::kResultReg)),
              RAX);
    }
  };
  GenerateSharedStubGeneric(assembler, save_fpu_registers,
                            self_code_stub_offset_from_thread, allow_return,
                            perform_runtime_call);
}

void StubCodeCompiler::GenerateEnterSafepointStub(Assembler* assembler) {
  RegisterSet all_registers;
  all_registers.AddAllGeneralRegisters();
  __ PushRegisters(all_registers);

  __ EnterFrame(0);
  __ ReserveAlignedFrameSpace(0);
  __ movq(RAX, Address(THR, kEnterSafepointRuntimeEntry.OffsetFromThread()));
  __ CallCFunction(RAX);
  __ LeaveFrame();

  __ PopRegisters(all_registers);
  __ ret();
}

void StubCodeCompiler::GenerateExitSafepointStub(Assembler* assembler) {
  RegisterSet all_registers;
  all_registers.AddAllGeneralRegisters();
  __ PushRegisters(all_registers);

  __ EnterFrame(0);
  __ ReserveAlignedFrameSpace(0);

  // Set the execution state to VM while waiting for the safepoint to end.
  // This isn't strictly necessary but enables tests to check that we're not
  // in native code anymore. See tests/ffi/function_gc_test.dart for example.
  __ movq(Address(THR, target::Thread::execution_state_offset()),
          Immediate(target::Thread::vm_execution_state()));

  __ movq(RAX, Address(THR, kExitSafepointRuntimeEntry.OffsetFromThread()));
  __ CallCFunction(RAX);
  __ LeaveFrame();

  __ PopRegisters(all_registers);
  __ ret();
}

// Calls native code within a safepoint.
//
// On entry:
//   Stack: arguments set up and aligned for native call, excl. shadow space
//   RBX = target address to call
//
// On exit:
//   Stack pointer lowered by shadow space
//   RBX, R12 clobbered
void StubCodeCompiler::GenerateCallNativeThroughSafepointStub(
    Assembler* assembler) {
  __ movq(R12, compiler::Immediate(target::Thread::exit_through_ffi()));
  __ TransitionGeneratedToNative(RBX, FPREG, R12,
                                 /*enter_safepoint=*/true);

  __ popq(R12);
  __ CallCFunction(RBX, /*restore_rsp=*/true);

  __ TransitionNativeToGenerated(/*leave_safepoint=*/true);

  // Faster than jmp because it doesn't confuse the branch predictor.
  __ pushq(R12);
  __ ret();
}

#if !defined(DART_PRECOMPILER)
static const RegisterSet kArgumentRegisterSet(
    CallingConventions::kArgumentRegisters,
    CallingConventions::kFpuArgumentRegisters);

void StubCodeCompiler::GenerateJITCallbackTrampolines(
    Assembler* assembler,
    intptr_t next_callback_id) {
  Label done;

  // RAX is volatile and not used for passing any arguments.
  COMPILE_ASSERT(!IsCalleeSavedRegister(RAX) && !IsArgumentRegister(RAX));

  for (intptr_t i = 0;
       i < NativeCallbackTrampolines::NumCallbackTrampolinesPerPage(); ++i) {
    __ movq(RAX, compiler::Immediate(next_callback_id + i));
    __ jmp(&done);
  }

  ASSERT_EQUAL(__ CodeSize(),
               kNativeCallbackTrampolineSize *
                   NativeCallbackTrampolines::NumCallbackTrampolinesPerPage());

  __ Bind(&done);

  const intptr_t shared_stub_start = __ CodeSize();

  // Save THR which is callee-saved.
  __ pushq(THR);

  // 2 = THR & return address
  COMPILE_ASSERT(2 == StubCodeCompiler::kNativeCallbackTrampolineStackDelta);

  // Save the callback ID.
  __ pushq(RAX);

  // Save all registers which might hold arguments.
  __ PushRegisters(kArgumentRegisterSet);

  // Load the thread, verify the callback ID and exit the safepoint.
  //
  // We exit the safepoint inside DLRT_GetThreadForNativeCallbackTrampoline
  // in order to save code size on this shared stub.
  {
    __ EnterFrame(0);
    __ ReserveAlignedFrameSpace(0);

    COMPILE_ASSERT(RAX != CallingConventions::kArg1Reg);
    __ movq(CallingConventions::kArg1Reg, RAX);
    __ movq(RAX, compiler::Immediate(reinterpret_cast<int64_t>(
                     DLRT_GetThreadForNativeCallbackTrampoline)));
    __ CallCFunction(RAX);
    __ movq(THR, RAX);

    __ LeaveFrame();
  }

  // Restore the arguments.
  __ PopRegisters(kArgumentRegisterSet);

  // Restore the callback ID.
  __ popq(RAX);

  // Current state:
  //
  // Stack:
  //  <old stack (arguments)>
  //  <return address>
  //  <saved THR>
  //
  // Registers: Like entry, except RAX == callback_id and THR == thread
  //            All argument registers are untouched.

  COMPILE_ASSERT(!IsCalleeSavedRegister(TMP) && !IsArgumentRegister(TMP));

  // Load the target from the thread.
  __ movq(TMP, compiler::Address(
                   THR, compiler::target::Thread::callback_code_offset()));
  __ movq(TMP, compiler::FieldAddress(
                   TMP, compiler::target::GrowableObjectArray::data_offset()));
  __ movq(TMP, __ ElementAddressForRegIndex(
                   /*external=*/false,
                   /*array_cid=*/kArrayCid,
                   /*index, smi-tagged=*/compiler::target::kWordSize * 2,
                   /*index_unboxed=*/false,
                   /*array=*/TMP,
                   /*index=*/RAX));
  __ movq(TMP, compiler::FieldAddress(
                   TMP, compiler::target::Code::entry_point_offset()));

  // On entry to the function, there will be two extra slots on the stack:
  // the saved THR and the return address. The target will know to skip them.
  __ call(TMP);

  // EnterSafepoint takes care to not clobber *any* registers (besides TMP).
  __ EnterSafepoint();

  // Restore THR (callee-saved).
  __ popq(THR);

  __ ret();

  // 'kNativeCallbackSharedStubSize' is an upper bound because the exact
  // instruction size can vary slightly based on OS calling conventions.
  ASSERT((__ CodeSize() - shared_stub_start) <= kNativeCallbackSharedStubSize);
  ASSERT(__ CodeSize() <= VirtualMemory::PageSize());

#if defined(DEBUG)
  while (__ CodeSize() < VirtualMemory::PageSize()) {
    __ Breakpoint();
  }
#endif
}
#endif  // !defined(DART_PRECOMPILER)

// RBX: The extracted method.
// RDX: The type_arguments_field_offset (or 0)
void StubCodeCompiler::GenerateBuildMethodExtractorStub(
    Assembler* assembler,
    const Object& closure_allocation_stub,
    const Object& context_allocation_stub) {
  const intptr_t kReceiverOffsetInWords =
      target::frame_layout.param_end_from_fp + 1;

  __ EnterStubFrame();

  // Push type_arguments vector (or null)
  Label no_type_args;
  __ movq(RCX, Address(THR, target::Thread::object_null_offset()));
  __ cmpq(RDX, Immediate(0));
  __ j(EQUAL, &no_type_args, Assembler::kNearJump);
  __ movq(RAX, Address(RBP, target::kWordSize * kReceiverOffsetInWords));
  __ movq(RCX, Address(RAX, RDX, TIMES_1, 0));
  __ Bind(&no_type_args);
  __ pushq(RCX);

  // Push extracted method.
  __ pushq(RBX);

  // Allocate context.
  {
    Label done, slow_path;
    __ TryAllocateArray(kContextCid, target::Context::InstanceSize(1),
                        &slow_path, Assembler::kFarJump,
                        RAX,  // instance
                        RSI,  // end address
                        RDI);
    __ movq(RSI, Address(THR, target::Thread::object_null_offset()));
    __ movq(FieldAddress(RAX, target::Context::parent_offset()), RSI);
    __ movq(FieldAddress(RAX, target::Context::num_variables_offset()),
            Immediate(1));
    __ jmp(&done);

    __ Bind(&slow_path);

    __ LoadImmediate(/*num_vars=*/R10, Immediate(1));
    __ LoadObject(CODE_REG, context_allocation_stub);
    __ call(FieldAddress(CODE_REG, target::Code::entry_point_offset()));

    __ Bind(&done);
  }

  // Store receiver in context
  __ movq(RSI, Address(RBP, target::kWordSize * kReceiverOffsetInWords));
  __ StoreIntoObject(
      RAX, FieldAddress(RAX, target::Context::variable_offset(0)), RSI);

  // Push context.
  __ pushq(RAX);

  // Allocate closure.
  __ LoadObject(CODE_REG, closure_allocation_stub);
  __ call(FieldAddress(
      CODE_REG, target::Code::entry_point_offset(CodeEntryKind::kUnchecked)));

  // Populate closure object.
  __ popq(RCX);  // Pop context.
  __ StoreIntoObject(RAX, FieldAddress(RAX, target::Closure::context_offset()),
                     RCX);
  __ popq(RCX);  // Pop extracted method.
  __ StoreIntoObjectNoBarrier(
      RAX, FieldAddress(RAX, target::Closure::function_offset()), RCX);
  __ popq(RCX);  // Pop type argument vector.
  __ StoreIntoObjectNoBarrier(
      RAX,
      FieldAddress(RAX, target::Closure::instantiator_type_arguments_offset()),
      RCX);
  __ LoadObject(RCX, EmptyTypeArguments());
  __ StoreIntoObjectNoBarrier(
      RAX, FieldAddress(RAX, target::Closure::delayed_type_arguments_offset()),
      RCX);

  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateDispatchTableNullErrorStub(
    Assembler* assembler) {
  __ EnterStubFrame();
  __ CallRuntime(kNullErrorRuntimeEntry, /*argument_count=*/0);
  // The NullError runtime entry does not return.
  __ Breakpoint();
}

void StubCodeCompiler::GenerateRangeError(Assembler* assembler,
                                          bool with_fpu_regs) {
  auto perform_runtime_call = [&]() {
    // If the generated code has unboxed index/length we need to box them before
    // calling the runtime entry.
    if (GenericCheckBoundInstr::UseUnboxedRepresentation()) {
      Label length, smi_case;

      // The user-controlled index might not fit into a Smi.
      __ addq(RangeErrorABI::kIndexReg, RangeErrorABI::kIndexReg);
      __ BranchIf(NO_OVERFLOW, &length);
      {
        // Allocate a mint, reload the two registers and popualte the mint.
        __ PushImmediate(Immediate(0));
        __ CallRuntime(kAllocateMintRuntimeEntry, /*argument_count=*/0);
        __ PopRegister(RangeErrorABI::kIndexReg);
        __ movq(
            TMP,
            Address(RBP, target::kWordSize *
                             StubCodeCompiler::WordOffsetFromFpToCpuRegister(
                                 RangeErrorABI::kIndexReg)));
        __ movq(FieldAddress(RangeErrorABI::kIndexReg,
                             target::Mint::value_offset()),
                TMP);
        __ movq(
            RangeErrorABI::kLengthReg,
            Address(RBP, target::kWordSize *
                             StubCodeCompiler::WordOffsetFromFpToCpuRegister(
                                 RangeErrorABI::kLengthReg)));
      }

      // Length is guaranteed to be in positive Smi range (it comes from a load
      // of a vm recognized array).
      __ Bind(&length);
      __ SmiTag(RangeErrorABI::kLengthReg);
    }
    __ PushRegister(RangeErrorABI::kLengthReg);
    __ PushRegister(RangeErrorABI::kIndexReg);
    __ CallRuntime(kRangeErrorRuntimeEntry, /*argument_count=*/2);
    __ Breakpoint();
  };

  GenerateSharedStubGeneric(
      assembler, /*save_fpu_registers=*/with_fpu_regs,
      with_fpu_regs
          ? target::Thread::range_error_shared_with_fpu_regs_stub_offset()
          : target::Thread::range_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false, perform_runtime_call);
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
      target::NativeArguments::thread_offset() + native_args_struct_offset;
  const intptr_t argc_tag_offset =
      target::NativeArguments::argc_tag_offset() + native_args_struct_offset;
  const intptr_t argv_offset =
      target::NativeArguments::argv_offset() + native_args_struct_offset;
  const intptr_t retval_offset =
      target::NativeArguments::retval_offset() + native_args_struct_offset;

  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ movq(Address(THR, target::Thread::top_exit_frame_info_offset()), RBP);

  // Mark that the thread exited generated code through a runtime call.
  __ movq(Address(THR, target::Thread::exit_through_ffi_offset()),
          Immediate(target::Thread::exit_through_runtime_call()));

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
  __ subq(RSP, Immediate(target::NativeArguments::StructSize()));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Pass target::NativeArguments structure by value and call native function.
  __ movq(Address(RSP, thread_offset), THR);  // Set thread in NativeArgs.
  __ movq(Address(RSP, argc_tag_offset),
          R10);  // Set argc in target::NativeArguments.
  __ movq(Address(RSP, argv_offset),
          RAX);  // Set argv in target::NativeArguments.
  __ leaq(RAX,
          Address(RBP, 2 * target::kWordSize));  // Compute return value addr.
  __ movq(Address(RSP, retval_offset),
          RAX);  // Set retval in target::NativeArguments.

  // Pass the pointer to the target::NativeArguments.
  __ movq(CallingConventions::kArg1Reg, RSP);
  // Pass pointer to function entrypoint.
  __ movq(CallingConventions::kArg2Reg, RBX);

  __ movq(RAX, wrapper_address);
  __ CallCFunction(RAX);

  // Mark that the thread is executing Dart code.
  __ movq(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Mark that the thread has not exited generated Dart code.
  __ movq(Address(THR, target::Thread::exit_through_ffi_offset()),
          Immediate(0));

  // Reset exit frame information in Isolate's mutator thread structure.
  __ movq(Address(THR, target::Thread::top_exit_frame_info_offset()),
          Immediate(0));

  // Restore the global object pool after returning from runtime (old space is
  // moving, so the GOP could have been relocated).
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ movq(PP, Address(THR, target::Thread::global_object_pool_offset()));
  }

  __ LeaveStubFrame();
  __ ret();
}

void StubCodeCompiler::GenerateCallNoScopeNativeStub(Assembler* assembler) {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::no_scope_native_wrapper_entry_point_offset()));
}

void StubCodeCompiler::GenerateCallAutoScopeNativeStub(Assembler* assembler) {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::auto_scope_native_wrapper_entry_point_offset()));
}

// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of return value.
//   RAX : address of first argument in argument array.
//   RBX : address of the native function to call.
//   R10 : argc_tag including number of arguments and function kind.
void StubCodeCompiler::GenerateCallBootstrapNativeStub(Assembler* assembler) {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::bootstrap_native_wrapper_entry_point_offset()));
}

// Input parameters:
//   R10: arguments descriptor array.
void StubCodeCompiler::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(R10);  // Preserve arguments descriptor array.
  // Setup space on stack for return value.
  __ pushq(Immediate(0));
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  __ popq(CODE_REG);  // Get Code object result.
  __ popq(R10);       // Restore arguments descriptor array.
  // Remove the stub frame as we are about to jump to the dart function.
  __ LeaveStubFrame();

  __ movq(RBX, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ jmp(RBX);
}

// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// R10: arguments descriptor array.
void StubCodeCompiler::GenerateFixCallersTargetStub(Assembler* assembler) {
  Label monomorphic;
  __ BranchOnMonomorphicCheckedEntryJIT(&monomorphic);

  // This was a static call.
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ movq(CODE_REG,
          Address(THR, target::Thread::fix_callers_target_code_offset()));
  __ EnterStubFrame();
  __ pushq(R10);  // Preserve arguments descriptor array.
  // Setup space on stack for return value.
  __ pushq(Immediate(0));
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  __ popq(CODE_REG);  // Get Code object.
  __ popq(R10);       // Restore arguments descriptor array.
  __ movq(RAX, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ LeaveStubFrame();
  __ jmp(RAX);
  __ int3();

  __ Bind(&monomorphic);
  // This was a switchable call.
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ movq(CODE_REG,
          Address(THR, target::Thread::fix_callers_target_code_offset()));
  __ EnterStubFrame();
  __ pushq(RBX);           // Preserve cache (guarded CID as Smi).
  __ pushq(RDX);           // Preserve receiver.
  __ pushq(Immediate(0));  // Result slot.
  __ CallRuntime(kFixCallersTargetMonomorphicRuntimeEntry, 0);
  __ popq(CODE_REG);  // Get Code object.
  __ popq(RDX);       // Restore receiver.
  __ popq(RBX);       // Restore cache (guarded CID as Smi).
  __ movq(RAX, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                          CodeEntryKind::kMonomorphic)));
  __ LeaveStubFrame();
  __ jmp(RAX);
  __ int3();
}

// Called from object allocate instruction when the allocation stub has been
// disabled.
void StubCodeCompiler::GenerateFixAllocationStubTargetStub(
    Assembler* assembler) {
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ movq(CODE_REG,
          Address(THR, target::Thread::fix_allocation_stub_code_offset()));
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ pushq(Immediate(0));
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  __ popq(CODE_REG);  // Get Code object.
  __ movq(RAX, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ LeaveStubFrame();
  __ jmp(RAX);
  __ int3();
}

// Input parameters:
//   R10: smi-tagged argument count, may be zero.
//   RBP[target::frame_layout.param_end_from_fp + 1]: last argument.
static void PushArrayOfArguments(Assembler* assembler) {
  __ LoadObject(R12, NullObject());
  // Allocate array to store arguments of caller.
  __ movq(RBX, R12);  // Null element type for raw Array.
  __ Call(StubCodeAllocateArray());
  __ SmiUntag(R10);
  // RAX: newly allocated array.
  // R10: length of the array (was preserved by the stub).
  __ pushq(RAX);  // Array is in RAX and on top of stack.
  __ leaq(R12,
          Address(RBP, R10, TIMES_8,
                  target::frame_layout.param_end_from_fp * target::kWordSize));
  __ leaq(RBX, FieldAddress(RAX, target::Array::data_offset()));
  // R12: address of first argument on stack.
  // RBX: address of first argument in array.
  Label loop, loop_condition;
#if defined(DEBUG)
  static auto const kJumpLength = Assembler::kFarJump;
#else
  static auto const kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
  __ jmp(&loop_condition, kJumpLength);
  __ Bind(&loop);
  __ movq(RDI, Address(R12, 0));
  // Generational barrier is needed, array is not necessarily in new space.
  __ StoreIntoObject(RAX, Address(RBX, 0), RDI);
  __ addq(RBX, Immediate(target::kWordSize));
  __ subq(R12, Immediate(target::kWordSize));
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
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - RAX);
  const intptr_t saved_exception_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - RAX);
  const intptr_t saved_stacktrace_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - RDX);
  // Result in RAX is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    if (i == CODE_REG) {
      // Save the original value of CODE_REG pushed before invoking this stub
      // instead of the value used to call this stub.
      __ pushq(Address(RBP, 2 * target::kWordSize));
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
    __ movq(RBX, Address(RBP, saved_result_slot_from_fp * target::kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into RBX temporarily.
    __ movq(RBX,
            Address(RBP, saved_exception_slot_from_fp * target::kWordSize));
    __ movq(RDX,
            Address(RBP, saved_stacktrace_slot_from_fp * target::kWordSize));
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
    __ movq(RBX, Address(RBP, target::frame_layout.first_local_from_fp *
                                  target::kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore exception into RBX.
    __ movq(RBX, Address(RBP, target::frame_layout.first_local_from_fp *
                                  target::kWordSize));
    // Restore stacktrace into RDX.
    __ movq(RDX, Address(RBP, (target::frame_layout.first_local_from_fp - 1) *
                                  target::kWordSize));
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
  __ pushq(Immediate(target::ToRawSmi(0)));  // Space for the result.
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
void StubCodeCompiler::GenerateDeoptimizeLazyFromReturnStub(
    Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ pushq(Immediate(kZapCodeReg));
  // Return address for "call" to deopt stub.
  __ pushq(Immediate(kZapReturnAddress));
  __ movq(CODE_REG,
          Address(THR, target::Thread::lazy_deopt_from_return_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromReturn);
  __ ret();
}

// RAX: exception, must be preserved
// RDX: stacktrace, must be preserved
void StubCodeCompiler::GenerateDeoptimizeLazyFromThrowStub(
    Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ pushq(Immediate(kZapCodeReg));
  // Return address for "call" to deopt stub.
  __ pushq(Immediate(kZapReturnAddress));
  __ movq(CODE_REG,
          Address(THR, target::Thread::lazy_deopt_from_throw_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromThrow);
  __ ret();
}

void StubCodeCompiler::GenerateDeoptimizeStub(Assembler* assembler) {
  __ popq(TMP);
  __ pushq(CODE_REG);
  __ pushq(TMP);
  __ movq(CODE_REG, Address(THR, target::Thread::deoptimize_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);
  __ ret();
}

// Input:
//   RBX - icdata/megamorphic_cache
//   RDI - arguments descriptor size
static void GenerateNoSuchMethodDispatcherBody(Assembler* assembler,
                                               Register receiver_reg) {
  __ pushq(Immediate(0));  // Setup space on stack for result.
  __ pushq(receiver_reg);  // Receiver.
  __ pushq(RBX);           // ICData/MegamorphicCache.
  __ pushq(R10);           // Arguments descriptor array.

  // Adjust arguments count.
  __ cmpq(
      FieldAddress(R10, target::ArgumentsDescriptor::type_args_len_offset()),
      Immediate(0));
  __ movq(R10, RDI);
  Label args_count_ok;
  __ j(EQUAL, &args_count_ok, Assembler::kNearJump);
  __ addq(R10, Immediate(target::ToRawSmi(1)));  // Include the type arguments.
  __ Bind(&args_count_ok);

  // R10: Smi-tagged arguments array length.
  PushArrayOfArguments(assembler);
  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromCallStubRuntimeEntry, kNumArgs);
  __ Drop(4);
  __ popq(RAX);  // Return value.
  __ LeaveStubFrame();
  __ ret();
}

// Input:
//   RBX - icdata/megamorphic_cache
//   R10 - argument descriptor
static void GenerateDispatcherCode(Assembler* assembler,
                                   Label* call_target_function) {
  __ Comment("NoSuchMethodDispatch");
  // When lazily generated invocation dispatchers are disabled, the
  // miss-handler may return null.
  __ CompareObject(RAX, NullObject());
  __ j(NOT_EQUAL, call_target_function);

  __ EnterStubFrame();
  // Load the receiver.
  __ movq(RDI, FieldAddress(R10, target::ArgumentsDescriptor::size_offset()));
  __ movq(RAX,
          Address(RBP, RDI, TIMES_HALF_WORD_SIZE,
                  target::frame_layout.param_end_from_fp * target::kWordSize));

  GenerateNoSuchMethodDispatcherBody(assembler, /*receiver_reg=*/RAX);
}

// Input:
//   RBX - icdata/megamorphic_cache
//   RDX - receiver
void StubCodeCompiler::GenerateNoSuchMethodDispatcherStub(
    Assembler* assembler) {
  __ EnterStubFrame();

  __ movq(R10, FieldAddress(
                   RBX, target::CallSiteData::arguments_descriptor_offset()));
  __ movq(RDI, FieldAddress(R10, target::ArgumentsDescriptor::size_offset()));

  GenerateNoSuchMethodDispatcherBody(assembler, /*receiver_reg=*/RDX);
}

// Called for inline allocation of arrays.
// Input parameters:
//   R10 : Array length as Smi.
//   RBX : array element type (either NULL or an instantiated type).
// NOTE: R10 cannot be clobbered here as the caller relies on it being saved.
// The newly allocated object is returned in RAX.
void StubCodeCompiler::GenerateAllocateArrayStub(Assembler* assembler) {
  if (!FLAG_use_slow_path) {
    Label slow_case;
    // Compute the size to be allocated, it is based on the array length
    // and is computed as:
    // RoundedAllocationSize(
    //     (array_length * target::kwordSize) + target::Array::header_size()).
    __ movq(RDI, R10);  // Array Length.
    // Check that length is a positive Smi.
    __ testq(RDI, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, &slow_case);

    __ cmpq(RDI, Immediate(0));
    __ j(LESS, &slow_case);
    // Check for maximum allowed length.
    const Immediate& max_len =
        Immediate(target::ToRawSmi(target::Array::kMaxNewSpaceElements));
    __ cmpq(RDI, max_len);
    __ j(GREATER, &slow_case);

    // Check for allocation tracing.
    NOT_IN_PRODUCT(
        __ MaybeTraceAllocation(kArrayCid, &slow_case, Assembler::kFarJump));

    const intptr_t fixed_size_plus_alignment_padding =
        target::Array::header_size() +
        target::ObjectAlignment::kObjectAlignment - 1;
    // RDI is a Smi.
    __ leaq(RDI, Address(RDI, TIMES_4, fixed_size_plus_alignment_padding));
    ASSERT(kSmiTagShift == 1);
    __ andq(RDI, Immediate(-target::ObjectAlignment::kObjectAlignment));

    const intptr_t cid = kArrayCid;
    __ movq(RAX, Address(THR, target::Thread::top_offset()));

    // RDI: allocation size.
    __ movq(RCX, RAX);
    __ addq(RCX, RDI);
    __ j(CARRY, &slow_case);

    // Check if the allocation fits into the remaining space.
    // RAX: potential new object start.
    // RCX: potential next object start.
    // RDI: allocation size.
    __ cmpq(RCX, Address(THR, target::Thread::end_offset()));
    __ j(ABOVE_EQUAL, &slow_case);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    __ movq(Address(THR, target::Thread::top_offset()), RCX);
    __ addq(RAX, Immediate(kHeapObjectTag));

    // Initialize the tags.
    // RAX: new object start as a tagged pointer.
    // RDI: allocation size.
    {
      Label size_tag_overflow, done;
      __ cmpq(RDI, Immediate(target::ObjectLayout::kSizeTagMaxSizeTag));
      __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
      __ shlq(RDI, Immediate(target::ObjectLayout::kTagBitsSizeTagPos -
                             target::ObjectAlignment::kObjectAlignmentLog2));
      __ jmp(&done, Assembler::kNearJump);

      __ Bind(&size_tag_overflow);
      __ LoadImmediate(RDI, Immediate(0));
      __ Bind(&done);

      // Get the class index and insert it into the tags.
      uword tags = target::MakeTagWordForNewSpaceObject(cid, 0);
      __ orq(RDI, Immediate(tags));
      __ movq(FieldAddress(RAX, target::Array::tags_offset()), RDI);  // Tags.
    }

    // RAX: new object start as a tagged pointer.
    // Store the type argument field.
    // No generational barrier needed, since we store into a new object.
    __ StoreIntoObjectNoBarrier(
        RAX, FieldAddress(RAX, target::Array::type_arguments_offset()), RBX);

    // Set the length field.
    __ StoreIntoObjectNoBarrier(
        RAX, FieldAddress(RAX, target::Array::length_offset()), R10);

    // Initialize all array elements to raw_null.
    // RAX: new object start as a tagged pointer.
    // RCX: new object end address.
    // RDI: iterator which initially points to the start of the variable
    // data area to be initialized.
    __ LoadObject(R12, NullObject());
    __ leaq(RDI, FieldAddress(RAX, target::Array::header_size()));
    Label done;
    Label init_loop;
    __ Bind(&init_loop);
    __ cmpq(RDI, RCX);
#if defined(DEBUG)
    static auto const kJumpLength = Assembler::kFarJump;
#else
    static auto const kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
    __ j(ABOVE_EQUAL, &done, kJumpLength);
    // No generational barrier needed, since we are storing null.
    __ StoreIntoObjectNoBarrier(RAX, Address(RDI, 0), R12);
    __ addq(RDI, Immediate(target::kWordSize));
    __ jmp(&init_loop, kJumpLength);
    __ Bind(&done);
    __ ret();  // returns the newly allocated object in RAX.

    // Unable to allocate the array using the fast inline code, just call
    // into the runtime.
    __ Bind(&slow_case);
  }
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

  // Write-barrier elimination might be enabled for this array (depending on the
  // array length). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(assembler);

  __ LeaveStubFrame();
  __ ret();
}

void StubCodeCompiler::GenerateAllocateMintSharedWithFPURegsStub(
    Assembler* assembler) {
  // For test purpose call allocation stub without inline allocation attempt.
  if (!FLAG_use_slow_path) {
    Label slow_case;
    __ TryAllocate(compiler::MintClass(), &slow_case, Assembler::kNearJump,
                   AllocateMintABI::kResultReg, AllocateMintABI::kTempReg);
    __ Ret();

    __ Bind(&slow_case);
  }
  COMPILE_ASSERT(AllocateMintABI::kResultReg ==
                 SharedSlowPathStubABI::kResultReg);
  GenerateSharedStub(assembler, /*save_fpu_registers=*/true,
                     &kAllocateMintRuntimeEntry,
                     target::Thread::allocate_mint_with_fpu_regs_stub_offset(),
                     /*allow_return=*/true,
                     /*store_runtime_result_in_result_register=*/true);
}

void StubCodeCompiler::GenerateAllocateMintSharedWithoutFPURegsStub(
    Assembler* assembler) {
  // For test purpose call allocation stub without inline allocation attempt.
  if (!FLAG_use_slow_path) {
    Label slow_case;
    __ TryAllocate(compiler::MintClass(), &slow_case, Assembler::kNearJump,
                   AllocateMintABI::kResultReg, AllocateMintABI::kTempReg);
    __ Ret();

    __ Bind(&slow_case);
  }
  COMPILE_ASSERT(AllocateMintABI::kResultReg ==
                 SharedSlowPathStubABI::kResultReg);
  GenerateSharedStub(
      assembler, /*save_fpu_registers=*/false, &kAllocateMintRuntimeEntry,
      target::Thread::allocate_mint_without_fpu_regs_stub_offset(),
      /*allow_return=*/true,
      /*store_runtime_result_in_result_register=*/true);
}

static const RegisterSet kCalleeSavedRegisterSet(
    CallingConventions::kCalleeSaveCpuRegisters,
    CallingConventions::kCalleeSaveXmmRegisters);

// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   RSP : points to return address.
//   RDI : target code
//   RSI : arguments descriptor array.
//   RDX : arguments array.
//   RCX : current thread.
void StubCodeCompiler::GenerateInvokeDartCodeStub(Assembler* assembler) {
  __ pushq(Address(RSP, 0));  // Marker for the profiler.
  __ EnterFrame(0);

  const Register kTargetCodeReg = CallingConventions::kArg1Reg;
  const Register kArgDescReg = CallingConventions::kArg2Reg;
  const Register kArgsReg = CallingConventions::kArg3Reg;
  const Register kThreadReg = CallingConventions::kArg4Reg;

  // Push code object to PC marker slot.
  __ pushq(Address(kThreadReg, target::Thread::invoke_dart_code_stub_offset()));

  // At this point, the stack looks like:
  // | stub code object
  // | saved RBP                                      | <-- RBP
  // | saved PC (return to DartEntry::InvokeFunction) |

  const intptr_t kInitialOffset = 2;
  // Save arguments descriptor array, later replaced by Smi argument count.
  const intptr_t kArgumentsDescOffset = -(kInitialOffset)*target::kWordSize;
  __ pushq(kArgDescReg);

  // Save C++ ABI callee-saved registers.
  __ PushRegisters(kCalleeSavedRegisterSet);

  // If any additional (or fewer) values are pushed, the offsets in
  // target::frame_layout.exit_link_slot_from_entry_fp will need to be changed.

  // Set up THR, which caches the current thread in Dart code.
  if (THR != kThreadReg) {
    __ movq(THR, kThreadReg);
  }

#if defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Save the current VMTag on the stack.
  __ movq(RAX, Assembler::VMTagAddress());
  __ pushq(RAX);

  // Save top resource and top exit frame info. Use RAX as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ movq(RAX, Address(THR, target::Thread::top_resource_offset()));
  __ pushq(RAX);
  __ movq(Address(THR, target::Thread::top_resource_offset()), Immediate(0));

  __ movq(RAX, Address(THR, target::Thread::exit_through_ffi_offset()));
  __ pushq(RAX);
  __ movq(Address(THR, target::Thread::exit_through_ffi_offset()),
          Immediate(0));

  __ movq(RAX, Address(THR, target::Thread::top_exit_frame_info_offset()));
  __ pushq(RAX);

  // The constant target::frame_layout.exit_link_slot_from_entry_fp must be kept
  // in sync with the code above.
  __ EmitEntryFrameVerification();

  __ movq(Address(THR, target::Thread::top_exit_frame_info_offset()),
          Immediate(0));

  // Mark that the thread is executing Dart code. Do this after initializing the
  // exit link for the profiler.
  __ movq(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));

  // Load arguments descriptor array into R10, which is passed to Dart code.
  __ movq(R10, Address(kArgDescReg, VMHandles::kOffsetOfRawPtrInHandle));

  // Push arguments. At this point we only need to preserve kTargetCodeReg.
  ASSERT(kTargetCodeReg != RDX);

  // Load number of arguments into RBX and adjust count for type arguments.
  __ movq(RBX, FieldAddress(R10, target::ArgumentsDescriptor::count_offset()));
  __ cmpq(
      FieldAddress(R10, target::ArgumentsDescriptor::type_args_len_offset()),
      Immediate(0));
  Label args_count_ok;
  __ j(EQUAL, &args_count_ok, Assembler::kNearJump);
  __ addq(RBX, Immediate(target::ToRawSmi(1)));  // Include the type arguments.
  __ Bind(&args_count_ok);
  // Save number of arguments as Smi on stack, replacing saved ArgumentsDesc.
  __ movq(Address(RBP, kArgumentsDescOffset), RBX);
  __ SmiUntag(RBX);

  // Compute address of 'arguments array' data area into RDX.
  __ movq(RDX, Address(kArgsReg, VMHandles::kOffsetOfRawPtrInHandle));
  __ leaq(RDX, FieldAddress(RDX, target::Array::data_offset()));

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ j(ZERO, &done_push_arguments, Assembler::kNearJump);
  __ LoadImmediate(RAX, Immediate(0));
  __ Bind(&push_arguments);
  __ pushq(Address(RDX, RAX, TIMES_8, 0));
  __ incq(RAX);
  __ cmpq(RAX, RBX);
  __ j(LESS, &push_arguments, Assembler::kNearJump);
  __ Bind(&done_push_arguments);

  // Call the Dart code entrypoint.
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ movq(PP, Address(THR, target::Thread::global_object_pool_offset()));
  } else {
    __ xorq(PP, PP);  // GC-safe value into PP.
  }
  __ movq(CODE_REG,
          Address(kTargetCodeReg, VMHandles::kOffsetOfRawPtrInHandle));
  __ movq(kTargetCodeReg,
          FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ call(kTargetCodeReg);  // R10 is the arguments descriptor array.

  // Read the saved number of passed arguments as Smi.
  __ movq(RDX, Address(RBP, kArgumentsDescOffset));

  // Get rid of arguments pushed on the stack.
  __ leaq(RSP, Address(RSP, RDX, TIMES_4, 0));  // RDX is a Smi.

  // Restore the saved top exit frame info and top resource back into the
  // Isolate structure.
  __ popq(Address(THR, target::Thread::top_exit_frame_info_offset()));
  __ popq(Address(THR, target::Thread::exit_through_ffi_offset()));
  __ popq(Address(THR, target::Thread::top_resource_offset()));

  // Restore the current VMTag from the stack.
  __ popq(Assembler::VMTagAddress());

#if defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Restore C++ ABI callee-saved registers.
  __ PopRegisters(kCalleeSavedRegisterSet);
  __ set_constant_pool_allowed(false);

  // Restore the frame pointer.
  __ LeaveFrame();
  __ popq(RCX);

  __ ret();
}

// Helper to generate space allocation of context stub.
// This does not initialise the fields of the context.
// Input:
//   R10: number of context variables.
// Output:
//   RAX: new, uinitialised allocated RawContext object.
// Clobbered:
//   R13
static void GenerateAllocateContextSpaceStub(Assembler* assembler,
                                             Label* slow_case) {
  // First compute the rounded instance size.
  // R10: number of context variables.
  intptr_t fixed_size_plus_alignment_padding =
      (target::Context::header_size() +
       target::ObjectAlignment::kObjectAlignment - 1);
  __ leaq(R13, Address(R10, TIMES_8, fixed_size_plus_alignment_padding));
  __ andq(R13, Immediate(-target::ObjectAlignment::kObjectAlignment));

  // Check for allocation tracing.
  NOT_IN_PRODUCT(
      __ MaybeTraceAllocation(kContextCid, slow_case, Assembler::kFarJump));

  // Now allocate the object.
  // R10: number of context variables.
  __ movq(RAX, Address(THR, target::Thread::top_offset()));
  __ addq(R13, RAX);
  // Check if the allocation fits into the remaining space.
  // RAX: potential new object.
  // R13: potential next object start.
  // R10: number of context variables.
  __ cmpq(R13, Address(THR, target::Thread::end_offset()));
  __ j(ABOVE_EQUAL, slow_case);

  // Successfully allocated the object, now update top to point to
  // next object start and initialize the object.
  // RAX: new object.
  // R13: next object start.
  // R10: number of context variables.
  __ movq(Address(THR, target::Thread::top_offset()), R13);
  // R13: Size of allocation in bytes.
  __ subq(R13, RAX);
  __ addq(RAX, Immediate(kHeapObjectTag));
  // Generate isolate-independent code to allow sharing between isolates.

  // Calculate the size tag.
  // RAX: new object.
  // R10: number of context variables.
  {
    Label size_tag_overflow, done;
    __ leaq(R13, Address(R10, TIMES_8, fixed_size_plus_alignment_padding));
    __ andq(R13, Immediate(-target::ObjectAlignment::kObjectAlignment));
    __ cmpq(R13, Immediate(target::ObjectLayout::kSizeTagMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shlq(R13, Immediate(target::ObjectLayout::kTagBitsSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2));
    __ jmp(&done);

    __ Bind(&size_tag_overflow);
    // Set overflow size tag value.
    __ LoadImmediate(R13, Immediate(0));

    __ Bind(&done);
    // RAX: new object.
    // R10: number of context variables.
    // R13: size and bit tags.
    uword tags = target::MakeTagWordForNewSpaceObject(kContextCid, 0);
    __ orq(R13, Immediate(tags));
    __ movq(FieldAddress(RAX, target::Object::tags_offset()), R13);  // Tags.
  }

  // Setup up number of context variables field.
  // RAX: new object.
  // R10: number of context variables as integer value (not object).
  __ movq(FieldAddress(RAX, target::Context::num_variables_offset()), R10);
}

// Called for inline allocation of contexts.
// Input:
//   R10: number of context variables.
// Output:
//   RAX: new allocated RawContext object.
// Clobbered:
//   R9, R13
void StubCodeCompiler::GenerateAllocateContextStub(Assembler* assembler) {
  __ LoadObject(R9, NullObject());
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    GenerateAllocateContextSpaceStub(assembler, &slow_case);

    // Setup the parent field.
    // RAX: new object.
    // R9: Parent object, initialised to null.
    // No generational barrier needed, since we are storing null.
    __ StoreIntoObjectNoBarrier(
        RAX, FieldAddress(RAX, target::Context::parent_offset()), R9);

    // Initialize the context variables.
    // RAX: new object.
    // R10: number of context variables.
    {
      Label loop, entry;
      __ leaq(R13, FieldAddress(RAX, target::Context::variable_offset(0)));
#if defined(DEBUG)
      static auto const kJumpLength = Assembler::kFarJump;
#else
      static auto const kJumpLength = Assembler::kNearJump;
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
  // Write-barrier elimination might be enabled for this context (depending on
  // the size). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(assembler, /*preserve_registers=*/false);

  // RAX: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();

  __ ret();
}

// Called for inline clone of contexts.
// Input:
//   R9: context to clone.
// Output:
//   RAX: new allocated RawContext object.
// Clobbered:
//   R10, R13
void StubCodeCompiler::GenerateCloneContextStub(Assembler* assembler) {
  {
    Label slow_case;

    // Load num. variable (int32_t) in the existing context.
    __ movsxd(R10, FieldAddress(R9, target::Context::num_variables_offset()));

    // Allocate new context of same size.
    GenerateAllocateContextSpaceStub(assembler, &slow_case);

    // Load parent in the existing context.
    __ movq(R13, FieldAddress(R9, target::Context::parent_offset()));
    // Setup the parent field.
    // RAX: new object.
    // R9: Old parent object.
    __ StoreIntoObjectNoBarrier(
        RAX, FieldAddress(RAX, target::Context::parent_offset()), R13);

    // Clone the context variables.
    // RAX: new context clone.
    // R10: number of context variables.
    {
      Label loop, entry;
      __ jmp(&entry, Assembler::kNearJump);
      __ Bind(&loop);
      __ decq(R10);
      __ movq(R13, FieldAddress(R9, R10, TIMES_8,
                                target::Context::variable_offset(0)));
      __ StoreIntoObjectNoBarrier(
          RAX,
          FieldAddress(RAX, R10, TIMES_8, target::Context::variable_offset(0)),
          R13);
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

  __ PushObject(NullObject());  // Make space on stack for the return value.
  __ pushq(R9);                 // Push context.
  __ CallRuntime(kCloneContextRuntimeEntry, 1);  // Clone context.
  __ popq(RAX);                                  // Pop context argument.
  __ popq(RAX);                                  // Pop the new context object.

  // Write-barrier elimination might be enabled for this context (depending on
  // the size). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(assembler, /*preserve_registers=*/false);

  // RAX: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();

  __ ret();
}

void StubCodeCompiler::GenerateWriteBarrierWrappersStub(Assembler* assembler) {
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if ((kDartAvailableCpuRegs & (1 << i)) == 0) continue;

    Register reg = static_cast<Register>(i);
    intptr_t start = __ CodeSize();
    __ pushq(kWriteBarrierObjectReg);
    __ movq(kWriteBarrierObjectReg, reg);
    __ call(Address(THR, target::Thread::write_barrier_entry_point_offset()));
    __ popq(kWriteBarrierObjectReg);
    __ ret();
    intptr_t end = __ CodeSize();

    RELEASE_ASSERT(end - start == kStoreBufferWrapperSize);
  }
}

// Helper stub to implement Assembler::StoreIntoObject/Array.
// Input parameters:
//   RDX: Object (old)
//   RAX: Value (old or new)
//   R13: Slot
// If RAX is new, add RDX to the store buffer. Otherwise RAX is old, mark RAX
// and add it to the mark list.
COMPILE_ASSERT(kWriteBarrierObjectReg == RDX);
COMPILE_ASSERT(kWriteBarrierValueReg == RAX);
COMPILE_ASSERT(kWriteBarrierSlotReg == R13);
static void GenerateWriteBarrierStubHelper(Assembler* assembler,
                                           Address stub_code,
                                           bool cards) {
  Label add_to_mark_stack, remember_card;
  __ testq(RAX, Immediate(1 << target::ObjectAlignment::kNewObjectBitPosition));
  __ j(ZERO, &add_to_mark_stack);

  if (cards) {
    __ movl(TMP, FieldAddress(RDX, target::Object::tags_offset()));
    __ testl(TMP, Immediate(1 << target::ObjectLayout::kCardRememberedBit));
    __ j(NOT_ZERO, &remember_card, Assembler::kFarJump);
  } else {
#if defined(DEBUG)
    Label ok;
    __ movl(TMP, FieldAddress(RDX, target::Object::tags_offset()));
    __ testl(TMP, Immediate(1 << target::ObjectLayout::kCardRememberedBit));
    __ j(ZERO, &ok, Assembler::kFarJump);
    __ Stop("Wrong barrier");
    __ Bind(&ok);
#endif
  }

  // Update the tags that this object has been remembered.
  // RDX: Address being stored
  // RAX: Current tag value
  // lock+andq is an atomic read-modify-write.
  __ lock();
  __ andq(FieldAddress(RDX, target::Object::tags_offset()),
          Immediate(~(1 << target::ObjectLayout::kOldAndNotRememberedBit)));

  // Save registers being destroyed.
  __ pushq(RAX);
  __ pushq(RCX);

  // Load the StoreBuffer block out of the thread. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  // RDX: Address being stored
  __ movq(RAX, Address(THR, target::Thread::store_buffer_block_offset()));
  __ movl(RCX, Address(RAX, target::StoreBufferBlock::top_offset()));
  __ movq(
      Address(RAX, RCX, TIMES_8, target::StoreBufferBlock::pointers_offset()),
      RDX);

  // Increment top_ and check for overflow.
  // RCX: top_
  // RAX: StoreBufferBlock
  Label overflow;
  __ incq(RCX);
  __ movl(Address(RAX, target::StoreBufferBlock::top_offset()), RCX);
  __ cmpl(RCX, Immediate(target::StoreBufferBlock::kSize));
  // Restore values.
  __ popq(RCX);
  __ popq(RAX);
  __ j(EQUAL, &overflow, Assembler::kNearJump);
  __ ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&overflow);
  // Setup frame, push callee-saved registers.
  __ pushq(CODE_REG);
  __ movq(CODE_REG, stub_code);
  __ EnterCallRuntimeFrame(0);
  __ movq(CallingConventions::kArg1Reg, THR);
  __ CallRuntime(kStoreBufferBlockProcessRuntimeEntry, 1);
  __ LeaveCallRuntimeFrame();
  __ popq(CODE_REG);
  __ ret();

  __ Bind(&add_to_mark_stack);
  __ pushq(RAX);      // Spill.
  __ pushq(RCX);      // Spill.
  __ movq(TMP, RAX);  // RAX is fixed implicit operand of CAS.

  // Atomically clear kOldAndNotMarkedBit.
  Label retry, lost_race, marking_overflow;
  __ movq(RAX, FieldAddress(TMP, target::Object::tags_offset()));
  __ Bind(&retry);
  __ movq(RCX, RAX);
  __ testq(RCX, Immediate(1 << target::ObjectLayout::kOldAndNotMarkedBit));
  __ j(ZERO, &lost_race);  // Marked by another thread.
  __ andq(RCX, Immediate(~(1 << target::ObjectLayout::kOldAndNotMarkedBit)));
  __ LockCmpxchgq(FieldAddress(TMP, target::Object::tags_offset()), RCX);
  __ j(NOT_EQUAL, &retry, Assembler::kNearJump);

  __ movq(RAX, Address(THR, target::Thread::marking_stack_block_offset()));
  __ movl(RCX, Address(RAX, target::MarkingStackBlock::top_offset()));
  __ movq(
      Address(RAX, RCX, TIMES_8, target::MarkingStackBlock::pointers_offset()),
      TMP);
  __ incq(RCX);
  __ movl(Address(RAX, target::MarkingStackBlock::top_offset()), RCX);
  __ cmpl(RCX, Immediate(target::MarkingStackBlock::kSize));
  __ popq(RCX);  // Unspill.
  __ popq(RAX);  // Unspill.
  __ j(EQUAL, &marking_overflow, Assembler::kNearJump);
  __ ret();

  __ Bind(&marking_overflow);
  __ pushq(CODE_REG);
  __ movq(CODE_REG, stub_code);
  __ EnterCallRuntimeFrame(0);
  __ movq(CallingConventions::kArg1Reg, THR);
  __ CallRuntime(kMarkingStackBlockProcessRuntimeEntry, 1);
  __ LeaveCallRuntimeFrame();
  __ popq(CODE_REG);
  __ ret();

  __ Bind(&lost_race);
  __ popq(RCX);  // Unspill.
  __ popq(RAX);  // Unspill.
  __ ret();

  if (cards) {
    Label remember_card_slow;

    // Get card table.
    __ Bind(&remember_card);
    __ movq(TMP, RDX);                              // Object.
    __ andq(TMP, Immediate(target::kOldPageMask));  // OldPage.
    __ cmpq(Address(TMP, target::OldPage::card_table_offset()), Immediate(0));
    __ j(EQUAL, &remember_card_slow, Assembler::kNearJump);

    // Dirty the card.
    __ subq(R13, TMP);  // Offset in page.
    __ movq(TMP,
            Address(TMP, target::OldPage::card_table_offset()));  // Card table.
    __ shrq(
        R13,
        Immediate(target::OldPage::kBytesPerCardLog2));  // Index in card table.
    __ movb(Address(TMP, R13, TIMES_1, 0), Immediate(1));
    __ ret();

    // Card table not yet allocated.
    __ Bind(&remember_card_slow);
    __ pushq(CODE_REG);
    __ movq(CODE_REG, stub_code);
    __ EnterCallRuntimeFrame(0);
    __ movq(CallingConventions::kArg1Reg, RDX);
    __ movq(CallingConventions::kArg2Reg, R13);
    __ CallRuntime(kRememberCardRuntimeEntry, 2);
    __ LeaveCallRuntimeFrame();
    __ popq(CODE_REG);
    __ ret();
  }
}

void StubCodeCompiler::GenerateWriteBarrierStub(Assembler* assembler) {
  GenerateWriteBarrierStubHelper(
      assembler, Address(THR, target::Thread::write_barrier_code_offset()),
      false);
}

void StubCodeCompiler::GenerateArrayWriteBarrierStub(Assembler* assembler) {
  GenerateWriteBarrierStubHelper(
      assembler,
      Address(THR, target::Thread::array_write_barrier_code_offset()), true);
}

static void GenerateAllocateObjectHelper(Assembler* assembler,
                                         bool is_cls_parameterized) {
  // Note: Keep in sync with calling function.
  // kAllocationStubTypeArgumentsReg = RDX
  const Register kTagsReg = R8;

  {
    Label slow_case;
    const Register kNewTopReg = R9;

    // Allocate the object and update top to point to
    // next object start and initialize the allocated object.
    {
      const Register kInstanceSizeReg = RSI;

      __ ExtractInstanceSizeFromTags(kInstanceSizeReg, kTagsReg);

      __ movq(RAX, Address(THR, target::Thread::top_offset()));
      __ leaq(kNewTopReg, Address(RAX, kInstanceSizeReg, TIMES_1, 0));
      // Check if the allocation fits into the remaining space.
      __ cmpq(kNewTopReg, Address(THR, target::Thread::end_offset()));
      __ j(ABOVE_EQUAL, &slow_case);

      __ movq(Address(THR, target::Thread::top_offset()), kNewTopReg);
    }  // kInstanceSizeReg = RSI

    // Set the tags.
    // 64 bit store also zeros the identity hash field.
    __ movq(Address(RAX, target::Object::tags_offset()), kTagsReg);

    __ addq(RAX, Immediate(kHeapObjectTag));

    // Initialize the remaining words of the object.
    {
      const Register kNextFieldReg = RDI;
      __ leaq(kNextFieldReg,
              FieldAddress(RAX, target::Instance::first_field_offset()));

      const Register kNullReg = R10;
      __ LoadObject(kNullReg, NullObject());

      // Loop until the whole object is initialized.
      Label init_loop;
      Label done;
      __ Bind(&init_loop);
      __ cmpq(kNextFieldReg, kNewTopReg);
#if defined(DEBUG)
      static auto const kJumpLength = Assembler::kFarJump;
#else
      static auto const kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
      __ j(ABOVE_EQUAL, &done, kJumpLength);
      __ StoreIntoObjectNoBarrier(RAX, Address(kNextFieldReg, 0), kNullReg);
      __ addq(kNextFieldReg, Immediate(target::kWordSize));
      __ jmp(&init_loop, Assembler::kNearJump);
      __ Bind(&done);
    }  // kNextFieldReg = RDI, kNullReg = R10

    if (is_cls_parameterized) {
      Label not_parameterized_case;

      const Register kClsIdReg = R9;
      const Register kTypeOffsetReg = RDI;

      __ ExtractClassIdFromTags(kClsIdReg, kTagsReg);

      // Load class' type_arguments_field offset in words.
      __ LoadClassById(kTypeOffsetReg, kClsIdReg);
      __ movl(
          kTypeOffsetReg,
          FieldAddress(kTypeOffsetReg,
                       target::Class::
                           host_type_arguments_field_offset_in_words_offset()));

      // Set the type arguments in the new object.
      __ StoreIntoObject(RAX, FieldAddress(RAX, kTypeOffsetReg, TIMES_8, 0),
                         kAllocationStubTypeArgumentsReg);

      __ Bind(&not_parameterized_case);
    }  // kTypeOffsetReg = RDI;

    __ ret();

    __ Bind(&slow_case);
  }  // kNewTopReg = R9;

  // Fall back on slow case:
  if (!is_cls_parameterized) {
    __ LoadObject(kAllocationStubTypeArgumentsReg, NullObject());
  }
  // Tail call to generic allocation stub.
  __ jmp(
      Address(THR, target::Thread::allocate_object_slow_entry_point_offset()));
}

// Called for inline allocation of objects (any class).
void StubCodeCompiler::GenerateAllocateObjectStub(Assembler* assembler) {
  GenerateAllocateObjectHelper(assembler, /*is_cls_parameterized=*/false);
}

void StubCodeCompiler::GenerateAllocateObjectParameterizedStub(
    Assembler* assembler) {
  GenerateAllocateObjectHelper(assembler, /*is_cls_parameterized=*/true);
}

void StubCodeCompiler::GenerateAllocateObjectSlowStub(Assembler* assembler) {
  // Note: Keep in sync with calling stub.
  // kAllocationStubTypeArgumentsReg = RDX
  const Register kTagsToClsIdReg = R8;

  if (!FLAG_use_bare_instructions) {
    __ movq(CODE_REG,
            Address(THR, target::Thread::call_to_runtime_stub_offset()));
  }

  __ ExtractClassIdFromTags(kTagsToClsIdReg, kTagsToClsIdReg);

  // Create a stub frame.
  // Ensure constant pool is allowed so we can e.g. load class object.
  __ EnterStubFrame();

  // Setup space on stack for return value.
  __ LoadObject(RAX, NullObject());
  __ pushq(RAX);

  // Push class of object to be allocated.
  __ LoadClassById(RAX, kTagsToClsIdReg);
  __ pushq(RAX);

  // Must be Object::null() if non-parameterized class.
  __ pushq(kAllocationStubTypeArgumentsReg);

  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);

  __ popq(RAX);  // Pop argument (type arguments of object).
  __ popq(RAX);  // Pop argument (class of object).
  __ popq(RAX);  // Pop result (newly allocated object).

  // Write-barrier elimination is enabled for [cls] and we therefore need to
  // ensure that the object is in new-space or has remembered bit set.
  EnsureIsNewOrRemembered(assembler, /*preserve_registers=*/false);

  // RAX: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();

  __ ret();
}

// Called for inline allocation of objects.
void StubCodeCompiler::GenerateAllocationStubForClass(
    Assembler* assembler,
    UnresolvedPcRelativeCalls* unresolved_calls,
    const Class& cls,
    const Code& allocate_object,
    const Code& allocat_object_parametrized) {
  static_assert(kAllocationStubTypeArgumentsReg == RDX,
                "Adjust register allocation in the AllocationStub");

  classid_t cls_id = target::Class::GetId(cls);
  ASSERT(cls_id != kIllegalCid);

  RELEASE_ASSERT(AllocateObjectInstr::WillAllocateNewOrRemembered(cls));

  const intptr_t cls_type_arg_field_offset =
      target::Class::TypeArgumentsFieldOffset(cls);

  // The generated code is different if the class is parameterized.
  const bool is_cls_parameterized = target::Class::NumTypeArguments(cls) > 0;
  ASSERT(!is_cls_parameterized ||
         cls_type_arg_field_offset != target::Class::kNoTypeArguments);

  const intptr_t instance_size = target::Class::GetInstanceSize(cls);
  ASSERT(instance_size > 0);
  // User-defined classes should always be allocatable in new space.
  RELEASE_ASSERT(target::Heap::IsAllocatableInNewSpace(instance_size));

  const uword tags =
      target::MakeTagWordForNewSpaceObject(cls_id, instance_size);

  // Note: Keep in sync with helper function.
  // kAllocationStubTypeArgumentsReg = RDX
  const Register kTagsReg = R8;

  __ movq(kTagsReg, Immediate(tags));

  // Load the appropriate generic alloc. stub.
  if (!FLAG_use_slow_path && FLAG_inline_alloc &&
      !target::Class::TraceAllocation(cls) &&
      target::SizeFitsInSizeTag(instance_size)) {
    if (is_cls_parameterized) {
      // TODO(41974): Assign all allocation stubs to the root loading unit?
      if (false &&
          !IsSameObject(NullObject(),
                        CastHandle<Object>(allocat_object_parametrized))) {
        __ GenerateUnRelocatedPcRelativeTailCall();
        unresolved_calls->Add(new UnresolvedPcRelativeCall(
            __ CodeSize(), allocat_object_parametrized, /*is_tail_call=*/true));
      } else {
        __ jmp(Address(THR,
                       target::Thread::
                           allocate_object_parameterized_entry_point_offset()));
      }
    } else {
      // TODO(41974): Assign all allocation stubs to the root loading unit?
      if (false &&
          !IsSameObject(NullObject(), CastHandle<Object>(allocate_object))) {
        __ GenerateUnRelocatedPcRelativeTailCall();
        unresolved_calls->Add(new UnresolvedPcRelativeCall(
            __ CodeSize(), allocate_object, /*is_tail_call=*/true));
      } else {
        __ jmp(
            Address(THR, target::Thread::allocate_object_entry_point_offset()));
      }
    }
  } else {
    if (!is_cls_parameterized) {
      __ LoadObject(kAllocationStubTypeArgumentsReg, NullObject());
    }
    __ jmp(Address(THR,
                   target::Thread::allocate_object_slow_entry_point_offset()));
  }
}

// Called for invoking "dynamic noSuchMethod(Invocation invocation)" function
// from the entry code of a dart function after an error in passed argument
// name or number is detected.
// Input parameters:
//   RSP : points to return address.
//   RSP + 8 : address of last argument.
//   R10 : arguments descriptor array.
void StubCodeCompiler::GenerateCallClosureNoSuchMethodStub(
    Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ movq(R13, FieldAddress(R10, target::ArgumentsDescriptor::size_offset()));
  __ movq(RAX,
          Address(RBP, R13, TIMES_4,
                  target::frame_layout.param_end_from_fp * target::kWordSize));

  // Load the function.
  __ movq(RBX, FieldAddress(RAX, target::Closure::function_offset()));

  __ pushq(Immediate(0));  // Result slot.
  __ pushq(RAX);           // Receiver.
  __ pushq(RBX);           // Function.
  __ pushq(R10);           // Arguments descriptor array.

  // Adjust arguments count.
  __ cmpq(
      FieldAddress(R10, target::ArgumentsDescriptor::type_args_len_offset()),
      Immediate(0));
  __ movq(R10, R13);
  Label args_count_ok;
  __ j(EQUAL, &args_count_ok, Assembler::kNearJump);
  __ addq(R10, Immediate(target::ToRawSmi(1)));  // Include the type arguments.
  __ Bind(&args_count_ok);

  // R10: Smi-tagged arguments array length.
  PushArrayOfArguments(assembler);

  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromPrologueRuntimeEntry, kNumArgs);
  // noSuchMethod on closures always throws an error, so it will never return.
  __ int3();
}

// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCodeCompiler::GenerateOptimizedUsageCounterIncrement(
    Assembler* assembler) {
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }
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
  __ incl(FieldAddress(func_reg, target::Function::usage_counter_offset()));
}

// Loads function into 'temp_reg', preserves 'ic_reg'.
void StubCodeCompiler::GenerateUsageCounterIncrement(Assembler* assembler,
                                                     Register temp_reg) {
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }
  if (FLAG_optimization_counter_threshold >= 0) {
    Register ic_reg = RBX;
    Register func_reg = temp_reg;
    ASSERT(ic_reg != func_reg);
    __ Comment("Increment function counter");
    __ movq(func_reg, FieldAddress(ic_reg, target::ICData::owner_offset()));
    __ incl(FieldAddress(func_reg, target::Function::usage_counter_offset()));
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
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // Left.
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));  // Right
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
    case Token::kLT: {
      __ cmpq(RAX, RCX);
      __ setcc(GREATER_EQUAL, ByteRegisterOf(RAX));
      __ movzxb(RAX, RAX);  // RAX := RAX < RCX ? 0 : 1
      __ movq(RAX,
              Address(THR, RAX, TIMES_8, target::Thread::bool_true_offset()));
      ASSERT(target::Thread::bool_true_offset() + 8 ==
             target::Thread::bool_false_offset());
      break;
    }
    case Token::kEQ: {
      __ cmpq(RAX, RCX);
      __ setcc(NOT_EQUAL, ByteRegisterOf(RAX));
      __ movzxb(RAX, RAX);  // RAX := RAX == RCX ? 0 : 1
      __ movq(RAX,
              Address(THR, RAX, TIMES_8, target::Thread::bool_true_offset()));
      ASSERT(target::Thread::bool_true_offset() + 8 ==
             target::Thread::bool_false_offset());
      break;
    }
    default:
      UNIMPLEMENTED();
  }

  // RBX: IC data object (preserved).
  __ movq(R13, FieldAddress(RBX, target::ICData::entries_offset()));
  // R13: ic_data_array with check entries: classes and target functions.
  __ leaq(R13, FieldAddress(R13, target::Array::data_offset()));
// R13: points directly to the first ic data array element.
#if defined(DEBUG)
  // Check that first entry is for Smi/Smi.
  Label error, ok;
  const Immediate& imm_smi_cid = Immediate(target::ToRawSmi(kSmiCid));
  __ cmpq(Address(R13, 0 * target::kWordSize), imm_smi_cid);
  __ j(NOT_EQUAL, &error, Assembler::kNearJump);
  __ cmpq(Address(R13, 1 * target::kWordSize), imm_smi_cid);
  __ j(EQUAL, &ok, Assembler::kNearJump);
  __ Bind(&error);
  __ Stop("Incorrect IC data");
  __ Bind(&ok);
#endif

  if (FLAG_optimization_counter_threshold >= 0) {
    const intptr_t count_offset =
        target::ICData::CountIndexFor(num_args) * target::kWordSize;
    // Update counter, ignore overflow.
    __ addq(Address(R13, count_offset), Immediate(target::ToRawSmi(1)));
  }

  __ ret();
}

// Saves the offset of the target entry-point (from the Function) into R8.
//
// Must be the first code generated, since any code before will be skipped in
// the unchecked entry-point.
static void GenerateRecordEntryPoint(Assembler* assembler) {
  Label done;
  __ movq(R8,
          Immediate(target::Function::entry_point_offset() - kHeapObjectTag));
  __ jmp(&done);
  __ BindUncheckedEntryPoint();
  __ movq(R8, Immediate(target::Function::entry_point_offset(
                            CodeEntryKind::kUnchecked) -
                        kHeapObjectTag));
  __ Bind(&done);
}

// Generate inline cache check for 'num_args'.
//  RDX: receiver (if instance call)
//  RBX: ICData
//  RSP[0]: return address
// Control flow:
// - If receiver is null -> jump to IC miss.
// - If receiver is Smi -> load Smi class.
// - If receiver is not-Smi -> load receiver's class.
// - Check if 'num_args' (including receiver) match any IC data group.
// - Match found -> jump to target.
// - Match not found -> jump to IC miss.
void StubCodeCompiler::GenerateNArgsCheckInlineCacheStub(
    Assembler* assembler,
    intptr_t num_args,
    const RuntimeEntry& handle_ic_miss,
    Token::Kind kind,
    Optimized optimized,
    CallType type,
    Exactness exactness) {
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }

  const bool save_entry_point = kind == Token::kILLEGAL;
  if (save_entry_point) {
    GenerateRecordEntryPoint(assembler);
  }

  if (optimized == kOptimized) {
    GenerateOptimizedUsageCounterIncrement(assembler);
  } else {
    GenerateUsageCounterIncrement(assembler, /* scratch */ RCX);
  }

  ASSERT(num_args == 1 || num_args == 2);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ movl(RCX, FieldAddress(RBX, target::ICData::state_bits_offset()));
    ASSERT(target::ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andq(RCX, Immediate(target::ICData::NumArgsTestedMask()));
    __ cmpq(RCX, Immediate(num_args));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

#if !defined(PRODUCT)
  Label stepping, done_stepping;
  if (optimized == kUnoptimized) {
    __ Comment("Check single stepping");
    __ LoadIsolate(RAX);
    __ cmpb(Address(RAX, target::Isolate::single_step_offset()), Immediate(0));
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
  // RBX: IC data object (preserved).
  __ movq(R13, FieldAddress(RBX, target::ICData::entries_offset()));
  // R13: ic_data_array with check entries: classes and target functions.
  __ leaq(R13, FieldAddress(R13, target::Array::data_offset()));
  // R13: points directly to the first ic data array element.

  if (type == kInstanceCall) {
    __ LoadTaggedClassIdMayBeSmi(RAX, RDX);
    __ movq(R10, FieldAddress(
                     RBX, target::CallSiteData::arguments_descriptor_offset()));
    if (num_args == 2) {
      __ movq(RCX,
              FieldAddress(R10, target::ArgumentsDescriptor::count_offset()));
      __ movq(R9, Address(RSP, RCX, TIMES_4, -target::kWordSize));
      __ LoadTaggedClassIdMayBeSmi(RCX, R9);
    }
  } else {
    __ movq(R10, FieldAddress(
                     RBX, target::CallSiteData::arguments_descriptor_offset()));
    __ movq(RCX,
            FieldAddress(R10, target::ArgumentsDescriptor::count_offset()));
    __ movq(RDX, Address(RSP, RCX, TIMES_4, 0));
    __ LoadTaggedClassIdMayBeSmi(RAX, RDX);
    if (num_args == 2) {
      __ movq(R9, Address(RSP, RCX, TIMES_4, -target::kWordSize));
      __ LoadTaggedClassIdMayBeSmi(RCX, R9);
    }
  }
  // RAX: first argument class ID as Smi.
  // RCX: second argument class ID as Smi.
  // R10: args descriptor

  // Loop that checks if there is an IC data match.
  Label loop, found, miss;
  __ Comment("ICData loop");

  // We unroll the generic one that is generated once more than the others.
  const bool optimize = kind == Token::kILLEGAL;
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(num_args) * target::kWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(num_args) * target::kWordSize;
  const intptr_t exactness_offset =
      target::ICData::ExactnessIndexFor(num_args) * target::kWordSize;

  __ Bind(&loop);
  for (int unroll = optimize ? 4 : 2; unroll >= 0; unroll--) {
    Label update;
    __ movq(R9, Address(R13, 0));
    __ cmpq(RAX, R9);  // Class id match?
    if (num_args == 2) {
      __ j(NOT_EQUAL, &update);  // Continue.
      __ movq(R9, Address(R13, target::kWordSize));
      // R9: next class ID to check (smi).
      __ cmpq(RCX, R9);  // Class id match?
    }
    __ j(EQUAL, &found);  // Break.

    __ Bind(&update);

    const intptr_t entry_size = target::ICData::TestEntryLengthFor(
                                    num_args, exactness == kCheckExactness) *
                                target::kWordSize;
    __ addq(R13, Immediate(entry_size));  // Next entry.

    __ cmpq(R9, Immediate(target::ToRawSmi(kIllegalCid)));  // Done?
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
  __ movq(RAX, FieldAddress(R10, target::ArgumentsDescriptor::count_offset()));
  __ leaq(RAX, Address(RSP, RAX, TIMES_4, 0));  // RAX is Smi.
  __ EnterStubFrame();
  if (save_entry_point) {
    __ SmiTag(R8);  // Entry-point offset is not Smi.
    __ pushq(R8);   // Preserve entry point.
  }
  __ pushq(R10);           // Preserve arguments descriptor array.
  __ pushq(RBX);           // Preserve IC data object.
  __ pushq(Immediate(0));  // Result slot.
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ movq(RCX, Address(RAX, -target::kWordSize * i));
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
  if (save_entry_point) {
    __ popq(R8);      // Restore entry point.
    __ SmiUntag(R8);  // Entry-point offset is not Smi.
  }
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
  Label call_target_function_through_unchecked_entry;
  if (exactness == kCheckExactness) {
    Label exactness_ok;
    ASSERT(num_args == 1);
    __ movq(RAX, Address(R13, exactness_offset));
    __ cmpq(RAX, Immediate(target::ToRawSmi(
                     StaticTypeExactnessState::HasExactSuperType().Encode())));
    __ j(LESS, &exactness_ok);
    __ j(EQUAL, &call_target_function_through_unchecked_entry);

    // Check trivial exactness.
    // Note: ICDataLayout::receivers_static_type_ is guaranteed to be not null
    // because we only emit calls to this stub when it is not null.
    __ movq(RCX,
            FieldAddress(RBX, target::ICData::receivers_static_type_offset()));
    __ movq(RCX, FieldAddress(RCX, target::Type::arguments_offset()));
    // RAX contains an offset to type arguments in words as a smi,
    // hence TIMES_4. RDX is guaranteed to be non-smi because it is expected
    // to have type arguments.
    __ cmpq(RCX, FieldAddress(RDX, RAX, TIMES_4, 0));
    __ j(EQUAL, &call_target_function_through_unchecked_entry);

    // Update exactness state (not-exact anymore).
    __ movq(Address(R13, exactness_offset),
            Immediate(target::ToRawSmi(
                StaticTypeExactnessState::NotExact().Encode())));
    __ Bind(&exactness_ok);
  }
  __ movq(RAX, Address(R13, target_offset));

  if (FLAG_optimization_counter_threshold >= 0) {
    __ Comment("Update ICData counter");
    // Ignore overflow.
    __ addq(Address(R13, count_offset), Immediate(target::ToRawSmi(1)));
  }

  __ Comment("Call target (via specified entry point)");
  __ Bind(&call_target_function);
  // RAX: Target function.
  __ movq(CODE_REG, FieldAddress(RAX, target::Function::code_offset()));
  if (save_entry_point) {
    __ addq(R8, RAX);
    __ jmp(Address(R8, 0));
  } else {
    __ jmp(FieldAddress(RAX, target::Function::entry_point_offset()));
  }

  if (exactness == kCheckExactness) {
    __ Bind(&call_target_function_through_unchecked_entry);
    if (FLAG_optimization_counter_threshold >= 0) {
      __ Comment("Update ICData counter");
      // Ignore overflow.
      __ addq(Address(R13, count_offset), Immediate(target::ToRawSmi(1)));
    }
    __ Comment("Call target (via unchecked entry point)");
    __ movq(RAX, Address(R13, target_offset));
    __ movq(CODE_REG, FieldAddress(RAX, target::Function::code_offset()));
    __ jmp(FieldAddress(
        RAX, target::Function::entry_point_offset(CodeEntryKind::kUnchecked)));
  }

#if !defined(PRODUCT)
  if (optimized == kUnoptimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    if (type == kInstanceCall) {
      __ pushq(RDX);  // Preserve receiver.
    }
    __ pushq(RBX);  // Preserve ICData.
    if (save_entry_point) {
      __ SmiTag(R8);  // Entry-point offset is not Smi.
      __ pushq(R8);   // Preserve entry point.
    }
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    if (save_entry_point) {
      __ popq(R8);  // Restore entry point.
      __ SmiUntag(R8);
    }
    __ popq(RBX);  // Restore ICData.
    if (type == kInstanceCall) {
      __ popq(RDX);  // Restore receiver.
    }
    __ RestoreCodePointer();
    __ LeaveStubFrame();
    __ jmp(&done_stepping);
  }
#endif
}

//  RDX: receiver
//  RBX: ICData
//  RSP[0]: return address
void StubCodeCompiler::GenerateOneArgCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

//  RDX: receiver
//  RBX: ICData
//  RSP[0]: return address
void StubCodeCompiler::GenerateOneArgCheckInlineCacheWithExactnessCheckStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kCheckExactness);
}

//  RDX: receiver
//  RBX: ICData
//  RSP[0]: return address
void StubCodeCompiler::GenerateTwoArgsCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

//  RDX: receiver
//  RBX: ICData
//  RSP[0]: return address
void StubCodeCompiler::GenerateSmiAddInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kADD,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

//  RDX: receiver
//  RBX: ICData
//  RSP[0]: return address
void StubCodeCompiler::GenerateSmiLessInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kLT,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

//  RDX: receiver
//  RBX: ICData
//  RSP[0]: return address
void StubCodeCompiler::GenerateSmiEqualInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

//  RDX: receiver
//  RBX: ICData
//  RDI: Function
//  RSP[0]: return address
void StubCodeCompiler::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kIgnoreExactness);
}

//  RDX: receiver
//  RBX: ICData
//  RDI: Function
//  RSP[0]: return address
void StubCodeCompiler::
    GenerateOneArgOptimizedCheckInlineCacheWithExactnessCheckStub(
        Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kCheckExactness);
}

//  RDX: receiver
//  RBX: ICData
//  RDI: Function
//  RSP[0]: return address
void StubCodeCompiler::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kIgnoreExactness);
}

//  RBX: ICData
//  RSP[0]: return address
void StubCodeCompiler::GenerateZeroArgsUnoptimizedStaticCallStub(
    Assembler* assembler) {
  GenerateRecordEntryPoint(assembler);
  GenerateUsageCounterIncrement(assembler, /* scratch */ RCX);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == 0.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ movl(RCX, FieldAddress(RBX, target::ICData::state_bits_offset()));
    ASSERT(target::ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andq(RCX, Immediate(target::ICData::NumArgsTestedMask()));
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
  __ movzxb(RAX, Address(RAX, target::Isolate::single_step_offset()));
  __ cmpq(RAX, Immediate(0));
#if defined(DEBUG)
  static auto const kJumpLength = Assembler::kFarJump;
#else
  static auto const kJumpLength = Assembler::kNearJump;
#endif  // DEBUG
  __ j(NOT_EQUAL, &stepping, kJumpLength);
  __ Bind(&done_stepping);
#endif

  // RBX: IC data object (preserved).
  __ movq(R12, FieldAddress(RBX, target::ICData::entries_offset()));
  // R12: ic_data_array with entries: target functions and count.
  __ leaq(R12, FieldAddress(R12, target::Array::data_offset()));
  // R12: points directly to the first ic data array element.
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(0) * target::kWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(0) * target::kWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    // Increment count for this call, ignore overflow.
    __ addq(Address(R12, count_offset), Immediate(target::ToRawSmi(1)));
  }

  // Load arguments descriptor into R10.
  __ movq(R10, FieldAddress(
                   RBX, target::CallSiteData::arguments_descriptor_offset()));

  // Get function and call it, if possible.
  __ movq(RAX, Address(R12, target_offset));
  __ movq(CODE_REG, FieldAddress(RAX, target::Function::code_offset()));

  __ addq(R8, RAX);
  __ jmp(Address(R8, 0));

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ pushq(RBX);  // Preserve IC data object.
  __ SmiTag(R8);  // Entry-point is not Smi.
  __ pushq(R8);   // Preserve entry-point.
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ popq(R8);  // Restore entry-point.
  __ SmiUntag(R8);
  __ popq(RBX);
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ jmp(&done_stepping, Assembler::kNearJump);
#endif
}

//  RBX: ICData
//  RSP[0]: return address
void StubCodeCompiler::GenerateOneArgUnoptimizedStaticCallStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kStaticCallMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kStaticCall, kIgnoreExactness);
}

//  RBX: ICData
//  RSP[0]: return address
void StubCodeCompiler::GenerateTwoArgsUnoptimizedStaticCallStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kStaticCall, kIgnoreExactness);
}

// Stub for compiling a function and jumping to the compiled code.
// R10: Arguments descriptor.
// RAX: Function.
void StubCodeCompiler::GenerateLazyCompileStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ pushq(R10);  // Preserve arguments descriptor array.
  __ pushq(RAX);  // Pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ popq(RAX);  // Restore function.
  __ popq(R10);  // Restore arguments descriptor array.
  __ LeaveStubFrame();

  __ movq(CODE_REG, FieldAddress(RAX, target::Function::code_offset()));
  __ movq(RCX, FieldAddress(RAX, target::Function::entry_point_offset()));
  __ jmp(RCX);
}

// RBX: Contains an ICData.
// TOS(0): return address (Dart code).
void StubCodeCompiler::GenerateICCallBreakpointStub(Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ pushq(RDX);           // Preserve receiver.
  __ pushq(RBX);           // Preserve IC data.
  __ pushq(Immediate(0));  // Result slot.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popq(CODE_REG);  // Original stub.
  __ popq(RBX);       // Restore IC data.
  __ popq(RDX);       // Restore receiver.
  __ LeaveStubFrame();

  __ movq(RAX, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ jmp(RAX);  // Jump to original stub.
#endif  // defined(PRODUCT)
}

void StubCodeCompiler::GenerateUnoptStaticCallBreakpointStub(
    Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ pushq(RDX);           // Preserve receiver.
  __ pushq(RBX);           // Preserve IC data.
  __ pushq(Immediate(0));  // Result slot.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popq(CODE_REG);  // Original stub.
  __ popq(RBX);       // Restore IC data.
  __ popq(RDX);       // Restore receiver.
  __ LeaveStubFrame();

  __ movq(RAX, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ jmp(RAX);  // Jump to original stub.
#endif  // defined(PRODUCT)
}

//  TOS(0): return address (Dart code).
void StubCodeCompiler::GenerateRuntimeCallBreakpointStub(Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ pushq(Immediate(0));  // Result slot.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ popq(CODE_REG);  // Original stub.
  __ LeaveStubFrame();

  __ movq(RAX, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ jmp(RAX);  // Jump to original stub.
#endif  // defined(PRODUCT)
}

// Called only from unoptimized code.
void StubCodeCompiler::GenerateDebugStepCheckStub(Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(RAX);
  __ movzxb(RAX, Address(RAX, target::Isolate::single_step_offset()));
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_EQUAL, &stepping, Assembler::kNearJump);
  __ Bind(&done_stepping);
  __ ret();

  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ jmp(&done_stepping, Assembler::kNearJump);
#endif  // defined(PRODUCT)
}

// Used to check class and type arguments. Arguments passed in registers:
//
// Input registers (from TypeTestABI struct):
//   - kSubtypeTestCacheReg: SubtypeTestCacheLayout
//   - kInstanceReg: instance to test against (must be preserved).
//   - kDstTypeReg: destination type (for n>=3).
//   - kInstantiatorTypeArgumentsReg : instantiator type arguments (for n>=5).
//   - kFunctionTypeArgumentsReg : function type arguments (for n>=5).
// Inputs from stack:
//   - TOS + 0: return address.
//
// All input registers are preserved.
//
// Result in SubtypeTestCacheReg::kResultReg: null -> not found, otherwise
// result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  ASSERT(n == 1 || n == 3 || n == 5 || n == 7);

  // Until we have the result, we use the result register to store the null
  // value for quick access. This has the side benefit of initializing the
  // result to null, so it only needs to be changed if found.
  const Register kNullReg = TypeTestABI::kSubtypeTestCacheResultReg;
  __ LoadObject(kNullReg, NullObject());

  const Register kScratchReg = TypeTestABI::kScratchReg;

  // Only used for n >= 7, so set conditionally in that case to catch misuse.
  Register kInstanceParentFunctionTypeArgumentsReg = kNoRegister;
  Register kInstanceDelayedFunctionTypeArgumentsReg = kNoRegister;

  // Free up these 2 registers to be used for 7-value test.
  if (n >= 7) {
    kInstanceParentFunctionTypeArgumentsReg = PP;
    kInstanceDelayedFunctionTypeArgumentsReg = CODE_REG;
    __ pushq(kInstanceParentFunctionTypeArgumentsReg);
    __ pushq(kInstanceDelayedFunctionTypeArgumentsReg);
  }

  // Loop initialization (moved up here to avoid having all dependent loads
  // after each other).

  // We avoid a load-acquire barrier here by relying on the fact that all other
  // loads from the array are data-dependent loads.
  __ movq(STCInternalRegs::kCacheEntryReg,
          FieldAddress(TypeTestABI::kSubtypeTestCacheReg,
                       target::SubtypeTestCache::cache_offset()));
  __ addq(STCInternalRegs::kCacheEntryReg,
          Immediate(target::Array::data_offset() - kHeapObjectTag));

  Label loop, not_closure;
  if (n >= 5) {
    __ LoadClassIdMayBeSmi(STCInternalRegs::kInstanceCidOrFunctionReg,
                           TypeTestABI::kInstanceReg);
  } else {
    __ LoadClassId(STCInternalRegs::kInstanceCidOrFunctionReg,
                   TypeTestABI::kInstanceReg);
  }
  __ cmpq(STCInternalRegs::kInstanceCidOrFunctionReg, Immediate(kClosureCid));
  __ j(NOT_EQUAL, &not_closure, Assembler::kNearJump);

  // Closure handling.
  {
    __ movq(STCInternalRegs::kInstanceCidOrFunctionReg,
            FieldAddress(TypeTestABI::kInstanceReg,
                         target::Closure::function_offset()));
    if (n >= 3) {
      __ movq(
          STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg,
          FieldAddress(TypeTestABI::kInstanceReg,
                       target::Closure::instantiator_type_arguments_offset()));
      if (n >= 7) {
        __ movq(
            kInstanceParentFunctionTypeArgumentsReg,
            FieldAddress(TypeTestABI::kInstanceReg,
                         target::Closure::function_type_arguments_offset()));
        __ movq(kInstanceDelayedFunctionTypeArgumentsReg,
                FieldAddress(TypeTestABI::kInstanceReg,
                             target::Closure::delayed_type_arguments_offset()));
      }
    }
    __ jmp(&loop, Assembler::kNearJump);
  }

  // Non-Closure handling.
  {
    __ Bind(&not_closure);
    if (n >= 3) {
      Label has_no_type_arguments;
      __ LoadClassById(kScratchReg, STCInternalRegs::kInstanceCidOrFunctionReg);
      __ movq(STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg, kNullReg);
      __ movl(
          kScratchReg,
          FieldAddress(kScratchReg,
                       target::Class::
                           host_type_arguments_field_offset_in_words_offset()));
      __ cmpl(kScratchReg, Immediate(target::Class::kNoTypeArguments));
      __ j(EQUAL, &has_no_type_arguments, Assembler::kNearJump);
      __ movq(STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg,
              FieldAddress(TypeTestABI::kInstanceReg, kScratchReg, TIMES_8, 0));
      __ Bind(&has_no_type_arguments);

      if (n >= 7) {
        __ movq(kInstanceParentFunctionTypeArgumentsReg, kNullReg);
        __ movq(kInstanceDelayedFunctionTypeArgumentsReg, kNullReg);
      }
    }
    __ SmiTag(STCInternalRegs::kInstanceCidOrFunctionReg);
  }

  Label found, not_found, next_iteration;

  // Loop header.
  __ Bind(&loop);
  __ movq(kScratchReg,
          Address(STCInternalRegs::kCacheEntryReg,
                  target::kWordSize *
                      target::SubtypeTestCache::kInstanceClassIdOrFunction));
  __ cmpq(kScratchReg, kNullReg);
  __ j(EQUAL, &not_found, Assembler::kNearJump);
  __ cmpq(kScratchReg, STCInternalRegs::kInstanceCidOrFunctionReg);
  if (n == 1) {
    __ j(EQUAL, &found, Assembler::kNearJump);
  } else {
    __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
    __ cmpq(TypeTestABI::kDstTypeReg,
            Address(STCInternalRegs::kCacheEntryReg,
                    target::kWordSize *
                        target::SubtypeTestCache::kDestinationType));
    __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
    __ cmpq(STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg,
            Address(STCInternalRegs::kCacheEntryReg,
                    target::kWordSize *
                        target::SubtypeTestCache::kInstanceTypeArguments));
    if (n == 3) {
      __ j(EQUAL, &found, Assembler::kNearJump);
    } else {
      __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
      __ cmpq(
          TypeTestABI::kInstantiatorTypeArgumentsReg,
          Address(STCInternalRegs::kCacheEntryReg,
                  target::kWordSize *
                      target::SubtypeTestCache::kInstantiatorTypeArguments));
      __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
      __ cmpq(TypeTestABI::kFunctionTypeArgumentsReg,
              Address(STCInternalRegs::kCacheEntryReg,
                      target::kWordSize *
                          target::SubtypeTestCache::kFunctionTypeArguments));

      if (n == 5) {
        __ j(EQUAL, &found, Assembler::kNearJump);
      } else {
        ASSERT(n == 7);
        __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);

        __ cmpq(kInstanceParentFunctionTypeArgumentsReg,
                Address(STCInternalRegs::kCacheEntryReg,
                        target::kWordSize *
                            target::SubtypeTestCache::
                                kInstanceParentFunctionTypeArguments));
        __ j(NOT_EQUAL, &next_iteration, Assembler::kNearJump);
        __ cmpq(kInstanceDelayedFunctionTypeArgumentsReg,
                Address(STCInternalRegs::kCacheEntryReg,
                        target::kWordSize *
                            target::SubtypeTestCache::
                                kInstanceDelayedFunctionTypeArguments));
        __ j(EQUAL, &found, Assembler::kNearJump);
      }
    }
  }

  __ Bind(&next_iteration);
  __ addq(STCInternalRegs::kCacheEntryReg,
          Immediate(target::kWordSize *
                    target::SubtypeTestCache::kTestEntryLength));
  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&found);
  __ movq(TypeTestABI::kSubtypeTestCacheResultReg,
          Address(STCInternalRegs::kCacheEntryReg,
                  target::kWordSize * target::SubtypeTestCache::kTestResult));

  __ Bind(&not_found);
  if (n >= 7) {
    __ popq(kInstanceDelayedFunctionTypeArgumentsReg);
    __ popq(kInstanceParentFunctionTypeArgumentsReg);
  }
  __ ret();
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype3TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 3);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype5TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 5);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype7TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 7);
}

// Return the current stack pointer address, used to stack alignment
// checks.
// TOS + 0: return address
// Result in RAX.
void StubCodeCompiler::GenerateGetCStackPointerStub(Assembler* assembler) {
  __ leaq(RAX, Address(RSP, target::kWordSize));
  __ ret();
}

// Jump to a frame on the call stack.
// TOS + 0: return address
// Arg1: program counter
// Arg2: stack pointer
// Arg3: frame_pointer
// Arg4: thread
// No Result.
void StubCodeCompiler::GenerateJumpToFrameStub(Assembler* assembler) {
  __ movq(THR, CallingConventions::kArg4Reg);
  __ movq(RBP, CallingConventions::kArg3Reg);
  __ movq(RSP, CallingConventions::kArg2Reg);
#if defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif
  Label exit_through_non_ffi;
  // Check if we exited generated from FFI. If so do transition.
  __ cmpq(compiler::Address(
              THR, compiler::target::Thread::exit_through_ffi_offset()),
          compiler::Immediate(target::Thread::exit_through_ffi()));
  __ j(NOT_EQUAL, &exit_through_non_ffi, compiler::Assembler::kNearJump);
  __ TransitionNativeToGenerated(/*leave_safepoint=*/true);
  __ Bind(&exit_through_non_ffi);

  // Set the tag.
  __ movq(Assembler::VMTagAddress(), Immediate(VMTag::kDartTagId));
  // Clear top exit frame.
  __ movq(Address(THR, target::Thread::top_exit_frame_info_offset()),
          Immediate(0));
  // Restore the pool pointer.
  __ RestoreCodePointer();
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ movq(PP, Address(THR, target::Thread::global_object_pool_offset()));
  } else {
    __ LoadPoolPointer(PP);
  }
  __ jmp(CallingConventions::kArg1Reg);  // Jump to program counter.
}

// Run an exception handler.  Execution comes from JumpToFrame stub.
//
// The arguments are stored in the Thread object.
// No result.
void StubCodeCompiler::GenerateRunExceptionHandlerStub(Assembler* assembler) {
  ASSERT(kExceptionObjectReg == RAX);
  ASSERT(kStackTraceObjectReg == RDX);
  __ movq(CallingConventions::kArg1Reg,
          Address(THR, target::Thread::resume_pc_offset()));

  word offset_from_thread = 0;
  bool ok = target::CanLoadFromThread(NullObject(), &offset_from_thread);
  ASSERT(ok);
  __ movq(TMP, Address(THR, offset_from_thread));

  // Load the exception from the current thread.
  Address exception_addr(THR, target::Thread::active_exception_offset());
  __ movq(kExceptionObjectReg, exception_addr);
  __ movq(exception_addr, TMP);

  // Load the stacktrace from the current thread.
  Address stacktrace_addr(THR, target::Thread::active_stacktrace_offset());
  __ movq(kStackTraceObjectReg, stacktrace_addr);
  __ movq(stacktrace_addr, TMP);

  __ jmp(CallingConventions::kArg1Reg);  // Jump to continuation point.
}

// Deoptimize a frame on the call stack before rewinding.
// The arguments are stored in the Thread object.
// No result.
void StubCodeCompiler::GenerateDeoptForRewindStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG.
  __ pushq(Immediate(kZapCodeReg));

  // Push the deopt pc.
  __ pushq(Address(THR, target::Thread::resume_pc_offset()));
#if defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif
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
void StubCodeCompiler::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ movq(CODE_REG, Address(THR, target::Thread::optimize_stub_offset()));
  __ EnterStubFrame();
  __ pushq(R10);           // Preserve args descriptor.
  __ pushq(Immediate(0));  // Result slot.
  __ pushq(RDI);           // Arg0: function to optimize
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ popq(RAX);  // Discard argument.
  __ popq(RAX);  // Get Code object.
  __ popq(R10);  // Restore argument descriptor.
  __ LeaveStubFrame();
  __ movq(CODE_REG, FieldAddress(RAX, target::Function::code_offset()));
  __ movq(RCX, FieldAddress(RAX, target::Function::entry_point_offset()));
  __ jmp(RCX);
  __ int3();
}

// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Left and right are pushed on stack.
// Return ZF set.
// Note: A Mint cannot contain a value that would fit in Smi.
static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right) {
  Label reference_compare, done, check_mint;
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
  __ movq(left, FieldAddress(left, target::Double::value_offset()));
  __ cmpq(left, FieldAddress(right, target::Double::value_offset()));
  __ jmp(&done, Assembler::kFarJump);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid);
  __ j(NOT_EQUAL, &reference_compare, Assembler::kNearJump);
  __ CompareClassId(right, kMintCid);
  __ j(NOT_EQUAL, &done, Assembler::kFarJump);
  __ movq(left, FieldAddress(left, target::Mint::value_offset()));
  __ cmpq(left, FieldAddress(right, target::Mint::value_offset()));
  __ jmp(&done, Assembler::kFarJump);

  __ Bind(&reference_compare);
  __ cmpq(left, right);
  __ Bind(&done);
}

// Called only from unoptimized code. All relevant registers have been saved.
// TOS + 0: return address
// TOS + 1: right argument.
// TOS + 2: left argument.
// Returns ZF set.
void StubCodeCompiler::GenerateUnoptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
#if !defined(PRODUCT)
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(RAX);
  __ movzxb(RAX, Address(RAX, target::Isolate::single_step_offset()));
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_EQUAL, &stepping);
  __ Bind(&done_stepping);
#endif

  const Register left = RAX;
  const Register right = RDX;

  __ movq(left, Address(RSP, 2 * target::kWordSize));
  __ movq(right, Address(RSP, 1 * target::kWordSize));
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
void StubCodeCompiler::GenerateOptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  const Register left = RAX;
  const Register right = RDX;

  __ movq(left, Address(RSP, 2 * target::kWordSize));
  __ movq(right, Address(RSP, 1 * target::kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();
}

// Called from megamorphic calls.
//  RDX: receiver (passed to target)
//  RBX: target::MegamorphicCache (preserved)
// Passed to target:
//  CODE_REG: target Code
//  R10: arguments descriptor
void StubCodeCompiler::GenerateMegamorphicCallStub(Assembler* assembler) {
  // Jump if receiver is a smi.
  Label smi_case;
  __ testq(RDX, Immediate(kSmiTagMask));
  // Jump out of line for smi case.
  __ j(ZERO, &smi_case, Assembler::kNearJump);

  // Loads the cid of the object.
  __ LoadClassId(RAX, RDX);

  Label cid_loaded;
  __ Bind(&cid_loaded);
  __ movq(R9, FieldAddress(RBX, target::MegamorphicCache::mask_offset()));
  __ movq(RDI, FieldAddress(RBX, target::MegamorphicCache::buckets_offset()));
  // R9: mask as a smi.
  // RDI: cache buckets array.

  // Tag cid as a smi.
  __ addq(RAX, RAX);

  // Compute the table index.
  ASSERT(target::MegamorphicCache::kSpreadFactor == 7);
  // Use leaq and subq multiply with 7 == 8 - 1.
  __ leaq(RCX, Address(RAX, TIMES_8, 0));
  __ subq(RCX, RAX);

  Label loop;
  __ Bind(&loop);
  __ andq(RCX, R9);

  const intptr_t base = target::Array::data_offset();
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
  const auto target_address =
      FieldAddress(RDI, RCX, TIMES_8, base + target::kWordSize);
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ movq(R10, FieldAddress(
                     RBX, target::CallSiteData::arguments_descriptor_offset()));
    __ jmp(target_address);
  } else {
    __ movq(RAX, target_address);
    __ movq(R10, FieldAddress(
                     RBX, target::CallSiteData::arguments_descriptor_offset()));
    __ movq(RCX, FieldAddress(RAX, target::Function::entry_point_offset()));
    __ movq(CODE_REG, FieldAddress(RAX, target::Function::code_offset()));
    __ jmp(RCX);
  }

  // Probe failed, check if it is a miss.
  __ Bind(&probe_failed);
  __ cmpq(FieldAddress(RDI, RCX, TIMES_8, base),
          Immediate(target::ToRawSmi(kIllegalCid)));
  Label miss;
  __ j(ZERO, &miss, Assembler::kNearJump);

  // Try next entry in the table.
  __ AddImmediate(RCX, Immediate(target::ToRawSmi(1)));
  __ jmp(&loop);

  // Load cid for the Smi case.
  __ Bind(&smi_case);
  __ movq(RAX, Immediate(kSmiCid));
  __ jmp(&cid_loaded);

  __ Bind(&miss);
  GenerateSwitchableCallMissStub(assembler);
}

// Input:
//  RBX - icdata
//  RDX - receiver object
void StubCodeCompiler::GenerateICCallThroughCodeStub(Assembler* assembler) {
  Label loop, found, miss;
  __ movq(R13, FieldAddress(RBX, target::ICData::entries_offset()));
  __ movq(R10, FieldAddress(
                   RBX, target::CallSiteData::arguments_descriptor_offset()));
  __ leaq(R13, FieldAddress(R13, target::Array::data_offset()));
  // R13: first IC entry
  __ LoadTaggedClassIdMayBeSmi(RAX, RDX);
  // RAX: receiver cid as Smi

  __ Bind(&loop);
  __ movq(R9, Address(R13, 0));
  __ cmpq(RAX, R9);
  __ j(EQUAL, &found, Assembler::kNearJump);

  ASSERT(target::ToRawSmi(kIllegalCid) == 0);
  __ testq(R9, R9);
  __ j(ZERO, &miss, Assembler::kNearJump);

  const intptr_t entry_length =
      target::ICData::TestEntryLengthFor(1, /*tracking_exactness=*/false) *
      target::kWordSize;
  __ addq(R13, Immediate(entry_length));  // Next entry.
  __ jmp(&loop);

  __ Bind(&found);
  const intptr_t code_offset =
      target::ICData::CodeIndexFor(1) * target::kWordSize;
  const intptr_t entry_offset =
      target::ICData::EntryPointIndexFor(1) * target::kWordSize;
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    __ movq(CODE_REG, Address(R13, code_offset));
  }
  __ jmp(Address(R13, entry_offset));

  __ Bind(&miss);
  __ LoadIsolate(RAX);
  __ movq(CODE_REG, Address(RAX, target::Isolate::ic_miss_code_offset()));
  __ movq(RCX, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ jmp(RCX);
}

void StubCodeCompiler::GenerateMonomorphicSmiableCheckStub(
    Assembler* assembler) {
  Label have_cid, miss;

  __ movq(RAX, Immediate(kSmiCid));
  __ movzxw(
      RCX,
      FieldAddress(RBX, target::MonomorphicSmiableCall::expected_cid_offset()));
  __ testq(RDX, Immediate(kSmiTagMask));
  __ j(ZERO, &have_cid, Assembler::kNearJump);
  __ LoadClassId(RAX, RDX);
  __ Bind(&have_cid);
  __ cmpq(RAX, RCX);
  __ j(NOT_EQUAL, &miss, Assembler::kNearJump);
  if (FLAG_use_bare_instructions) {
    __ jmp(
        FieldAddress(RBX, target::MonomorphicSmiableCall::entrypoint_offset()));
  } else {
    __ movq(CODE_REG,
            FieldAddress(RBX, target::MonomorphicSmiableCall::target_offset()));
    __ jmp(FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  }

  __ Bind(&miss);
  __ jmp(Address(THR, target::Thread::switchable_call_miss_entry_offset()));
}

// Called from switchable IC calls.
//  RDX: receiver
void StubCodeCompiler::GenerateSwitchableCallMissStub(Assembler* assembler) {
  __ movq(CODE_REG,
          Address(THR, target::Thread::switchable_call_miss_stub_offset()));
  __ EnterStubFrame();
  __ pushq(RDX);  // Preserve receiver.

  __ pushq(Immediate(0));  // Result slot.
  __ pushq(Immediate(0));  // Arg0: stub out.
  __ pushq(RDX);           // Arg1: Receiver
  __ CallRuntime(kSwitchableCallMissRuntimeEntry, 2);
  __ popq(RBX);
  __ popq(CODE_REG);  // result = stub
  __ popq(RBX);       // result = IC

  __ popq(RDX);  // Restore receiver.
  __ LeaveStubFrame();

  __ movq(RCX, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                          CodeEntryKind::kNormal)));
  __ jmp(RCX);
}

// Called from switchable IC calls.
//  RDX: receiver
//  RBX: SingleTargetCache
// Passed to target::
//  CODE_REG: target Code object
void StubCodeCompiler::GenerateSingleTargetCallStub(Assembler* assembler) {
  Label miss;
  __ LoadClassIdMayBeSmi(RAX, RDX);
  __ movzxw(R9,
            FieldAddress(RBX, target::SingleTargetCache::lower_limit_offset()));
  __ movzxw(R10,
            FieldAddress(RBX, target::SingleTargetCache::upper_limit_offset()));
  __ cmpq(RAX, R9);
  __ j(LESS, &miss, Assembler::kNearJump);
  __ cmpq(RAX, R10);
  __ j(GREATER, &miss, Assembler::kNearJump);
  __ movq(RCX,
          FieldAddress(RBX, target::SingleTargetCache::entry_point_offset()));
  __ movq(CODE_REG,
          FieldAddress(RBX, target::SingleTargetCache::target_offset()));
  __ jmp(RCX);

  __ Bind(&miss);
  __ EnterStubFrame();
  __ pushq(RDX);  // Preserve receiver.

  __ pushq(Immediate(0));  // Result slot.
  __ pushq(Immediate(0));  // Arg0: stub out
  __ pushq(RDX);           // Arg1: Receiver
  __ CallRuntime(kSwitchableCallMissRuntimeEntry, 2);
  __ popq(RBX);
  __ popq(CODE_REG);  // result = stub
  __ popq(RBX);       // result = IC

  __ popq(RDX);  // Restore receiver.
  __ LeaveStubFrame();

  __ movq(RCX, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                          CodeEntryKind::kMonomorphic)));
  __ jmp(RCX);
}

void StubCodeCompiler::GenerateFrameAwaitingMaterializationStub(
    Assembler* assembler) {
  __ int3();
}

void StubCodeCompiler::GenerateAsynchronousGapMarkerStub(Assembler* assembler) {
  __ int3();
}

void StubCodeCompiler::GenerateNotLoadedStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ CallRuntime(kNotLoadedRuntimeEntry, 0);
  __ int3();
}

// Instantiate type arguments from instantiator and function type args.
// RBX: uninstantiated type arguments.
// RDX: instantiator type arguments.
// RCX: function type arguments.
// Returns instantiated type arguments in RAX.
void StubCodeCompiler::GenerateInstantiateTypeArgumentsStub(
    Assembler* assembler) {
  // Lookup cache before calling runtime.
  __ movq(RAX, compiler::FieldAddress(
                   InstantiationABI::kUninstantiatedTypeArgumentsReg,
                   target::TypeArguments::instantiations_offset()));
  __ leaq(RAX, compiler::FieldAddress(RAX, Array::data_offset()));

  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  compiler::Label loop, next, found, call_runtime;
  __ Bind(&loop);

  // Use load-acquire to test for sentinel, if we found non-sentinel it is safe
  // to access the other entries. If we found a sentinel we go to runtime.
  __ LoadAcquire(RDI, RAX,
                 TypeArguments::Instantiation::kInstantiatorTypeArgsIndex *
                     target::kWordSize);
  __ CompareImmediate(RDI, Smi::RawValue(TypeArguments::kNoInstantiator));
  __ j(EQUAL, &call_runtime, compiler::Assembler::kNearJump);

  __ cmpq(RDI, InstantiationABI::kInstantiatorTypeArgumentsReg);
  __ j(NOT_EQUAL, &next, compiler::Assembler::kNearJump);
  __ movq(R10, compiler::Address(
                   RAX, TypeArguments::Instantiation::kFunctionTypeArgsIndex *
                            target::kWordSize));
  __ cmpq(R10, InstantiationABI::kFunctionTypeArgumentsReg);
  __ j(EQUAL, &found, compiler::Assembler::kNearJump);
  __ Bind(&next);
  __ addq(RAX, compiler::Immediate(TypeArguments::Instantiation::kSizeInWords *
                                   target::kWordSize));
  __ jmp(&loop);

  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ Bind(&call_runtime);
  __ EnterStubFrame();
  __ PushObject(Object::null_object());  // Make room for the result.
  __ pushq(InstantiationABI::kUninstantiatedTypeArgumentsReg);
  __ pushq(InstantiationABI::kInstantiatorTypeArgumentsReg);
  __ pushq(InstantiationABI::kFunctionTypeArgumentsReg);
  __ CallRuntime(kInstantiateTypeArgumentsRuntimeEntry, 3);
  __ Drop(3);  // Drop 2 type vectors, and uninstantiated type.
  __ popq(InstantiationABI::kResultTypeArgumentsReg);
  __ LeaveStubFrame();
  __ ret();

  __ Bind(&found);
  __ movq(InstantiationABI::kResultTypeArgumentsReg,
          compiler::Address(
              RAX, TypeArguments::Instantiation::kInstantiatedTypeArgsIndex *
                       target::kWordSize));
  __ ret();
}

void StubCodeCompiler::
    GenerateInstantiateTypeArgumentsMayShareInstantiatorTAStub(
        Assembler* assembler) {
  // Return the instantiator type arguments if its nullability is compatible for
  // sharing, otherwise proceed to instantiation cache lookup.
  compiler::Label cache_lookup;
  __ movq(RAX, compiler::FieldAddress(
                   InstantiationABI::kUninstantiatedTypeArgumentsReg,
                   target::TypeArguments::nullability_offset()));
  __ movq(RDI, compiler::FieldAddress(
                   InstantiationABI::kInstantiatorTypeArgumentsReg,
                   target::TypeArguments::nullability_offset()));
  __ andq(RDI, RAX);
  __ cmpq(RDI, RAX);
  __ j(NOT_EQUAL, &cache_lookup, compiler::Assembler::kNearJump);
  __ movq(InstantiationABI::kResultTypeArgumentsReg,
          InstantiationABI::kInstantiatorTypeArgumentsReg);
  __ ret();

  __ Bind(&cache_lookup);
  GenerateInstantiateTypeArgumentsStub(assembler);
}

void StubCodeCompiler::GenerateInstantiateTypeArgumentsMayShareFunctionTAStub(
    Assembler* assembler) {
  // Return the function type arguments if its nullability is compatible for
  // sharing, otherwise proceed to instantiation cache lookup.
  compiler::Label cache_lookup;
  __ movq(RAX, compiler::FieldAddress(
                   InstantiationABI::kUninstantiatedTypeArgumentsReg,
                   target::TypeArguments::nullability_offset()));
  __ movq(RDI,
          compiler::FieldAddress(InstantiationABI::kFunctionTypeArgumentsReg,
                                 target::TypeArguments::nullability_offset()));
  __ andq(RDI, RAX);
  __ cmpq(RDI, RAX);
  __ j(NOT_EQUAL, &cache_lookup, compiler::Assembler::kNearJump);
  __ movq(InstantiationABI::kResultTypeArgumentsReg,
          InstantiationABI::kFunctionTypeArgumentsReg);
  __ ret();

  __ Bind(&cache_lookup);
  GenerateInstantiateTypeArgumentsStub(assembler);
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

void StubCodeCompiler::GenerateAllocateTypedDataArrayStub(Assembler* assembler,
                                                          intptr_t cid) {
  const intptr_t element_size = TypedDataElementSizeInBytes(cid);
  const intptr_t max_len = TypedDataMaxNewSpaceElements(cid);
  ScaleFactor scale_factor = GetScaleFactor(element_size);

  COMPILE_ASSERT(AllocateTypedDataArrayABI::kLengthReg == RAX);
  COMPILE_ASSERT(AllocateTypedDataArrayABI::kResultReg == RAX);

  // Save length argument for possible runtime call, as
  // RAX is clobbered.
  Label call_runtime;
  __ pushq(AllocateTypedDataArrayABI::kLengthReg);

  NOT_IN_PRODUCT(
      __ MaybeTraceAllocation(cid, &call_runtime, Assembler::kFarJump));
  __ movq(RDI, AllocateTypedDataArrayABI::kLengthReg);
  /* Check that length is a positive Smi. */
  /* RDI: requested array length argument. */
  __ testq(RDI, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &call_runtime);
  __ cmpq(RDI, Immediate(0));
  __ j(LESS, &call_runtime);
  __ SmiUntag(RDI);
  /* Check for maximum allowed length. */
  /* RDI: untagged array length. */
  __ cmpq(RDI, Immediate(max_len));
  __ j(GREATER, &call_runtime);
  /* Special case for scaling by 16. */
  if (scale_factor == TIMES_16) {
    /* double length of array. */
    __ addq(RDI, RDI);
    /* only scale by 8. */
    scale_factor = TIMES_8;
  }
  const intptr_t fixed_size_plus_alignment_padding =
      target::TypedData::InstanceSize() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ leaq(RDI, Address(RDI, scale_factor, fixed_size_plus_alignment_padding));
  __ andq(RDI, Immediate(-target::ObjectAlignment::kObjectAlignment));
  __ movq(RAX, Address(THR, target::Thread::top_offset()));
  __ movq(RCX, RAX);

  /* RDI: allocation size. */
  __ addq(RCX, RDI);
  __ j(CARRY, &call_runtime);

  /* Check if the allocation fits into the remaining space. */
  /* RAX: potential new object start. */
  /* RCX: potential next object start. */
  /* RDI: allocation size. */
  __ cmpq(RCX, Address(THR, target::Thread::end_offset()));
  __ j(ABOVE_EQUAL, &call_runtime);

  /* Successfully allocated the object(s), now update top to point to */
  /* next object start and initialize the object. */
  __ movq(Address(THR, target::Thread::top_offset()), RCX);
  __ addq(RAX, Immediate(kHeapObjectTag));
  /* Initialize the tags. */
  /* RAX: new object start as a tagged pointer. */
  /* RCX: new object end address. */
  /* RDI: allocation size. */
  /* R13: scratch register. */
  {
    Label size_tag_overflow, done;
    __ cmpq(RDI, Immediate(target::ObjectLayout::kSizeTagMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shlq(RDI, Immediate(target::ObjectLayout::kTagBitsSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2));
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&size_tag_overflow);
    __ LoadImmediate(RDI, Immediate(0));
    __ Bind(&done);

    /* Get the class index and insert it into the tags. */
    uword tags = target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
    __ orq(RDI, Immediate(tags));
    __ movq(FieldAddress(RAX, target::Object::tags_offset()), RDI); /* Tags. */
  }
  /* Set the length field. */
  /* RAX: new object start as a tagged pointer. */
  /* RCX: new object end address. */
  __ popq(RDI); /* Array length. */
  __ StoreIntoObjectNoBarrier(
      RAX, FieldAddress(RAX, target::TypedDataBase::length_offset()), RDI);
  /* Initialize all array elements to 0. */
  /* RAX: new object start as a tagged pointer. */
  /* RCX: new object end address. */
  /* RDI: iterator which initially points to the start of the variable */
  /* RBX: scratch register. */
  /* data area to be initialized. */
  __ xorq(RBX, RBX); /* Zero. */
  __ leaq(RDI, FieldAddress(RAX, target::TypedData::InstanceSize()));
  __ StoreInternalPointer(
      RAX, FieldAddress(RAX, target::TypedDataBase::data_field_offset()), RDI);
  Label done, init_loop;
  __ Bind(&init_loop);
  __ cmpq(RDI, RCX);
  __ j(ABOVE_EQUAL, &done, Assembler::kNearJump);
  __ movq(Address(RDI, 0), RBX);
  __ addq(RDI, Immediate(target::kWordSize));
  __ jmp(&init_loop, Assembler::kNearJump);
  __ Bind(&done);

  __ ret();

  __ Bind(&call_runtime);
  __ popq(RDI);  // Array length
  __ EnterStubFrame();
  __ PushObject(Object::null_object());  // Make room for the result.
  __ PushImmediate(Immediate(target::ToRawSmi(cid)));
  __ pushq(RDI);  // Array length
  __ CallRuntime(kAllocateTypedDataRuntimeEntry, 2);
  __ Drop(2);  // Drop arguments.
  __ popq(AllocateTypedDataArrayABI::kResultReg);
  __ LeaveStubFrame();
  __ ret();
}

}  // namespace compiler

}  // namespace dart

#endif  // defined(TARGET_ARCH_X64)
