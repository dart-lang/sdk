// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

// For `AllocateObjectInstr::WillAllocateNewOrRemembered`
// For `GenericCheckBoundInstr::UseUnboxedRepresentation`
#include "vm/compiler/backend/il.h"

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/stub_code_compiler.h"

#if defined(TARGET_ARCH_ARM64)

#include "vm/class_id.h"
#include "vm/code_entry_kind.h"
#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"
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

// Ensures that [R0] is a new object, if not it will be added to the remembered
// set via a leaf runtime call.
//
// WARNING: This might clobber all registers except for [R0], [THR] and [FP].
// The caller should simply call LeaveStubFrame() and return.
static void EnsureIsNewOrRemembered(Assembler* assembler,
                                    bool preserve_registers = true) {
  // If the object is not remembered we call a leaf-runtime to add it to the
  // remembered set.
  Label done;
  __ tbnz(&done, R0, target::ObjectAlignment::kNewObjectBitPosition);

  {
    Assembler::CallRuntimeScope scope(
        assembler, kEnsureRememberedAndMarkingDeferredRuntimeEntry,
        /*frame_size=*/0, /*preserve_registers=*/preserve_registers);
    __ mov(R1, THR);
    scope.Call(/*argument_count=*/2);
  }

  __ Bind(&done);
}

// Input parameters:
//   LR : return address.
//   SP : address of last argument in argument array.
//   SP + 8*R4 - 8 : address of first argument in argument array.
//   SP + 8*R4 : address of return value.
//   R5 : address of the runtime function to call.
//   R4 : number of arguments to the call.
void StubCodeCompiler::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t thread_offset = target::NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = target::NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = target::NativeArguments::argv_offset();
  const intptr_t retval_offset = target::NativeArguments::retval_offset();

  __ Comment("CallToRuntimeStub");
  __ ldr(CODE_REG, Address(THR, target::Thread::call_to_runtime_stub_offset()));
  __ SetPrologueOffset();
  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ StoreToOffset(FP, THR, target::Thread::top_exit_frame_info_offset());

  // Mark that the thread exited generated code through a runtime call.
  __ LoadImmediate(R8, target::Thread::exit_through_runtime_call());
  __ StoreToOffset(R8, THR, target::Thread::exit_through_ffi_offset());

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(R8, THR, target::Thread::vm_tag_offset());
    __ CompareImmediate(R8, VMTag::kDartTagId);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing VM code.
  __ StoreToOffset(R5, THR, target::Thread::vm_tag_offset());

  // Reserve space for arguments and align frame before entering C++ world.
  // target::NativeArguments are passed in registers.
  __ Comment("align stack");
  // Reserve space for arguments.
  ASSERT(target::NativeArguments::StructSize() == 4 * target::kWordSize);
  __ ReserveAlignedFrameSpace(target::NativeArguments::StructSize());

  // Pass target::NativeArguments structure by value and call runtime.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * target::kWordSize);
  // Set thread in NativeArgs.
  __ mov(R0, THR);

  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * target::kWordSize);
  __ mov(R1, R4);  // Set argc in target::NativeArguments.

  ASSERT(argv_offset == 2 * target::kWordSize);
  __ add(R2, ZR, Operand(R4, LSL, 3));
  __ add(R2, FP, Operand(R2));  // Compute argv.
  // Set argv in target::NativeArguments.
  __ AddImmediate(R2,
                  target::frame_layout.param_end_from_fp * target::kWordSize);

  ASSERT(retval_offset == 3 * target::kWordSize);
  __ AddImmediate(R3, R2, target::kWordSize);

  __ StoreToOffset(R0, SP, thread_offset);
  __ StoreToOffset(R1, SP, argc_tag_offset);
  __ StoreToOffset(R2, SP, argv_offset);
  __ StoreToOffset(R3, SP, retval_offset);
  __ mov(R0, SP);  // Pass the pointer to the target::NativeArguments.

  // We are entering runtime code, so the C stack pointer must be restored from
  // the stack limit to the top of the stack. We cache the stack limit address
  // in a callee-saved register.
  __ mov(R25, CSP);
  __ mov(CSP, SP);

  __ blr(R5);
  __ Comment("CallToRuntimeStub return");

  // Restore SP and CSP.
  __ mov(SP, CSP);
  __ mov(CSP, R25);

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();

  // Retval is next to 1st argument.
  // Mark that the thread is executing Dart code.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(R2, THR, target::Thread::vm_tag_offset());

  // Mark that the thread has not exited generated Dart code.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(R2, THR, target::Thread::exit_through_ffi_offset());

  // Reset exit frame information in Isolate's mutator thread structure.
  __ StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());

  // Restore the global object pool after returning from runtime (old space is
  // moving, so the GOP could have been relocated).
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ SetupGlobalPoolAndDispatchTable();
  }

  __ LeaveStubFrame();

  // The following return can jump to a lazy-deopt stub, which assumes R0
  // contains a return value and will save it in a GC-visible way.  We therefore
  // have to ensure R0 does not contain any garbage value left from the C
  // function we called (which has return type "void").
  // (See GenerateDeoptimizationSequence::saved_result_slot_from_fp.)
  __ LoadImmediate(R0, 0);
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
  RegisterSet all_registers;
  all_registers.AddAllNonReservedRegisters(save_fpu_registers);

  // To make the stack map calculation architecture independent we do the same
  // as on intel.
  READS_RETURN_ADDRESS_FROM_LR(__ Push(LR));
  __ PushRegisters(all_registers);
  __ ldr(CODE_REG, Address(THR, self_code_stub_offset_from_thread));
  __ EnterStubFrame();
  perform_runtime_call();
  if (!allow_return) {
    __ Breakpoint();
    return;
  }
  __ LeaveStubFrame();
  __ PopRegisters(all_registers);
  __ Drop(1);  // We use the LR restored via LeaveStubFrame.
  READS_RETURN_ADDRESS_FROM_LR(__ ret(LR));
}

void StubCodeCompiler::GenerateSharedStub(
    Assembler* assembler,
    bool save_fpu_registers,
    const RuntimeEntry* target,
    intptr_t self_code_stub_offset_from_thread,
    bool allow_return,
    bool store_runtime_result_in_result_register) {
  ASSERT(!store_runtime_result_in_result_register || allow_return);
  auto perform_runtime_call = [&]() {
    if (store_runtime_result_in_result_register) {
      __ PushRegister(NULL_REG);
    }
    __ CallRuntime(*target, /*argument_count=*/0);
    if (store_runtime_result_in_result_register) {
      __ PopRegister(R0);
      __ str(R0,
             Address(FP, target::kWordSize *
                             StubCodeCompiler::WordOffsetFromFpToCpuRegister(
                                 SharedSlowPathStubABI::kResultReg)));
    }
  };
  GenerateSharedStubGeneric(assembler, save_fpu_registers,
                            self_code_stub_offset_from_thread, allow_return,
                            perform_runtime_call);
}

void StubCodeCompiler::GenerateEnterSafepointStub(Assembler* assembler) {
  RegisterSet all_registers;
  all_registers.AddAllGeneralRegisters();

  __ EnterFrame(0);
  __ PushRegisters(all_registers);

  __ mov(CALLEE_SAVED_TEMP, CSP);
  __ mov(CALLEE_SAVED_TEMP2, SP);
  __ ReserveAlignedFrameSpace(0);
  __ mov(CSP, SP);

  __ ldr(R0, Address(THR, kEnterSafepointRuntimeEntry.OffsetFromThread()));
  __ blr(R0);

  __ mov(SP, CALLEE_SAVED_TEMP2);
  __ mov(CSP, CALLEE_SAVED_TEMP);

  __ PopRegisters(all_registers);
  __ LeaveFrame();

  __ Ret();
}

void StubCodeCompiler::GenerateExitSafepointStub(Assembler* assembler) {
  RegisterSet all_registers;
  all_registers.AddAllGeneralRegisters();

  __ EnterFrame(0);
  __ PushRegisters(all_registers);

  __ mov(CALLEE_SAVED_TEMP, CSP);
  __ mov(CALLEE_SAVED_TEMP2, SP);
  __ ReserveAlignedFrameSpace(0);
  __ mov(CSP, SP);

  // Set the execution state to VM while waiting for the safepoint to end.
  // This isn't strictly necessary but enables tests to check that we're not
  // in native code anymore. See tests/ffi/function_gc_test.dart for example.
  __ LoadImmediate(R0, target::Thread::vm_execution_state());
  __ str(R0, Address(THR, target::Thread::execution_state_offset()));

  __ ldr(R0, Address(THR, kExitSafepointRuntimeEntry.OffsetFromThread()));
  __ blr(R0);

  __ mov(SP, CALLEE_SAVED_TEMP2);
  __ mov(CSP, CALLEE_SAVED_TEMP);

  __ PopRegisters(all_registers);
  __ LeaveFrame();

  __ Ret();
}

// Calls native code within a safepoint.
//
// On entry:
//   R9: target to call
//   Stack: set up for native call (SP), aligned, CSP < SP
//
// On exit:
//   R19: clobbered, although normally callee-saved
//   Stack: preserved, CSP == SP
void StubCodeCompiler::GenerateCallNativeThroughSafepointStub(
    Assembler* assembler) {
  COMPILE_ASSERT(IsAbiPreservedRegister(R19));

  SPILLS_RETURN_ADDRESS_FROM_LR_TO_REGISTER(__ mov(R19, LR));
  __ LoadImmediate(R10, target::Thread::exit_through_ffi());
  __ TransitionGeneratedToNative(R9, FPREG, R10 /*volatile*/,
                                 /*enter_safepoint=*/true);
  __ mov(R25, CSP);
  __ mov(CSP, SP);

#if defined(DEBUG)
  // Check CSP alignment.
  __ andi(R11 /*volatile*/, SP,
          Immediate(~(OS::ActivationFrameAlignment() - 1)));
  __ cmp(R11, Operand(SP));
  Label done;
  __ b(&done, EQ);
  __ Breakpoint();
  __ Bind(&done);
#endif

  __ blr(R9);

  __ mov(SP, CSP);
  __ mov(CSP, R25);

  __ TransitionNativeToGenerated(R10, /*leave_safepoint=*/true);
  __ ret(R19);
}

#if !defined(DART_PRECOMPILER)
void StubCodeCompiler::GenerateJITCallbackTrampolines(
    Assembler* assembler,
    intptr_t next_callback_id) {
#if !defined(HOST_ARCH_ARM64)
  // TODO(37299): FFI is not support in SIMARM64.
  __ Breakpoint();
#else
  Label done;

  // R9 is volatile and not used for passing any arguments.
  COMPILE_ASSERT(!IsCalleeSavedRegister(R9) && !IsArgumentRegister(R9));
  for (intptr_t i = 0;
       i < NativeCallbackTrampolines::NumCallbackTrampolinesPerPage(); ++i) {
    // We don't use LoadImmediate because we need the trampoline size to be
    // fixed independently of the callback ID.
    //
    // Instead we paste the callback ID directly in the code load it
    // PC-relative.
    __ ldr(R9, compiler::Address::PC(2 * Instr::kInstrSize));
    __ b(&done);
    __ Emit(next_callback_id + i);
  }

  ASSERT(__ CodeSize() ==
         kNativeCallbackTrampolineSize *
             NativeCallbackTrampolines::NumCallbackTrampolinesPerPage());

  __ Bind(&done);

  const intptr_t shared_stub_start = __ CodeSize();

  // The load of the callback ID might have incorrect higher-order bits, since
  // we only emit a 32-bit callback ID.
  __ uxtw(R9, R9);

  // Save THR (callee-saved) and LR on real real C stack (CSP). Keeps it
  // aligned.
  COMPILE_ASSERT(StubCodeCompiler::kNativeCallbackTrampolineStackDelta == 2);
  SPILLS_LR_TO_FRAME(__ stp(
      THR, LR, Address(CSP, -2 * target::kWordSize, Address::PairPreIndex)));

  COMPILE_ASSERT(!IsArgumentRegister(THR));

  RegisterSet all_registers;
  all_registers.AddAllArgumentRegisters();
  all_registers.Add(Location::RegisterLocation(
      CallingConventions::kPointerToReturnStructRegisterCall));

  // The call below might clobber R9 (volatile, holding callback_id).
  all_registers.Add(Location::RegisterLocation(R9));

  // Load the thread, verify the callback ID and exit the safepoint.
  //
  // We exit the safepoint inside DLRT_GetThreadForNativeCallbackTrampoline
  // in order to safe code size on this shared stub.
  {
    __ mov(SP, CSP);

    __ EnterFrame(0);
    __ PushRegisters(all_registers);

    __ EnterFrame(0);
    __ ReserveAlignedFrameSpace(0);

    __ mov(CSP, SP);

    // Since DLRT_GetThreadForNativeCallbackTrampoline can theoretically be
    // loaded anywhere, we use the same trick as before to ensure a predictable
    // instruction sequence.
    Label call;
    __ mov(R0, R9);
    __ ldr(R1, compiler::Address::PC(2 * Instr::kInstrSize));
    __ b(&call);

    __ Emit64(
        reinterpret_cast<int64_t>(&DLRT_GetThreadForNativeCallbackTrampoline));

    __ Bind(&call);
    __ blr(R1);
    __ mov(THR, R0);

    __ LeaveFrame();

    __ PopRegisters(all_registers);
    __ LeaveFrame();

    __ mov(CSP, SP);
  }

  COMPILE_ASSERT(!IsCalleeSavedRegister(R10) && !IsArgumentRegister(R10));

  // Load the code object.
  __ LoadFromOffset(R10, THR, compiler::target::Thread::callback_code_offset());
  __ LoadFieldFromOffset(R10, R10,
                         compiler::target::GrowableObjectArray::data_offset());
  __ ldr(R10, __ ElementAddressForRegIndex(
                  /*external=*/false,
                  /*array_cid=*/kArrayCid,
                  /*index, smi-tagged=*/compiler::target::kWordSize * 2,
                  /*index_unboxed=*/false,
                  /*array=*/R10,
                  /*index=*/R9,
                  /*temp=*/TMP));
  __ LoadFieldFromOffset(R10, R10,
                         compiler::target::Code::entry_point_offset());

  // Clobbers all volatile registers, including the callback ID in R9.
  // Resets CSP and SP, important for EnterSafepoint below.
  __ blr(R10);

  // EnterSafepoint clobbers TMP, TMP2 and R9 -- all volatile and not holding
  // return values.
  __ EnterSafepoint(/*scratch=*/R9);

  // Pop LR and THR from the real stack (CSP).
  RESTORES_LR_FROM_FRAME(__ ldp(
      THR, LR, Address(CSP, 2 * target::kWordSize, Address::PairPostIndex)));

  __ ret();

  ASSERT((__ CodeSize() - shared_stub_start) == kNativeCallbackSharedStubSize);
  ASSERT(__ CodeSize() <= VirtualMemory::PageSize());

#if defined(DEBUG)
  while (__ CodeSize() < VirtualMemory::PageSize()) {
    __ Breakpoint();
  }
#endif
#endif  // !defined(HOST_ARCH_ARM64)
}
#endif  // !defined(DART_PRECOMPILER)

// R1: The extracted method.
// R4: The type_arguments_field_offset (or 0)
void StubCodeCompiler::GenerateBuildMethodExtractorStub(
    Assembler* assembler,
    const Object& closure_allocation_stub,
    const Object& context_allocation_stub) {
  const intptr_t kReceiverOffset = target::frame_layout.param_end_from_fp + 1;

  __ EnterStubFrame();

  // Build type_arguments vector (or null)
  Label no_type_args;
  __ ldr(R3, Address(THR, target::Thread::object_null_offset()), kEightBytes);
  __ cmp(R4, Operand(0));
  __ b(&no_type_args, EQ);
  __ ldr(R0, Address(FP, kReceiverOffset * target::kWordSize));
  __ ldr(R3, Address(R0, R4));
  __ Bind(&no_type_args);

  // Push type arguments & extracted method.
  __ PushPair(R3, R1);

  // Allocate context.
  {
    Label done, slow_path;
    __ TryAllocateArray(kContextCid, target::Context::InstanceSize(1),
                        &slow_path,
                        R0,  // instance
                        R1,  // end address
                        R2, R3);
    __ ldr(R1, Address(THR, target::Thread::object_null_offset()));
    __ str(R1, FieldAddress(R0, target::Context::parent_offset()));
    __ LoadImmediate(R1, 1);
    __ str(R1, FieldAddress(R0, target::Context::num_variables_offset()));
    __ b(&done);

    __ Bind(&slow_path);

    __ LoadImmediate(/*num_vars=*/R1, 1);
    __ LoadObject(CODE_REG, context_allocation_stub);
    __ ldr(R0, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
    __ blr(R0);

    __ Bind(&done);
  }

  // Store receiver in context
  __ ldr(R1, Address(FP, target::kWordSize * kReceiverOffset));
  __ StoreIntoObject(R0, FieldAddress(R0, target::Context::variable_offset(0)),
                     R1);

  // Push context.
  __ Push(R0);

  // Allocate closure.
  __ LoadObject(CODE_REG, closure_allocation_stub);
  __ ldr(R1, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                        CodeEntryKind::kUnchecked)));
  __ blr(R1);

  // Populate closure object.
  __ Pop(R1);  // Pop context.
  __ StoreIntoObject(R0, FieldAddress(R0, target::Closure::context_offset()),
                     R1);
  __ PopPair(R3, R1);  // Pop type arguments & extracted method.
  __ StoreIntoObjectNoBarrier(
      R0, FieldAddress(R0, target::Closure::function_offset()), R1);
  __ StoreIntoObjectNoBarrier(
      R0,
      FieldAddress(R0, target::Closure::instantiator_type_arguments_offset()),
      R3);
  __ LoadObject(R1, EmptyTypeArguments());
  __ StoreIntoObjectNoBarrier(
      R0, FieldAddress(R0, target::Closure::delayed_type_arguments_offset()),
      R1);

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
      __ adds(RangeErrorABI::kIndexReg, RangeErrorABI::kIndexReg,
              compiler::Operand(RangeErrorABI::kIndexReg));
      __ BranchIf(NO_OVERFLOW, &length);
      {
        // Allocate a mint, reload the two registers and popualte the mint.
        __ PushRegister(NULL_REG);
        __ CallRuntime(kAllocateMintRuntimeEntry, /*argument_count=*/0);
        __ PopRegister(RangeErrorABI::kIndexReg);
        __ ldr(TMP,
               Address(FP, target::kWordSize *
                               StubCodeCompiler::WordOffsetFromFpToCpuRegister(
                                   RangeErrorABI::kIndexReg)));
        __ str(TMP, FieldAddress(RangeErrorABI::kIndexReg,
                                 target::Mint::value_offset()));
        __ ldr(RangeErrorABI::kLengthReg,
               Address(FP, target::kWordSize *
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
//   LR : return address.
//   SP : address of return value.
//   R5 : address of the native function to call.
//   R2 : address of first argument in argument array.
//   R1 : argc_tag including number of arguments and function kind.
static void GenerateCallNativeWithWrapperStub(Assembler* assembler,
                                              Address wrapper) {
  const intptr_t thread_offset = target::NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = target::NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = target::NativeArguments::argv_offset();
  const intptr_t retval_offset = target::NativeArguments::retval_offset();

  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to native code.
  __ StoreToOffset(FP, THR, target::Thread::top_exit_frame_info_offset());

  // Mark that the thread exited generated code through a runtime call.
  __ LoadImmediate(R6, target::Thread::exit_through_runtime_call());
  __ StoreToOffset(R6, THR, target::Thread::exit_through_ffi_offset());

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(R6, THR, target::Thread::vm_tag_offset());
    __ CompareImmediate(R6, VMTag::kDartTagId);
    __ b(&ok, EQ);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing native code.
  __ StoreToOffset(R5, THR, target::Thread::vm_tag_offset());

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // R0) and align frame before entering the C++ world.
  __ ReserveAlignedFrameSpace(target::NativeArguments::StructSize());

  // Initialize target::NativeArguments structure and call native function.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * target::kWordSize);
  // Set thread in NativeArgs.
  __ mov(R0, THR);

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * target::kWordSize);
  // Set argc in target::NativeArguments: R1 already contains argc.

  ASSERT(argv_offset == 2 * target::kWordSize);
  // Set argv in target::NativeArguments: R2 already contains argv.

  // Set retval in NativeArgs.
  ASSERT(retval_offset == 3 * target::kWordSize);
  __ AddImmediate(R3, FP, 2 * target::kWordSize);

  // Passing the structure by value as in runtime calls would require changing
  // Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ StoreToOffset(R0, SP, thread_offset);
  __ StoreToOffset(R1, SP, argc_tag_offset);
  __ StoreToOffset(R2, SP, argv_offset);
  __ StoreToOffset(R3, SP, retval_offset);
  __ mov(R0, SP);  // Pass the pointer to the target::NativeArguments.

  // We are entering runtime code, so the C stack pointer must be restored from
  // the stack limit to the top of the stack. We cache the stack limit address
  // in the Dart SP register, which is callee-saved in the C ABI.
  __ mov(R25, CSP);
  __ mov(CSP, SP);

  __ mov(R1, R5);  // Pass the function entrypoint to call.

  // Call native function invocation wrapper or redirection via simulator.
  __ Call(wrapper);

  // Restore SP and CSP.
  __ mov(SP, CSP);
  __ mov(CSP, R25);

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(R2, THR, target::Thread::vm_tag_offset());

  // Mark that the thread has not exited generated Dart code.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(R2, THR, target::Thread::exit_through_ffi_offset());

  // Reset exit frame information in Isolate's mutator thread structure.
  __ StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());

  // Restore the global object pool after returning from runtime (old space is
  // moving, so the GOP could have been relocated).
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ SetupGlobalPoolAndDispatchTable();
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
//   LR : return address.
//   SP : address of return value.
//   R5 : address of the native function to call.
//   R2 : address of first argument in argument array.
//   R1 : argc_tag including number of arguments and function kind.
void StubCodeCompiler::GenerateCallBootstrapNativeStub(Assembler* assembler) {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::bootstrap_native_wrapper_entry_point_offset()));
}

// Input parameters:
//   R4: arguments descriptor array.
void StubCodeCompiler::GenerateCallStaticFunctionStub(Assembler* assembler) {
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ Push(R4);
  __ Push(ZR);
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  // Get Code object result and restore arguments descriptor array.
  __ Pop(CODE_REG);
  __ Pop(R4);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(R0, CODE_REG, target::Code::entry_point_offset());
  __ br(R0);
}

// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// R4: arguments descriptor array.
void StubCodeCompiler::GenerateFixCallersTargetStub(Assembler* assembler) {
  Label monomorphic;
  __ BranchOnMonomorphicCheckedEntryJIT(&monomorphic);

  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ ldr(CODE_REG,
         Address(THR, target::Thread::fix_callers_target_code_offset()));
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ Push(R4);
  __ Push(ZR);
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  // Get Code object result and restore arguments descriptor array.
  __ Pop(CODE_REG);
  __ Pop(R4);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(R0, CODE_REG, target::Code::entry_point_offset());
  __ br(R0);

  __ Bind(&monomorphic);
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ ldr(CODE_REG,
         Address(THR, target::Thread::fix_callers_target_code_offset()));
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ Push(R5);  // Preserve cache (guarded CID as Smi).
  __ Push(R0);  // Preserve receiver.
  __ Push(ZR);
  __ CallRuntime(kFixCallersTargetMonomorphicRuntimeEntry, 0);
  __ Pop(CODE_REG);
  __ Pop(R0);  // Restore receiver.
  __ Pop(R5);  // Restore cache (guarded CID as Smi).
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(
      R1, CODE_REG,
      target::Code::entry_point_offset(CodeEntryKind::kMonomorphic));
  __ br(R1);
}

// Called from object allocate instruction when the allocation stub has been
// disabled.
void StubCodeCompiler::GenerateFixAllocationStubTargetStub(
    Assembler* assembler) {
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ ldr(CODE_REG,
         Address(THR, target::Thread::fix_allocation_stub_code_offset()));
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ Push(ZR);
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  // Get Code object result.
  __ Pop(CODE_REG);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(R0, CODE_REG, target::Code::entry_point_offset());
  __ br(R0);
}

// Input parameters:
//   R2: smi-tagged argument count, may be zero.
//   FP[target::frame_layout.param_end_from_fp + 1]: last argument.
static void PushArrayOfArguments(Assembler* assembler) {
  // Allocate array to store arguments of caller.
  __ LoadObject(R1, NullObject());
  // R1: null element type for raw Array.
  // R2: smi-tagged argument count, may be zero.
  __ BranchLink(StubCodeAllocateArray());
  // R0: newly allocated array.
  // R2: smi-tagged argument count, may be zero (was preserved by the stub).
  __ Push(R0);  // Array is in R0 and on top of stack.
  __ add(R1, FP, Operand(R2, LSL, 2));
  __ AddImmediate(R1,
                  target::frame_layout.param_end_from_fp * target::kWordSize);
  __ AddImmediate(R3, R0, target::Array::data_offset() - kHeapObjectTag);
  // R1: address of first argument on stack.
  // R3: address of first argument in array.

  Label loop, loop_exit;
  __ Bind(&loop);
  __ CompareRegisters(R2, ZR);
  __ b(&loop_exit, LE);
  __ ldr(R7, Address(R1));
  __ AddImmediate(R1, -target::kWordSize);
  __ AddImmediate(R3, target::kWordSize);
  __ AddImmediate(R2, R2, -target::ToRawSmi(1));
  __ StoreIntoObject(R0, Address(R3, -target::kWordSize), R7);
  __ b(&loop);
  __ Bind(&loop_exit);
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
// Stack after TagAndPushPP() below:
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
      (kNumberOfCpuRegisters - R0);
  const intptr_t saved_exception_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - R0);
  const intptr_t saved_stacktrace_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - R1);
  // Result in R0 is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    const Register r = static_cast<Register>(i);
    if (r == CODE_REG) {
      // Save the original value of CODE_REG pushed before invoking this stub
      // instead of the value used to call this stub.
      COMPILE_ASSERT(R25 > CODE_REG);
      __ ldr(R25, Address(FP, 2 * target::kWordSize));
      __ str(R25, Address(SP, -1 * target::kWordSize, Address::PreIndex));
    } else if (r == R15) {
      // Because we save registers in decreasing order, IP0 will already be
      // saved.
      COMPILE_ASSERT(IP0 == R16);
      __ mov(IP0, R15);
      __ str(IP0, Address(SP, -1 * target::kWordSize, Address::PreIndex));
    } else {
      __ str(r, Address(SP, -1 * target::kWordSize, Address::PreIndex));
    }
  }

  for (intptr_t reg_idx = kNumberOfVRegisters - 1; reg_idx >= 0; reg_idx--) {
    VRegister vreg = static_cast<VRegister>(reg_idx);
    __ PushQuad(vreg);
  }

  __ mov(R0, SP);  // Pass address of saved registers block.
  bool is_lazy =
      (kind == kLazyDeoptFromReturn) || (kind == kLazyDeoptFromThrow);
  __ LoadImmediate(R1, is_lazy ? 1 : 0);
  __ ReserveAlignedFrameSpace(0);
  __ CallRuntime(kDeoptimizeCopyFrameRuntimeEntry, 2);
  // Result (R0) is stack-size (FP - SP) in bytes.

  if (kind == kLazyDeoptFromReturn) {
    // Restore result into R1 temporarily.
    __ LoadFromOffset(R1, FP, saved_result_slot_from_fp * target::kWordSize);
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into R1 temporarily.
    __ LoadFromOffset(R1, FP, saved_exception_slot_from_fp * target::kWordSize);
    __ LoadFromOffset(R2, FP,
                      saved_stacktrace_slot_from_fp * target::kWordSize);
  }

  // There is a Dart Frame on the stack. We must restore PP and leave frame.
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ sub(SP, FP, Operand(R0));

  // DeoptimizeFillFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ EnterStubFrame();

  if (kind == kLazyDeoptFromReturn) {
    __ Push(R1);  // Preserve result as first local.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Push(R1);  // Preserve exception as first local.
    __ Push(R2);  // Preserve stacktrace as second local.
  }
  __ ReserveAlignedFrameSpace(0);
  __ mov(R0, FP);  // Pass last FP as parameter in R0.
  __ CallRuntime(kDeoptimizeFillFrameRuntimeEntry, 1);
  if (kind == kLazyDeoptFromReturn) {
    // Restore result into R1.
    __ LoadFromOffset(
        R1, FP, target::frame_layout.first_local_from_fp * target::kWordSize);
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into R1.
    __ LoadFromOffset(
        R1, FP, target::frame_layout.first_local_from_fp * target::kWordSize);
    __ LoadFromOffset(
        R2, FP,
        (target::frame_layout.first_local_from_fp - 1) * target::kWordSize);
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
    __ Push(R1);  // Preserve result, it will be GC-d here.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Push(R1);  // Preserve exception, it will be GC-d here.
    __ Push(R2);  // Preserve stacktrace, it will be GC-d here.
  }

  __ Push(ZR);  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ Pop(R2);
  __ SmiUntag(R2);
  if (kind == kLazyDeoptFromReturn) {
    __ Pop(R0);  // Restore result.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Pop(R1);  // Restore stacktrace.
    __ Pop(R0);  // Restore exception.
  }
  __ LeaveStubFrame();
  // Remove materialization arguments.
  __ add(SP, SP, Operand(R2));
  // The caller is responsible for emitting the return instruction.
}

// R0: result, must be preserved
void StubCodeCompiler::GenerateDeoptimizeLazyFromReturnStub(
    Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ Push(TMP);
  // Return address for "call" to deopt stub.
  WRITES_RETURN_ADDRESS_TO_LR(__ LoadImmediate(LR, kZapReturnAddress));
  __ ldr(CODE_REG,
         Address(THR, target::Thread::lazy_deopt_from_return_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromReturn);
  __ ret();
}

// R0: exception, must be preserved
// R1: stacktrace, must be preserved
void StubCodeCompiler::GenerateDeoptimizeLazyFromThrowStub(
    Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ Push(TMP);
  // Return address for "call" to deopt stub.
  WRITES_RETURN_ADDRESS_TO_LR(__ LoadImmediate(LR, kZapReturnAddress));
  __ ldr(CODE_REG,
         Address(THR, target::Thread::lazy_deopt_from_throw_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromThrow);
  __ ret();
}

void StubCodeCompiler::GenerateDeoptimizeStub(Assembler* assembler) {
  __ Push(CODE_REG);
  __ ldr(CODE_REG, Address(THR, target::Thread::deoptimize_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);
  __ ret();
}

// R5: ICData/MegamorphicCache
static void GenerateNoSuchMethodDispatcherBody(Assembler* assembler) {
  __ EnterStubFrame();

  __ ldr(R4,
         FieldAddress(R5, target::CallSiteData::arguments_descriptor_offset()));

  // Load the receiver.
  __ LoadFieldFromOffset(R2, R4, target::ArgumentsDescriptor::size_offset());
  __ add(TMP, FP, Operand(R2, LSL, 2));  // R2 is Smi.
  __ LoadFromOffset(R6, TMP,
                    target::frame_layout.param_end_from_fp * target::kWordSize);
  __ Push(ZR);  // Result slot.
  __ Push(R6);  // Receiver.
  __ Push(R5);  // ICData/MegamorphicCache.
  __ Push(R4);  // Arguments descriptor.

  // Adjust arguments count.
  __ LoadFieldFromOffset(R3, R4,
                         target::ArgumentsDescriptor::type_args_len_offset());
  __ AddImmediate(TMP, R2, 1);  // Include the type arguments.
  __ cmp(R3, Operand(0));
  __ csinc(R2, R2, TMP, EQ);  // R2 <- (R3 == 0) ? R2 : TMP + 1 (R2 : R2 + 2).

  // R2: Smi-tagged arguments array length.
  PushArrayOfArguments(assembler);
  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromCallStubRuntimeEntry, kNumArgs);
  __ Drop(4);
  __ Pop(R0);  // Return value.
  __ LeaveStubFrame();
  __ ret();
}

static void GenerateDispatcherCode(Assembler* assembler,
                                   Label* call_target_function) {
  __ Comment("NoSuchMethodDispatch");
  // When lazily generated invocation dispatchers are disabled, the
  // miss-handler may return null.
  __ CompareObject(R0, NullObject());
  __ b(call_target_function, NE);

  GenerateNoSuchMethodDispatcherBody(assembler);
}

// Input:
//   R4 - arguments descriptor
//   R5 - icdata/megamorphic_cache
void StubCodeCompiler::GenerateNoSuchMethodDispatcherStub(
    Assembler* assembler) {
  GenerateNoSuchMethodDispatcherBody(assembler);
}

// Called for inline allocation of arrays.
// Input parameters:
//   LR: return address.
//   R2: array length as Smi.
//   R1: array element type (either NULL or an instantiated type).
// NOTE: R2 cannot be clobbered here as the caller relies on it being saved.
// The newly allocated object is returned in R0.
void StubCodeCompiler::GenerateAllocateArrayStub(Assembler* assembler) {
  if (!FLAG_use_slow_path) {
    Label slow_case;
    // Compute the size to be allocated, it is based on the array length
    // and is computed as:
    // RoundedAllocationSize(
    //     (array_length * kwordSize) + target::Array::header_size()).
    // Assert that length is a Smi.
    __ tsti(R2, Immediate(kSmiTagMask));
    __ b(&slow_case, NE);

    __ cmp(R2, Operand(0));
    __ b(&slow_case, LT);

    // Check for maximum allowed length.
    const intptr_t max_len =
        target::ToRawSmi(target::Array::kMaxNewSpaceElements);
    __ CompareImmediate(R2, max_len);
    __ b(&slow_case, GT);

    const intptr_t cid = kArrayCid;
    NOT_IN_PRODUCT(__ MaybeTraceAllocation(kArrayCid, R4, &slow_case));

    // Calculate and align allocation size.
    // Load new object start and calculate next object start.
    // R1: array element type.
    // R2: array length as Smi.
    __ ldr(R0, Address(THR, target::Thread::top_offset()));
    intptr_t fixed_size_plus_alignment_padding =
        target::Array::header_size() +
        target::ObjectAlignment::kObjectAlignment - 1;
    __ LoadImmediate(R3, fixed_size_plus_alignment_padding);
    __ add(R3, R3, Operand(R2, LSL, 2));  // R2 is Smi.
    ASSERT(kSmiTagShift == 1);
    __ andi(R3, R3,
            Immediate(~(target::ObjectAlignment::kObjectAlignment - 1)));
    // R0: potential new object start.
    // R3: object size in bytes.
    __ adds(R7, R3, Operand(R0));
    __ b(&slow_case, CS);  // Branch if unsigned overflow.

    // Check if the allocation fits into the remaining space.
    // R0: potential new object start.
    // R1: array element type.
    // R2: array length as Smi.
    // R3: array size.
    // R7: potential next object start.
    __ LoadFromOffset(TMP, THR, target::Thread::end_offset());
    __ CompareRegisters(R7, TMP);
    __ b(&slow_case, CS);  // Branch if unsigned higher or equal.

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    // R0: potential new object start.
    // R3: array size.
    // R7: potential next object start.
    __ str(R7, Address(THR, target::Thread::top_offset()));
    __ add(R0, R0, Operand(kHeapObjectTag));

    // R0: new object start as a tagged pointer.
    // R1: array element type.
    // R2: array length as Smi.
    // R3: array size.
    // R7: new object end address.

    // Store the type argument field.
    __ StoreIntoObjectOffsetNoBarrier(
        R0, target::Array::type_arguments_offset(), R1);

    // Set the length field.
    __ StoreIntoObjectOffsetNoBarrier(R0, target::Array::length_offset(), R2);

    // Calculate the size tag.
    // R0: new object start as a tagged pointer.
    // R2: array length as Smi.
    // R3: array size.
    // R7: new object end address.
    const intptr_t shift = target::ObjectLayout::kTagBitsSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2;
    __ CompareImmediate(R3, target::ObjectLayout::kSizeTagMaxSizeTag);
    // If no size tag overflow, shift R1 left, else set R1 to zero.
    __ LslImmediate(TMP, R3, shift);
    __ csel(R1, TMP, R1, LS);
    __ csel(R1, ZR, R1, HI);

    // Get the class index and insert it into the tags.
    const uword tags =
        target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);

    __ LoadImmediate(TMP, tags);
    __ orr(R1, R1, Operand(TMP));
    __ StoreFieldToOffset(R1, R0, target::Array::tags_offset());

    // Initialize all array elements to raw_null.
    // R0: new object start as a tagged pointer.
    // R7: new object end address.
    // R2: array length as Smi.
    __ AddImmediate(R1, R0, target::Array::data_offset() - kHeapObjectTag);
    // R1: iterator which initially points to the start of the variable
    // data area to be initialized.
    Label loop, done;
    __ Bind(&loop);
    // TODO(cshapiro): StoreIntoObjectNoBarrier
    __ CompareRegisters(R1, R7);
    __ b(&done, CS);
    __ str(NULL_REG, Address(R1));  // Store if unsigned lower.
    __ AddImmediate(R1, target::kWordSize);
    __ b(&loop);  // Loop until R1 == R7.
    __ Bind(&done);

    // Done allocating and initializing the array.
    // R0: new object.
    // R2: array length as Smi (preserved for the caller.)
    __ ret();

    // Unable to allocate the array using the fast inline code, just call
    // into the runtime.
    __ Bind(&slow_case);
  }
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  // Push array length as Smi and element type.
  __ Push(ZR);
  __ Push(R2);
  __ Push(R1);
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);
  // Pop arguments; result is popped in IP.
  __ Pop(R1);
  __ Pop(R2);
  __ Pop(R0);
  __ LeaveStubFrame();

  // Write-barrier elimination might be enabled for this array (depending on the
  // array length). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(assembler);

  __ ret();
}

void StubCodeCompiler::GenerateAllocateMintSharedWithFPURegsStub(
    Assembler* assembler) {
  // For test purpose call allocation stub without inline allocation attempt.
  if (!FLAG_use_slow_path) {
    Label slow_case;
    __ TryAllocate(compiler::MintClass(), &slow_case,
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
    __ TryAllocate(compiler::MintClass(), &slow_case,
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

// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   LR : points to return address.
//   R0 : code object of the Dart function to call.
//   R1 : arguments descriptor array.
//   R2 : arguments array.
//   R3 : current thread.
void StubCodeCompiler::GenerateInvokeDartCodeStub(Assembler* assembler) {
  __ Comment("InvokeDartCodeStub");

  // Copy the C stack pointer (CSP/R31) into the stack pointer we'll actually
  // use to access the stack (SP/R15) and set the C stack pointer to near the
  // stack limit, loaded from the Thread held in R3, to prevent signal handlers
  // from over-writing Dart frames.
  __ mov(SP, CSP);
  __ SetupCSPFromThread(R3);
  READS_RETURN_ADDRESS_FROM_LR(__ Push(LR));  // Marker for the profiler.
  __ EnterFrame(0);

  // Push code object to PC marker slot.
  __ ldr(TMP, Address(R3, target::Thread::invoke_dart_code_stub_offset()));
  __ Push(TMP);

#if defined(TARGET_OS_FUCHSIA)
  __ str(R18, Address(R3, target::Thread::saved_shadow_call_stack_offset()));
#elif defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  __ PushNativeCalleeSavedRegisters();

  // Set up THR, which caches the current thread in Dart code.
  if (THR != R3) {
    __ mov(THR, R3);
  }

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();

  // Save the current VMTag on the stack.
  __ LoadFromOffset(R4, THR, target::Thread::vm_tag_offset());
  __ Push(R4);

  // Save top resource and top exit frame info. Use R6 as a temporary register.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ LoadFromOffset(R6, THR, target::Thread::top_resource_offset());
  __ StoreToOffset(ZR, THR, target::Thread::top_resource_offset());
  __ Push(R6);

  __ LoadFromOffset(R6, THR, target::Thread::exit_through_ffi_offset());
  __ Push(R6);
  __ LoadImmediate(R6, 0);
  __ StoreToOffset(R6, THR, target::Thread::exit_through_ffi_offset());

  __ LoadFromOffset(R6, THR, target::Thread::top_exit_frame_info_offset());
  __ StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());
  // target::frame_layout.exit_link_slot_from_entry_fp must be kept in sync
  // with the code below.
#if defined(TARGET_OS_FUCHSIA)
  ASSERT(target::frame_layout.exit_link_slot_from_entry_fp == -24);
#else
  ASSERT(target::frame_layout.exit_link_slot_from_entry_fp == -23);
#endif
  __ Push(R6);

  // Mark that the thread is executing Dart code. Do this after initializing the
  // exit link for the profiler.
  __ LoadImmediate(R6, VMTag::kDartTagId);
  __ StoreToOffset(R6, THR, target::Thread::vm_tag_offset());

  // Load arguments descriptor array into R4, which is passed to Dart code.
  __ LoadFromOffset(R4, R1, VMHandles::kOffsetOfRawPtrInHandle);

  // Load number of arguments into R5 and adjust count for type arguments.
  __ LoadFieldFromOffset(R5, R4, target::ArgumentsDescriptor::count_offset());
  __ LoadFieldFromOffset(R3, R4,
                         target::ArgumentsDescriptor::type_args_len_offset());
  __ AddImmediate(TMP, R5, 1);  // Include the type arguments.
  __ cmp(R3, Operand(0));
  __ csinc(R5, R5, TMP, EQ);  // R5 <- (R3 == 0) ? R5 : TMP + 1 (R5 : R5 + 2).
  __ SmiUntag(R5);

  // Compute address of 'arguments array' data area into R2.
  __ LoadFromOffset(R2, R2, VMHandles::kOffsetOfRawPtrInHandle);
  __ AddImmediate(R2, target::Array::data_offset() - kHeapObjectTag);

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ cmp(R5, Operand(0));
  __ b(&done_push_arguments, EQ);  // check if there are arguments.
  __ LoadImmediate(R1, 0);
  __ Bind(&push_arguments);
  __ ldr(R3, Address(R2));
  __ Push(R3);
  __ add(R1, R1, Operand(1));
  __ add(R2, R2, Operand(target::kWordSize));
  __ cmp(R1, Operand(R5));
  __ b(&push_arguments, LT);
  __ Bind(&done_push_arguments);

  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ SetupGlobalPoolAndDispatchTable();
  } else {
    // We now load the pool pointer(PP) with a GC safe value as we are about to
    // invoke dart code. We don't need a real object pool here.
    // Smi zero does not work because ARM64 assumes PP to be untagged.
    __ LoadObject(PP, NullObject());
  }

  // Call the Dart code entrypoint.
  __ ldr(CODE_REG, Address(R0, VMHandles::kOffsetOfRawPtrInHandle));
  __ ldr(R0, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ blr(R0);  // R4 is the arguments descriptor array.
  __ Comment("InvokeDartCodeStub return");

  // Get rid of arguments pushed on the stack.
  __ AddImmediate(
      SP, FP,
      target::frame_layout.exit_link_slot_from_entry_fp * target::kWordSize);

  // Restore the saved top exit frame info and top resource back into the
  // Isolate structure. Uses R6 as a temporary register for this.
  __ Pop(R6);
  __ StoreToOffset(R6, THR, target::Thread::top_exit_frame_info_offset());
  __ Pop(R6);
  __ StoreToOffset(R6, THR, target::Thread::exit_through_ffi_offset());
  __ Pop(R6);
  __ StoreToOffset(R6, THR, target::Thread::top_resource_offset());

  // Restore the current VMTag from the stack.
  __ Pop(R4);
  __ StoreToOffset(R4, THR, target::Thread::vm_tag_offset());

  __ PopNativeCalleeSavedRegisters();

  // Restore the frame pointer and C stack pointer and return.
  __ LeaveFrame();
  __ Drop(1);
  __ RestoreCSP();
  __ ret();
}

// Helper to generate space allocation of context stub.
// This does not initialise the fields of the context.
// Input:
//   R1: number of context variables.
// Output:
//   R0: new allocated RawContext object.
// Clobbered:
//   R2, R3, R4, TMP
static void GenerateAllocateContextSpaceStub(Assembler* assembler,
                                             Label* slow_case) {
  // First compute the rounded instance size.
  // R1: number of context variables.
  intptr_t fixed_size_plus_alignment_padding =
      target::Context::header_size() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ LoadImmediate(R2, fixed_size_plus_alignment_padding);
  __ add(R2, R2, Operand(R1, LSL, 3));
  ASSERT(kSmiTagShift == 1);
  __ andi(R2, R2, Immediate(~(target::ObjectAlignment::kObjectAlignment - 1)));

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(kContextCid, R4, slow_case));
  // Now allocate the object.
  // R1: number of context variables.
  // R2: object size.
  __ ldr(R0, Address(THR, target::Thread::top_offset()));
  __ add(R3, R2, Operand(R0));
  // Check if the allocation fits into the remaining space.
  // R0: potential new object.
  // R1: number of context variables.
  // R2: object size.
  // R3: potential next object start.
  __ ldr(TMP, Address(THR, target::Thread::end_offset()));
  __ CompareRegisters(R3, TMP);
  __ b(slow_case, CS);  // Branch if unsigned higher or equal.

  // Successfully allocated the object, now update top to point to
  // next object start and initialize the object.
  // R0: new object.
  // R1: number of context variables.
  // R2: object size.
  // R3: next object start.
  __ str(R3, Address(THR, target::Thread::top_offset()));
  __ add(R0, R0, Operand(kHeapObjectTag));

  // Calculate the size tag.
  // R0: new object.
  // R1: number of context variables.
  // R2: object size.
  const intptr_t shift = target::ObjectLayout::kTagBitsSizeTagPos -
                         target::ObjectAlignment::kObjectAlignmentLog2;
  __ CompareImmediate(R2, target::ObjectLayout::kSizeTagMaxSizeTag);
  // If no size tag overflow, shift R2 left, else set R2 to zero.
  __ LslImmediate(TMP, R2, shift);
  __ csel(R2, TMP, R2, LS);
  __ csel(R2, ZR, R2, HI);

  // Get the class index and insert it into the tags.
  // R2: size and bit tags.
  const uword tags =
      target::MakeTagWordForNewSpaceObject(kContextCid, /*instance_size=*/0);

  __ LoadImmediate(TMP, tags);
  __ orr(R2, R2, Operand(TMP));
  __ StoreFieldToOffset(R2, R0, target::Object::tags_offset());

  // Setup up number of context variables field.
  // R0: new object.
  // R1: number of context variables as integer value (not object).
  __ StoreFieldToOffset(R1, R0, target::Context::num_variables_offset());
}

// Called for inline allocation of contexts.
// Input:
//   R1: number of context variables.
// Output:
//   R0: new allocated RawContext object.
// Clobbered:
//   R2, R3, R4, TMP
void StubCodeCompiler::GenerateAllocateContextStub(Assembler* assembler) {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    GenerateAllocateContextSpaceStub(assembler, &slow_case);

    // Setup the parent field.
    // R0: new object.
    // R1: number of context variables.
    __ LoadObject(R2, NullObject());
    __ StoreFieldToOffset(R2, R0, target::Context::parent_offset());

    // Initialize the context variables.
    // R0: new object.
    // R1: number of context variables.
    // R2: raw null.
    {
      Label loop, done;
      __ AddImmediate(R3, R0,
                      target::Context::variable_offset(0) - kHeapObjectTag);
      __ Bind(&loop);
      __ subs(R1, R1, Operand(1));
      __ b(&done, MI);
      __ str(R2, Address(R3, R1, UXTX, Address::Scaled));
      __ b(&loop, NE);  // Loop if R1 not zero.
      __ Bind(&done);
    }

    // Done allocating and initializing the context.
    // R0: new object.
    __ ret();

    __ Bind(&slow_case);
  }
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ SmiTag(R1);
  __ PushObject(NullObject());
  __ Push(R1);
  __ CallRuntime(kAllocateContextRuntimeEntry, 1);  // Allocate context.
  __ Drop(1);  // Pop number of context variables argument.
  __ Pop(R0);  // Pop the new context object.

  // Write-barrier elimination might be enabled for this context (depending on
  // the size). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(assembler, /*preserve_registers=*/false);

  // R0: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();

  __ ret();
}

// Called for clone of contexts.
// Input:
//   R5: context variable to clone.
// Output:
//   R0: new allocated RawContext object.
// Clobbered:
//   R1, (R2), R3, R4, (TMP)
void StubCodeCompiler::GenerateCloneContextStub(Assembler* assembler) {
  {
    Label slow_case;

    // Load num. variable (int32) in the existing context.
    __ ldr(
        R1,
        FieldAddress(R5, target::Context::num_variables_offset(), kFourBytes),
        kFourBytes);

    GenerateAllocateContextSpaceStub(assembler, &slow_case);

    // Load parent in the existing context.
    __ ldr(R3, FieldAddress(R5, target::Context::parent_offset()));
    // Setup the parent field.
    // R0: new context.
    __ StoreIntoObjectNoBarrier(
        R0, FieldAddress(R0, target::Context::parent_offset()), R3);

    // Clone the context variables.
    // R0: new context.
    // R1: number of context variables.
    {
      Label loop, done;
      // R3: Variable array address, new context.
      __ AddImmediate(R3, R0,
                      target::Context::variable_offset(0) - kHeapObjectTag);
      // R4: Variable array address, old context.
      __ AddImmediate(R4, R5,
                      target::Context::variable_offset(0) - kHeapObjectTag);

      __ Bind(&loop);
      __ subs(R1, R1, Operand(1));
      __ b(&done, MI);

      __ ldr(R5, Address(R4, R1, UXTX, Address::Scaled));
      __ str(R5, Address(R3, R1, UXTX, Address::Scaled));
      __ b(&loop, NE);  // Loop if R1 not zero.

      __ Bind(&done);
    }

    // Done allocating and initializing the context.
    // R0: new object.
    __ ret();

    __ Bind(&slow_case);
  }

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ PushPair(R5, NULL_REG);
  __ CallRuntime(kCloneContextRuntimeEntry, 1);  // Clone context.
  // Pop number of context variables argument.
  // Pop the new context object.
  __ PopPair(R1, R0);

  // Write-barrier elimination might be enabled for this context (depending on
  // the size). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(assembler, /*preserve_registers=*/false);

  // R0: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();
  __ ret();
}

void StubCodeCompiler::GenerateWriteBarrierWrappersStub(Assembler* assembler) {
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if ((kDartAvailableCpuRegs & (1 << i)) == 0) continue;

    Register reg = static_cast<Register>(i);
    intptr_t start = __ CodeSize();
    SPILLS_LR_TO_FRAME(__ Push(LR));
    __ Push(kWriteBarrierObjectReg);
    __ mov(kWriteBarrierObjectReg, reg);
    __ Call(Address(THR, target::Thread::write_barrier_entry_point_offset()));
    __ Pop(kWriteBarrierObjectReg);
    RESTORES_LR_FROM_FRAME(__ Pop(LR));
    READS_RETURN_ADDRESS_FROM_LR(__ ret(LR));
    intptr_t end = __ CodeSize();

    RELEASE_ASSERT(end - start == kStoreBufferWrapperSize);
  }
}

// Helper stub to implement Assembler::StoreIntoObject/Array.
// Input parameters:
//   R1: Object (old)
//   R0: Value (old or new)
//  R25: Slot
// If R0 is new, add R1 to the store buffer. Otherwise R0 is old, mark R0
// and add it to the mark list.
COMPILE_ASSERT(kWriteBarrierObjectReg == R1);
COMPILE_ASSERT(kWriteBarrierValueReg == R0);
COMPILE_ASSERT(kWriteBarrierSlotReg == R25);
static void GenerateWriteBarrierStubHelper(Assembler* assembler,
                                           Address stub_code,
                                           bool cards) {
  Label add_to_mark_stack, remember_card;
  __ tbz(&add_to_mark_stack, R0,
         target::ObjectAlignment::kNewObjectBitPosition);

  if (cards) {
    __ LoadFieldFromOffset(TMP, R1, target::Object::tags_offset(), kFourBytes);
    __ tbnz(&remember_card, TMP, target::ObjectLayout::kCardRememberedBit);
  } else {
#if defined(DEBUG)
    Label ok;
    __ LoadFieldFromOffset(TMP, R1, target::Object::tags_offset(), kFourBytes);
    __ tbz(&ok, TMP, target::ObjectLayout::kCardRememberedBit);
    __ Stop("Wrong barrier");
    __ Bind(&ok);
#endif
  }

  // Save values being destroyed.
  __ Push(R2);
  __ Push(R3);
  __ Push(R4);

  // Atomically set the remembered bit of the object header.
  ASSERT(target::Object::tags_offset() == 0);
  __ sub(R3, R1, Operand(kHeapObjectTag));
  // R3: Untagged address of header word (ldxr/stxr do not support offsets).
  Label retry;
  __ Bind(&retry);
  __ ldxr(R2, R3, kEightBytes);
  __ AndImmediate(R2, R2,
                  ~(1 << target::ObjectLayout::kOldAndNotRememberedBit));
  __ stxr(R4, R2, R3, kEightBytes);
  __ cbnz(&retry, R4);

  // Load the StoreBuffer block out of the thread. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  __ LoadFromOffset(R4, THR, target::Thread::store_buffer_block_offset());
  __ LoadFromOffset(R2, R4, target::StoreBufferBlock::top_offset(),
                    kUnsignedFourBytes);
  __ add(R3, R4, Operand(R2, LSL, target::kWordSizeLog2));
  __ StoreToOffset(R1, R3, target::StoreBufferBlock::pointers_offset());

  // Increment top_ and check for overflow.
  // R2: top_.
  // R4: StoreBufferBlock.
  Label overflow;
  __ add(R2, R2, Operand(1));
  __ StoreToOffset(R2, R4, target::StoreBufferBlock::top_offset(),
                   kUnsignedFourBytes);
  __ CompareImmediate(R2, target::StoreBufferBlock::kSize);
  // Restore values.
  __ Pop(R4);
  __ Pop(R3);
  __ Pop(R2);
  __ b(&overflow, EQ);
  __ ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&overflow);
  {
    Assembler::CallRuntimeScope scope(assembler,
                                      kStoreBufferBlockProcessRuntimeEntry,
                                      /*frame_size=*/0, stub_code);
    __ mov(R0, THR);
    scope.Call(/*argument_count=*/1);
  }
  __ ret();

  __ Bind(&add_to_mark_stack);
  __ Push(R2);  // Spill.
  __ Push(R3);  // Spill.
  __ Push(R4);  // Spill.

  // Atomically clear kOldAndNotMarkedBit.
  Label marking_retry, lost_race, marking_overflow;
  ASSERT(target::Object::tags_offset() == 0);
  __ sub(R3, R0, Operand(kHeapObjectTag));
  // R3: Untagged address of header word (ldxr/stxr do not support offsets).
  __ Bind(&marking_retry);
  __ ldxr(R2, R3, kEightBytes);
  __ tbz(&lost_race, R2, target::ObjectLayout::kOldAndNotMarkedBit);
  __ AndImmediate(R2, R2, ~(1 << target::ObjectLayout::kOldAndNotMarkedBit));
  __ stxr(R4, R2, R3, kEightBytes);
  __ cbnz(&marking_retry, R4);

  __ LoadFromOffset(R4, THR, target::Thread::marking_stack_block_offset());
  __ LoadFromOffset(R2, R4, target::MarkingStackBlock::top_offset(),
                    kUnsignedFourBytes);
  __ add(R3, R4, Operand(R2, LSL, target::kWordSizeLog2));
  __ StoreToOffset(R0, R3, target::MarkingStackBlock::pointers_offset());
  __ add(R2, R2, Operand(1));
  __ StoreToOffset(R2, R4, target::MarkingStackBlock::top_offset(),
                   kUnsignedFourBytes);
  __ CompareImmediate(R2, target::MarkingStackBlock::kSize);
  __ Pop(R4);  // Unspill.
  __ Pop(R3);  // Unspill.
  __ Pop(R2);  // Unspill.
  __ b(&marking_overflow, EQ);
  __ ret();

  __ Bind(&marking_overflow);
  {
    Assembler::CallRuntimeScope scope(assembler,
                                      kMarkingStackBlockProcessRuntimeEntry,
                                      /*frame_size=*/0, stub_code);
    __ mov(R0, THR);
    scope.Call(/*argument_count=*/1);
  }
  __ ret();

  __ Bind(&lost_race);
  __ Pop(R4);  // Unspill.
  __ Pop(R3);  // Unspill.
  __ Pop(R2);  // Unspill.
  __ ret();

  if (cards) {
    Label remember_card_slow;

    // Get card table.
    __ Bind(&remember_card);
    __ AndImmediate(TMP, R1, target::kOldPageMask);  // OldPage.
    __ ldr(TMP,
           Address(TMP, target::OldPage::card_table_offset()));  // Card table.
    __ cbz(&remember_card_slow, TMP);

    // Dirty the card.
    __ AndImmediate(TMP, R1, target::kOldPageMask);  // OldPage.
    __ sub(R25, R25, Operand(TMP));                  // Offset in page.
    __ ldr(TMP,
           Address(TMP, target::OldPage::card_table_offset()));  // Card table.
    __ add(TMP, TMP,
           Operand(R25, LSR,
                   target::OldPage::kBytesPerCardLog2));  // Card address.
    __ str(R1, Address(TMP, 0),
           kUnsignedByte);  // Low byte of R1 is non-zero from object tag.
    __ ret();

    // Card table not yet allocated.
    __ Bind(&remember_card_slow);
    {
      Assembler::CallRuntimeScope scope(assembler, kRememberCardRuntimeEntry,
                                        /*frame_size=*/0, stub_code);
      __ mov(R0, R1);   // Arg0 = Object
      __ mov(R1, R25);  // Arg1 = Slot
      scope.Call(/*argument_count=*/2);
    }
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
  const Register kInstanceReg = R0;
  // kAllocationStubTypeArgumentsReg = R1
  const Register kTagsReg = R2;

  {
    Label slow_case;

    const Register kNewTopReg = R3;

    // Bump allocation.
    {
      const Register kInstanceSizeReg = R4;
      const Register kEndReg = R5;

      __ ExtractInstanceSizeFromTags(kInstanceSizeReg, kTagsReg);

      // Load two words from Thread::top: top and end.
      // kInstanceReg: potential next object start.
      __ ldp(kInstanceReg, kEndReg,
             Address(THR, target::Thread::top_offset(), Address::PairOffset));

      __ add(kNewTopReg, kInstanceReg, Operand(kInstanceSizeReg));

      __ CompareRegisters(kEndReg, kNewTopReg);
      __ b(&slow_case, UNSIGNED_LESS_EQUAL);

      // Successfully allocated the object, now update top to point to
      // next object start and store the class in the class field of object.
      __ str(kNewTopReg, Address(THR, target::Thread::top_offset()));
    }  // kInstanceSizeReg = R4, kEndReg = R5

    // Tags.
    __ str(kTagsReg, Address(kInstanceReg, target::Object::tags_offset()));

    // Initialize the remaining words of the object.
    {
      const Register kFieldReg = R4;

      __ AddImmediate(kFieldReg, kInstanceReg,
                      target::Instance::first_field_offset());
      Label done, init_loop;
      __ Bind(&init_loop);
      __ CompareRegisters(kFieldReg, kNewTopReg);
      __ b(&done, UNSIGNED_GREATER_EQUAL);
      __ str(NULL_REG,
             Address(kFieldReg, target::kWordSize, Address::PostIndex));
      __ b(&init_loop);

      __ Bind(&done);
    }  // kFieldReg = R4

    if (is_cls_parameterized) {
      Label not_parameterized_case;

      const Register kClsIdReg = R4;
      const Register kTypeOffestReg = R5;

      __ ExtractClassIdFromTags(kClsIdReg, kTagsReg);

      // Load class' type_arguments_field offset in words.
      __ LoadClassById(kTypeOffestReg, kClsIdReg);
      __ ldr(
          kTypeOffestReg,
          FieldAddress(kTypeOffestReg,
                       target::Class::
                           host_type_arguments_field_offset_in_words_offset()),
          kFourBytes);

      // Set the type arguments in the new object.
      __ StoreIntoObjectNoBarrier(
          kInstanceReg,
          Address(kInstanceReg, kTypeOffestReg, UXTX, Address::Scaled),
          kAllocationStubTypeArgumentsReg);

      __ Bind(&not_parameterized_case);
    }  // kClsIdReg = R4, kTypeOffestReg = R5

    __ AddImmediate(kInstanceReg, kInstanceReg, kHeapObjectTag);

    __ ret();

    __ Bind(&slow_case);
  }  // kNewTopReg = R3

  // Fall back on slow case:
  if (!is_cls_parameterized) {
    __ mov(kAllocationStubTypeArgumentsReg, NULL_REG);
  }
  // Tail call to generic allocation stub.
  __ ldr(
      R3,
      Address(THR, target::Thread::allocate_object_slow_entry_point_offset()));
  __ br(R3);
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
  const Register kInstanceReg = R0;
  // kAllocationStubTypeArgumentsReg = R1
  const Register kTagsToClsIdReg = R2;

  if (!FLAG_use_bare_instructions) {
    __ ldr(CODE_REG,
           Address(THR, target::Thread::call_to_runtime_stub_offset()));
  }

  __ ExtractClassIdFromTags(kTagsToClsIdReg, kTagsToClsIdReg);

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();

  __ LoadClassById(R0, kTagsToClsIdReg);
  __ PushPair(R0, NULL_REG);  // Pushes result slot, then class object.

  // Should be Object::null() if class is non-parameterized.
  __ Push(kAllocationStubTypeArgumentsReg);

  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);

  // Load result off the stack into result register.
  __ ldr(kInstanceReg, Address(SP, 2 * target::kWordSize));

  // Write-barrier elimination is enabled for [cls] and we therefore need to
  // ensure that the object is in new-space or has remembered bit set.
  EnsureIsNewOrRemembered(assembler, /*preserve_registers=*/false);

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
  static_assert(kAllocationStubTypeArgumentsReg == R1,
                "Adjust register allocation in the AllocationStub");

  classid_t cls_id = target::Class::GetId(cls);
  ASSERT(cls_id != kIllegalCid);

  RELEASE_ASSERT(AllocateObjectInstr::WillAllocateNewOrRemembered(cls));

  // The generated code is different if the class is parameterized.
  const bool is_cls_parameterized = target::Class::NumTypeArguments(cls) > 0;
  ASSERT(!is_cls_parameterized || target::Class::TypeArgumentsFieldOffset(
                                      cls) != target::Class::kNoTypeArguments);

  const intptr_t instance_size = target::Class::GetInstanceSize(cls);
  ASSERT(instance_size > 0);
  RELEASE_ASSERT(target::Heap::IsAllocatableInNewSpace(instance_size));

  const uword tags =
      target::MakeTagWordForNewSpaceObject(cls_id, instance_size);

  // Note: Keep in sync with helper function.
  // kInstanceReg = R0
  // kAllocationStubTypeArgumentsReg = R1
  const Register kTagsReg = R2;

  __ LoadImmediate(kTagsReg, tags);

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
        __ ldr(R4,
               Address(THR,
                       target::Thread::
                           allocate_object_parameterized_entry_point_offset()));
        __ br(R4);
      }
    } else {
      // TODO(41974): Assign all allocation stubs to the root loading unit?
      if (false &&
          !IsSameObject(NullObject(), CastHandle<Object>(allocate_object))) {
        __ GenerateUnRelocatedPcRelativeTailCall();
        unresolved_calls->Add(new UnresolvedPcRelativeCall(
            __ CodeSize(), allocate_object, /*is_tail_call=*/true));
      } else {
        __ ldr(
            R4,
            Address(THR, target::Thread::allocate_object_entry_point_offset()));
        __ br(R4);
      }
    }
  } else {
    if (!is_cls_parameterized) {
      __ LoadObject(kAllocationStubTypeArgumentsReg, NullObject());
    }
    __ ldr(R4,
           Address(THR,
                   target::Thread::allocate_object_slow_entry_point_offset()));
    __ br(R4);
  }
}

// Called for invoking "dynamic noSuchMethod(Invocation invocation)" function
// from the entry code of a dart function after an error in passed argument
// name or number is detected.
// Input parameters:
//  LR : return address.
//  SP : address of last argument.
//  R4: arguments descriptor array.
void StubCodeCompiler::GenerateCallClosureNoSuchMethodStub(
    Assembler* assembler) {
  __ EnterStubFrame();

  // Load the receiver.
  __ LoadFieldFromOffset(R2, R4, target::ArgumentsDescriptor::size_offset());
  __ add(TMP, FP, Operand(R2, LSL, 2));  // R2 is Smi.
  __ LoadFromOffset(R6, TMP,
                    target::frame_layout.param_end_from_fp * target::kWordSize);

  // Load the function.
  __ LoadFieldFromOffset(TMP, R6, target::Closure::function_offset());

  __ Push(ZR);   // Result slot.
  __ Push(R6);   // Receiver.
  __ Push(TMP);  // Function
  __ Push(R4);   // Arguments descriptor.

  // Adjust arguments count.
  __ LoadFieldFromOffset(R3, R4,
                         target::ArgumentsDescriptor::type_args_len_offset());
  __ AddImmediate(TMP, R2, 1);  // Include the type arguments.
  __ cmp(R3, Operand(0));
  __ csinc(R2, R2, TMP, EQ);  // R2 <- (R3 == 0) ? R2 : TMP + 1 (R2 : R2 + 2).

  // R2: Smi-tagged arguments array length.
  PushArrayOfArguments(assembler);

  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromPrologueRuntimeEntry, kNumArgs);
  // noSuchMethod on closures always throws an error, so it will never return.
  __ brk(0);
}

//  R6: function object.
//  R5: inline cache data object.
// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCodeCompiler::GenerateOptimizedUsageCounterIncrement(
    Assembler* assembler) {
  Register ic_reg = R5;
  Register func_reg = R6;
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }
  if (FLAG_trace_optimized_ic_calls) {
    __ EnterStubFrame();
    __ Push(R6);        // Preserve.
    __ Push(R5);        // Preserve.
    __ Push(ic_reg);    // Argument.
    __ Push(func_reg);  // Argument.
    __ CallRuntime(kTraceICCallRuntimeEntry, 2);
    __ Drop(2);  // Discard argument;
    __ Pop(R5);  // Restore.
    __ Pop(R6);  // Restore.
    __ LeaveStubFrame();
  }
  __ LoadFieldFromOffset(R7, func_reg, target::Function::usage_counter_offset(),
                         kFourBytes);
  __ add(R7, R7, Operand(1));
  __ StoreFieldToOffset(R7, func_reg, target::Function::usage_counter_offset(),
                        kFourBytes);
}

// Loads function into 'temp_reg'.
void StubCodeCompiler::GenerateUsageCounterIncrement(Assembler* assembler,
                                                     Register temp_reg) {
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }
  if (FLAG_optimization_counter_threshold >= 0) {
    Register ic_reg = R5;
    Register func_reg = temp_reg;
    ASSERT(temp_reg == R6);
    __ Comment("Increment function counter");
    __ LoadFieldFromOffset(func_reg, ic_reg, target::ICData::owner_offset());
    __ LoadFieldFromOffset(
        R7, func_reg, target::Function::usage_counter_offset(), kFourBytes);
    __ AddImmediate(R7, 1);
    __ StoreFieldToOffset(R7, func_reg,
                          target::Function::usage_counter_offset(), kFourBytes);
  }
}

// Note: R5 must be preserved.
// Attempt a quick Smi operation for known operations ('kind'). The ICData
// must have been primed with a Smi/Smi check that will be used for counting
// the invocations.
static void EmitFastSmiOp(Assembler* assembler,
                          Token::Kind kind,
                          intptr_t num_args,
                          Label* not_smi_or_overflow) {
  __ Comment("Fast Smi op");
  __ ldr(R0, Address(SP, +1 * target::kWordSize));  // Left.
  __ ldr(R1, Address(SP, +0 * target::kWordSize));  // Right.
  __ orr(TMP, R0, Operand(R1));
  __ BranchIfNotSmi(TMP, not_smi_or_overflow);
  switch (kind) {
    case Token::kADD: {
      __ adds(R0, R1, Operand(R0));   // Adds.
      __ b(not_smi_or_overflow, VS);  // Branch if overflow.
      break;
    }
    case Token::kLT: {
      __ CompareRegisters(R0, R1);
      __ LoadObject(R0, CastHandle<Object>(TrueObject()));
      __ LoadObject(R1, CastHandle<Object>(FalseObject()));
      __ csel(R0, R0, R1, LT);
      break;
    }
    case Token::kEQ: {
      __ CompareRegisters(R0, R1);
      __ LoadObject(R0, CastHandle<Object>(TrueObject()));
      __ LoadObject(R1, CastHandle<Object>(FalseObject()));
      __ csel(R0, R0, R1, EQ);
      break;
    }
    default:
      UNIMPLEMENTED();
  }

  // R5: IC data object (preserved).
  __ LoadFieldFromOffset(R6, R5, target::ICData::entries_offset());
  // R6: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(R6, target::Array::data_offset() - kHeapObjectTag);
// R6: points directly to the first ic data array element.
#if defined(DEBUG)
  // Check that first entry is for Smi/Smi.
  Label error, ok;
  const intptr_t imm_smi_cid = target::ToRawSmi(kSmiCid);
  __ ldr(R1, Address(R6, 0));
  __ CompareImmediate(R1, imm_smi_cid);
  __ b(&error, NE);
  __ ldr(R1, Address(R6, target::kWordSize));
  __ CompareImmediate(R1, imm_smi_cid);
  __ b(&ok, EQ);
  __ Bind(&error);
  __ Stop("Incorrect IC data");
  __ Bind(&ok);
#endif
  if (FLAG_optimization_counter_threshold >= 0) {
    const intptr_t count_offset =
        target::ICData::CountIndexFor(num_args) * target::kWordSize;
    // Update counter, ignore overflow.
    __ LoadFromOffset(R1, R6, count_offset);
    __ adds(R1, R1, Operand(target::ToRawSmi(1)));
    __ StoreToOffset(R1, R6, count_offset);
  }

  __ ret();
}

// Saves the offset of the target entry-point (from the Function) into R8.
//
// Must be the first code generated, since any code before will be skipped in
// the unchecked entry-point.
static void GenerateRecordEntryPoint(Assembler* assembler) {
  Label done;
  __ LoadImmediate(R8, target::Function::entry_point_offset() - kHeapObjectTag);
  __ b(&done);
  __ BindUncheckedEntryPoint();
  __ LoadImmediate(
      R8, target::Function::entry_point_offset(CodeEntryKind::kUnchecked) -
              kHeapObjectTag);
  __ Bind(&done);
}

// Generate inline cache check for 'num_args'.
//  R0: receiver (if instance call)
//  R5: ICData
//  LR: return address
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
  const bool save_entry_point = kind == Token::kILLEGAL;
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }

  if (save_entry_point) {
    GenerateRecordEntryPoint(assembler);
  }

  if (optimized == kOptimized) {
    GenerateOptimizedUsageCounterIncrement(assembler);
  } else {
    GenerateUsageCounterIncrement(assembler, /*scratch=*/R6);
  }

  ASSERT(exactness == kIgnoreExactness);  // Unimplemented.
  ASSERT(num_args == 1 || num_args == 2);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ LoadFromOffset(R6, R5,
                      target::ICData::state_bits_offset() - kHeapObjectTag,
                      kUnsignedFourBytes);
    ASSERT(target::ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andi(R6, R6, Immediate(target::ICData::NumArgsTestedMask()));
    __ CompareImmediate(R6, num_args);
    __ b(&ok, EQ);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

#if !defined(PRODUCT)
  Label stepping, done_stepping;
  if (optimized == kUnoptimized) {
    __ Comment("Check single stepping");
    __ LoadIsolate(R6);
    __ LoadFromOffset(R6, R6, target::Isolate::single_step_offset(),
                      kUnsignedByte);
    __ CompareRegisters(R6, ZR);
    __ b(&stepping, NE);
    __ Bind(&done_stepping);
  }
#endif

  Label not_smi_or_overflow;
  if (kind != Token::kILLEGAL) {
    EmitFastSmiOp(assembler, kind, num_args, &not_smi_or_overflow);
  }
  __ Bind(&not_smi_or_overflow);

  __ Comment("Extract ICData initial values and receiver cid");
  // R5: IC data object (preserved).
  __ LoadFieldFromOffset(R6, R5, target::ICData::entries_offset());
  // R6: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(R6, target::Array::data_offset() - kHeapObjectTag);
  // R6: points directly to the first ic data array element.

  if (type == kInstanceCall) {
    __ LoadTaggedClassIdMayBeSmi(R0, R0);
    __ LoadFieldFromOffset(R4, R5,
                           target::CallSiteData::arguments_descriptor_offset());
    if (num_args == 2) {
      __ LoadFieldFromOffset(R7, R4,
                             target::ArgumentsDescriptor::count_offset());
      __ SmiUntag(R7);  // Untag so we can use the LSL 3 addressing mode.
      __ sub(R7, R7, Operand(2));
      // R1 <- [SP + (R1 << 3)]
      __ ldr(R1, Address(SP, R7, UXTX, Address::Scaled));
      __ LoadTaggedClassIdMayBeSmi(R1, R1);
    }
  } else {
    __ LoadFieldFromOffset(R4, R5,
                           target::CallSiteData::arguments_descriptor_offset());
    // Get the receiver's class ID (first read number of arguments from
    // arguments descriptor array and then access the receiver from the stack).
    __ LoadFieldFromOffset(R7, R4, target::ArgumentsDescriptor::count_offset());
    __ SmiUntag(R7);  // Untag so we can use the LSL 3 addressing mode.
    __ sub(R7, R7, Operand(1));
    // R0 <- [SP + (R7 << 3)]
    __ ldr(R0, Address(SP, R7, UXTX, Address::Scaled));
    __ LoadTaggedClassIdMayBeSmi(R0, R0);
    if (num_args == 2) {
      __ AddImmediate(R1, R7, -1);
      // R1 <- [SP + (R1 << 3)]
      __ ldr(R1, Address(SP, R1, UXTX, Address::Scaled));
      __ LoadTaggedClassIdMayBeSmi(R1, R1);
    }
  }
  // R0: first argument class ID as Smi.
  // R1: second argument class ID as Smi.
  // R4: args descriptor

  // We unroll the generic one that is generated once more than the others.
  const bool optimize = kind == Token::kILLEGAL;

  // Loop that checks if there is an IC data match.
  Label loop, found, miss;
  __ Comment("ICData loop");

  __ Bind(&loop);
  for (int unroll = optimize ? 4 : 2; unroll >= 0; unroll--) {
    Label update;

    __ LoadFromOffset(R2, R6, 0);
    __ CompareRegisters(R0, R2);  // Class id match?
    if (num_args == 2) {
      __ b(&update, NE);  // Continue.
      __ LoadFromOffset(R2, R6, target::kWordSize);
      __ CompareRegisters(R1, R2);  // Class id match?
    }
    __ b(&found, EQ);  // Break.

    __ Bind(&update);

    const intptr_t entry_size = target::ICData::TestEntryLengthFor(
                                    num_args, exactness == kCheckExactness) *
                                target::kWordSize;
    __ AddImmediate(R6, entry_size);  // Next entry.

    __ CompareImmediate(R2, target::ToRawSmi(kIllegalCid));  // Done?
    if (unroll == 0) {
      __ b(&loop, NE);
    } else {
      __ b(&miss, EQ);
    }
  }

  __ Bind(&miss);
  __ Comment("IC miss");

  // Compute address of arguments.
  __ LoadFieldFromOffset(R7, R4, target::ArgumentsDescriptor::count_offset());
  __ SmiUntag(R7);  // Untag so we can use the LSL 3 addressing mode.
  __ sub(R7, R7, Operand(1));
  // R7: argument_count - 1 (untagged).
  // R7 <- SP + (R7 << 3)
  __ add(R7, SP, Operand(R7, UXTX, 3));  // R7 is Untagged.
  // R7: address of receiver.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Preserve IC data object and arguments descriptor array and
  // setup space on stack for result (target code object).
  __ Push(R4);  // Preserve arguments descriptor array.
  __ Push(R5);  // Preserve IC Data.
  if (save_entry_point) {
    __ SmiTag(R8);
    __ Push(R8);
  }
  // Setup space on stack for the result (target code object).
  __ Push(ZR);
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ LoadFromOffset(TMP, R7, -i * target::kWordSize);
    __ Push(TMP);
  }
  // Pass IC data object.
  __ Push(R5);
  __ CallRuntime(handle_ic_miss, num_args + 1);
  // Remove the call arguments pushed earlier, including the IC data object.
  __ Drop(num_args + 1);
  // Pop returned function object into R0.
  // Restore arguments descriptor array and IC data array.
  __ Pop(R0);  // Pop returned function object into R0.
  if (save_entry_point) {
    __ Pop(R8);
    __ SmiUntag(R8);
  }
  __ Pop(R5);  // Restore IC Data.
  __ Pop(R4);  // Restore arguments descriptor array.
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  Label call_target_function;
  if (!FLAG_lazy_dispatchers) {
    GenerateDispatcherCode(assembler, &call_target_function);
  } else {
    __ b(&call_target_function);
  }

  __ Bind(&found);
  __ Comment("Update caller's counter");
  // R6: pointer to an IC data check group.
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(num_args) * target::kWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(num_args) * target::kWordSize;
  __ LoadFromOffset(R0, R6, target_offset);

  if (FLAG_optimization_counter_threshold >= 0) {
    // Update counter, ignore overflow.
    __ LoadFromOffset(R1, R6, count_offset);
    __ adds(R1, R1, Operand(target::ToRawSmi(1)));
    __ StoreToOffset(R1, R6, count_offset);
  }

  __ Comment("Call target");
  __ Bind(&call_target_function);
  // R0: target function.
  __ LoadFieldFromOffset(CODE_REG, R0, target::Function::code_offset());
  if (save_entry_point) {
    __ add(R2, R0, Operand(R8));
    __ ldr(R2, Address(R2, 0));
  } else {
    __ LoadFieldFromOffset(R2, R0, target::Function::entry_point_offset());
  }
  __ br(R2);

#if !defined(PRODUCT)
  if (optimized == kUnoptimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    if (type == kInstanceCall) {
      __ Push(R0);  // Preserve receiver.
    }
    if (save_entry_point) {
      __ SmiTag(R8);
      __ Push(R8);
    }
    __ Push(R5);  // Preserve IC data.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ Pop(R5);
    if (save_entry_point) {
      __ Pop(R8);
      __ SmiUntag(R8);
    }
    if (type == kInstanceCall) {
      __ Pop(R0);
    }
    __ RestoreCodePointer();
    __ LeaveStubFrame();
    __ b(&done_stepping);
  }
#endif
}

// R0: receiver
// R5: ICData
// LR: return address
void StubCodeCompiler::GenerateOneArgCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

// R0: receiver
// R5: ICData
// LR: return address
void StubCodeCompiler::GenerateOneArgCheckInlineCacheWithExactnessCheckStub(
    Assembler* assembler) {
  __ Stop("Unimplemented");
}

// R0: receiver
// R5: ICData
// LR: return address
void StubCodeCompiler::GenerateTwoArgsCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

// R0: receiver
// R5: ICData
// LR: return address
void StubCodeCompiler::GenerateSmiAddInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kADD,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

// R0: receiver
// R5: ICData
// LR: return address
void StubCodeCompiler::GenerateSmiLessInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kLT,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

// R0: receiver
// R5: ICData
// LR: return address
void StubCodeCompiler::GenerateSmiEqualInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

// R0: receiver
// R5: ICData
// R6: Function
// LR: return address
void StubCodeCompiler::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kIgnoreExactness);
}

// R0: receiver
// R5: ICData
// R6: Function
// LR: return address
void StubCodeCompiler::
    GenerateOneArgOptimizedCheckInlineCacheWithExactnessCheckStub(
        Assembler* assembler) {
  __ Stop("Unimplemented");
}

// R0: receiver
// R5: ICData
// R6: Function
// LR: return address
void StubCodeCompiler::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kIgnoreExactness);
}

// R5: ICData
// LR: return address
void StubCodeCompiler::GenerateZeroArgsUnoptimizedStaticCallStub(
    Assembler* assembler) {
  GenerateRecordEntryPoint(assembler);
  GenerateUsageCounterIncrement(assembler, /* scratch */ R6);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == 0.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ LoadFromOffset(R6, R5,
                      target::ICData::state_bits_offset() - kHeapObjectTag,
                      kUnsignedFourBytes);
    ASSERT(target::ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andi(R6, R6, Immediate(target::ICData::NumArgsTestedMask()));
    __ CompareImmediate(R6, 0);
    __ b(&ok, EQ);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Check single stepping.
#if !defined(PRODUCT)
  Label stepping, done_stepping;
  __ LoadIsolate(R6);
  __ LoadFromOffset(R6, R6, target::Isolate::single_step_offset(),
                    kUnsignedByte);
  __ CompareImmediate(R6, 0);
  __ b(&stepping, NE);
  __ Bind(&done_stepping);
#endif

  // R5: IC data object (preserved).
  __ LoadFieldFromOffset(R6, R5, target::ICData::entries_offset());
  // R6: ic_data_array with entries: target functions and count.
  __ AddImmediate(R6, target::Array::data_offset() - kHeapObjectTag);
  // R6: points directly to the first ic data array element.
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(0) * target::kWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(0) * target::kWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    // Increment count for this call, ignore overflow.
    __ LoadFromOffset(R1, R6, count_offset);
    __ adds(R1, R1, Operand(target::ToRawSmi(1)));
    __ StoreToOffset(R1, R6, count_offset);
  }

  // Load arguments descriptor into R4.
  __ LoadFieldFromOffset(R4, R5,
                         target::CallSiteData::arguments_descriptor_offset());

  // Get function and call it, if possible.
  __ LoadFromOffset(R0, R6, target_offset);
  __ LoadFieldFromOffset(CODE_REG, R0, target::Function::code_offset());
  __ add(R2, R0, Operand(R8));
  __ ldr(R2, Address(R2, 0));
  __ br(R2);

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ Push(R5);  // Preserve IC data.
  __ SmiTag(R8);
  __ Push(R8);
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ Pop(R8);
  __ SmiUntag(R8);
  __ Pop(R5);
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ b(&done_stepping);
#endif
}

// R5: ICData
// LR: return address
void StubCodeCompiler::GenerateOneArgUnoptimizedStaticCallStub(
    Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, /* scratch */ R6);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kStaticCallMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kStaticCall, kIgnoreExactness);
}

// R5: ICData
// LR: return address
void StubCodeCompiler::GenerateTwoArgsUnoptimizedStaticCallStub(
    Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, /* scratch */ R6);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kStaticCall, kIgnoreExactness);
}

// Stub for compiling a function and jumping to the compiled code.
// R4: Arguments descriptor.
// R0: Function.
void StubCodeCompiler::GenerateLazyCompileStub(Assembler* assembler) {
  // Preserve arg desc.
  __ EnterStubFrame();
  __ Push(R4);  // Save arg. desc.
  __ Push(R0);  // Pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ Pop(R0);  // Restore argument.
  __ Pop(R4);  // Restore arg desc.
  __ LeaveStubFrame();

  __ LoadFieldFromOffset(CODE_REG, R0, target::Function::code_offset());
  __ LoadFieldFromOffset(R2, R0, target::Function::entry_point_offset());
  __ br(R2);
}

// R5: Contains an ICData.
void StubCodeCompiler::GenerateICCallBreakpointStub(Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ Push(R0);  // Preserve receiver.
  __ Push(R5);  // Preserve IC data.
  __ Push(ZR);  // Space for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ Pop(CODE_REG);  // Original stub.
  __ Pop(R5);        // Restore IC data.
  __ Pop(R0);        // Restore receiver.
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ br(TMP);
#endif  // defined(PRODUCT)
}

void StubCodeCompiler::GenerateUnoptStaticCallBreakpointStub(
    Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ Push(R5);  // Preserve IC data.
  __ Push(ZR);  // Space for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ Pop(CODE_REG);  // Original stub.
  __ Pop(R5);        // Restore IC data.
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ br(TMP);
#endif  // defined(PRODUCT)
}

void StubCodeCompiler::GenerateRuntimeCallBreakpointStub(Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ Push(ZR);  // Space for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ Pop(CODE_REG);
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(R0, CODE_REG, target::Code::entry_point_offset());
  __ br(R0);
#endif  // defined(PRODUCT)
}

// Called only from unoptimized code. All relevant registers have been saved.
void StubCodeCompiler::GenerateDebugStepCheckStub(Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(R1);
  __ LoadFromOffset(R1, R1, target::Isolate::single_step_offset(),
                    kUnsignedByte);
  __ CompareImmediate(R1, 0);
  __ b(&stepping, NE);
  __ Bind(&done_stepping);
  __ ret();

  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ b(&done_stepping);
#endif  // defined(PRODUCT)
}

// Used to check class and type arguments. Arguments passed in registers:
//
// Inputs (mostly from TypeTestABI struct):
//   - kSubtypeTestCacheReg: SubtypeTestCacheLayout
//   - kInstanceReg: instance to test against.
//   - kDstTypeReg: destination type (for n>=3).
//   - kInstantiatorTypeArgumentsReg: instantiator type arguments (for n=5).
//   - kFunctionTypeArgumentsReg: function type arguments (for n=5).
//   - LR: return address.
//
// All input registers are preserved except for kSubtypeTestCacheReg, which
// should be saved by the caller if needed.
//
// Result in SubtypeTestCacheABI::kResultReg: null -> not found, otherwise
// result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  ASSERT(n == 1 || n == 3 || n == 5 || n == 7);

  // Until we have the result, we use the result register to store the null
  // value for quick access. This has the side benefit of initializing the
  // result to null, so it only needs to be changed if found.
  const Register kNullReg = TypeTestABI::kSubtypeTestCacheResultReg;
  __ LoadObject(kNullReg, NullObject());

  const Register kCacheArrayReg = TypeTestABI::kSubtypeTestCacheReg;
  const Register kScratchReg = TypeTestABI::kScratchReg;

  // All of these must be distinct from TypeTestABI::kSubtypeTestCacheResultReg
  // since it is used for kNullReg as well.

  // Loop initialization (moved up here to avoid having all dependent loads
  // after each other).

  // We avoid a load-acquire barrier here by relying on the fact that all other
  // loads from the array are data-dependent loads.
  __ ldr(kCacheArrayReg,
         FieldAddress(TypeTestABI::kSubtypeTestCacheReg,
                      target::SubtypeTestCache::cache_offset()));
  __ AddImmediate(kCacheArrayReg,
                  target::Array::data_offset() - kHeapObjectTag);

  Label loop, not_closure;
  if (n >= 5) {
    __ LoadClassIdMayBeSmi(STCInternalRegs::kInstanceCidOrFunctionReg,
                           TypeTestABI::TypeTestABI::kInstanceReg);
  } else {
    __ LoadClassId(STCInternalRegs::kInstanceCidOrFunctionReg,
                   TypeTestABI::kInstanceReg);
  }
  __ CompareImmediate(STCInternalRegs::kInstanceCidOrFunctionReg, kClosureCid);
  __ b(&not_closure, NE);

  // Closure handling.
  {
    __ ldr(STCInternalRegs::kInstanceCidOrFunctionReg,
           FieldAddress(TypeTestABI::kInstanceReg,
                        target::Closure::function_offset()));
    if (n >= 3) {
      __ ldr(
          STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg,
          FieldAddress(TypeTestABI::kInstanceReg,
                       target::Closure::instantiator_type_arguments_offset()));
      if (n >= 7) {
        __ ldr(STCInternalRegs::kInstanceParentFunctionTypeArgumentsReg,
               FieldAddress(TypeTestABI::kInstanceReg,
                            target::Closure::function_type_arguments_offset()));
        __ ldr(STCInternalRegs::kInstanceDelayedFunctionTypeArgumentsReg,
               FieldAddress(TypeTestABI::kInstanceReg,
                            target::Closure::delayed_type_arguments_offset()));
      }
    }
    __ b(&loop);
  }

  // Non-Closure handling.
  {
    __ Bind(&not_closure);
    if (n >= 3) {
      Label has_no_type_arguments;
      __ LoadClassById(kScratchReg, STCInternalRegs::kInstanceCidOrFunctionReg);
      __ mov(STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg, kNullReg);
      __ LoadFieldFromOffset(
          kScratchReg, kScratchReg,
          target::Class::host_type_arguments_field_offset_in_words_offset(),
          kFourBytes);
      __ CompareImmediate(kScratchReg, target::Class::kNoTypeArguments);
      __ b(&has_no_type_arguments, EQ);
      __ add(kScratchReg, TypeTestABI::kInstanceReg,
             Operand(kScratchReg, LSL, 3));
      __ ldr(STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg,
             FieldAddress(kScratchReg, 0));
      __ Bind(&has_no_type_arguments);

      if (n >= 7) {
        __ mov(STCInternalRegs::kInstanceParentFunctionTypeArgumentsReg,
               kNullReg);
        __ mov(STCInternalRegs::kInstanceDelayedFunctionTypeArgumentsReg,
               kNullReg);
      }
    }
    __ SmiTag(STCInternalRegs::kInstanceCidOrFunctionReg);
  }

  Label found, done, next_iteration;

  // Loop header
  __ Bind(&loop);
  __ ldr(kScratchReg,
         Address(kCacheArrayReg,
                 target::kWordSize *
                     target::SubtypeTestCache::kInstanceClassIdOrFunction));
  __ cmp(kScratchReg, Operand(kNullReg));
  __ b(&done, EQ);
  __ cmp(kScratchReg, Operand(STCInternalRegs::kInstanceCidOrFunctionReg));
  if (n == 1) {
    __ b(&found, EQ);
  } else {
    __ b(&next_iteration, NE);
    __ ldr(kScratchReg,
           Address(
               kCacheArrayReg,
               target::kWordSize * target::SubtypeTestCache::kDestinationType));
    __ cmp(kScratchReg, Operand(TypeTestABI::kDstTypeReg));
    __ b(&next_iteration, NE);
    __ ldr(kScratchReg,
           Address(kCacheArrayReg,
                   target::kWordSize *
                       target::SubtypeTestCache::kInstanceTypeArguments));
    __ cmp(kScratchReg,
           Operand(STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg));
    if (n == 3) {
      __ b(&found, EQ);
    } else {
      __ b(&next_iteration, NE);
      __ ldr(kScratchReg,
             Address(kCacheArrayReg,
                     target::kWordSize *
                         target::SubtypeTestCache::kInstantiatorTypeArguments));
      __ cmp(kScratchReg, Operand(TypeTestABI::kInstantiatorTypeArgumentsReg));
      __ b(&next_iteration, NE);
      __ ldr(kScratchReg,
             Address(kCacheArrayReg,
                     target::kWordSize *
                         target::SubtypeTestCache::kFunctionTypeArguments));
      __ cmp(kScratchReg, Operand(TypeTestABI::kFunctionTypeArgumentsReg));
      if (n == 5) {
        __ b(&found, EQ);
      } else {
        ASSERT(n == 7);
        __ b(&next_iteration, NE);

        __ ldr(kScratchReg,
               Address(kCacheArrayReg,
                       target::kWordSize *
                           target::SubtypeTestCache::
                               kInstanceParentFunctionTypeArguments));
        __ cmp(
            kScratchReg,
            Operand(STCInternalRegs::kInstanceParentFunctionTypeArgumentsReg));
        __ b(&next_iteration, NE);

        __ ldr(kScratchReg,
               Address(kCacheArrayReg,
                       target::kWordSize *
                           target::SubtypeTestCache::
                               kInstanceDelayedFunctionTypeArguments));
        __ cmp(
            kScratchReg,
            Operand(STCInternalRegs::kInstanceDelayedFunctionTypeArgumentsReg));
        __ b(&found, EQ);
      }
    }
  }
  __ Bind(&next_iteration);
  __ AddImmediate(
      kCacheArrayReg,
      target::kWordSize * target::SubtypeTestCache::kTestEntryLength);
  __ b(&loop);

  __ Bind(&found);
  __ ldr(TypeTestABI::kSubtypeTestCacheResultReg,
         Address(kCacheArrayReg,
                 target::kWordSize * target::SubtypeTestCache::kTestResult));
  __ Bind(&done);
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

void StubCodeCompiler::GenerateGetCStackPointerStub(Assembler* assembler) {
  __ mov(R0, CSP);
  __ ret();
}

// Jump to a frame on the call stack.
// LR: return address.
// R0: program_counter.
// R1: stack_pointer.
// R2: frame_pointer.
// R3: thread.
// Does not return.
//
// Notice: We need to keep this in sync with `Simulator::JumpToFrame()`.
void StubCodeCompiler::GenerateJumpToFrameStub(Assembler* assembler) {
  ASSERT(kExceptionObjectReg == R0);
  ASSERT(kStackTraceObjectReg == R1);
  __ set_lr_state(compiler::LRState::Clobbered());
  __ mov(CALLEE_SAVED_TEMP, R0);  // Program counter.
  __ mov(SP, R1);                 // Stack pointer.
  __ mov(FP, R2);                 // Frame_pointer.
  __ mov(THR, R3);
  __ SetupCSPFromThread(THR);
#if defined(TARGET_OS_FUCHSIA)
  __ ldr(R18, Address(THR, target::Thread::saved_shadow_call_stack_offset()));
#elif defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif
  Label exit_through_non_ffi;
  Register tmp1 = R0, tmp2 = R1;
  // Check if we exited generated from FFI. If so do transition.
  __ LoadFromOffset(tmp1, THR,
                    compiler::target::Thread::exit_through_ffi_offset());
  __ LoadImmediate(tmp2, target::Thread::exit_through_ffi());
  __ cmp(tmp1, Operand(tmp2));
  __ b(&exit_through_non_ffi, NE);
  __ TransitionNativeToGenerated(tmp1, /*leave_safepoint=*/true);
  __ Bind(&exit_through_non_ffi);

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();
  // Set the tag.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(R2, THR, target::Thread::vm_tag_offset());
  // Clear top exit frame.
  __ StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());
  // Restore the pool pointer.
  __ RestoreCodePointer();
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ SetupGlobalPoolAndDispatchTable();
  } else {
    __ LoadPoolPointer();
  }
  __ ret(CALLEE_SAVED_TEMP);  // Jump to continuation point.
}

// Run an exception handler.  Execution comes from JumpToFrame
// stub or from the simulator.
//
// The arguments are stored in the Thread object.
// Does not return.
void StubCodeCompiler::GenerateRunExceptionHandlerStub(Assembler* assembler) {
  WRITES_RETURN_ADDRESS_TO_LR(
      __ LoadFromOffset(LR, THR, target::Thread::resume_pc_offset()));

  word offset_from_thread = 0;
  bool ok = target::CanLoadFromThread(NullObject(), &offset_from_thread);
  ASSERT(ok);
  __ LoadFromOffset(R2, THR, offset_from_thread);

  // Exception object.
  __ LoadFromOffset(R0, THR, target::Thread::active_exception_offset());
  __ StoreToOffset(R2, THR, target::Thread::active_exception_offset());

  // StackTrace object.
  __ LoadFromOffset(R1, THR, target::Thread::active_stacktrace_offset());
  __ StoreToOffset(R2, THR, target::Thread::active_stacktrace_offset());

  __ ret();  // Jump to the exception handler code.
}

// Deoptimize a frame on the call stack before rewinding.
// The arguments are stored in the Thread object.
// No result.
void StubCodeCompiler::GenerateDeoptForRewindStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ Push(TMP);

  // Load the deopt pc into LR.
  WRITES_RETURN_ADDRESS_TO_LR(
      __ LoadFromOffset(LR, THR, target::Thread::resume_pc_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);

  // After we have deoptimized, jump to the correct frame.
  __ EnterStubFrame();
  __ CallRuntime(kRewindPostDeoptRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ brk(0);
}

// Calls to the runtime to optimize the given function.
// R6: function to be re-optimized.
// R4: argument descriptor (preserved).
void StubCodeCompiler::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ LoadFromOffset(CODE_REG, THR, target::Thread::optimize_stub_offset());
  __ EnterStubFrame();
  __ Push(R4);
  // Setup space on stack for the return value.
  __ Push(ZR);
  __ Push(R6);
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ Pop(R0);  // Discard argument.
  __ Pop(R0);  // Get Function object
  __ Pop(R4);  // Restore argument descriptor.
  __ LoadFieldFromOffset(CODE_REG, R0, target::Function::code_offset());
  __ LoadFieldFromOffset(R1, R0, target::Function::entry_point_offset());
  __ LeaveStubFrame();
  __ br(R1);
  __ brk(0);
}

// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// Left and right are pushed on stack.
// Return Zero condition flag set if equal.
// Note: A Mint cannot contain a value that would fit in Smi.
static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right) {
  Label reference_compare, done, check_mint;
  // If any of the arguments is Smi do reference compare.
  __ BranchIfSmi(left, &reference_compare);
  __ BranchIfSmi(right, &reference_compare);

  // Value compare for two doubles.
  __ CompareClassId(left, kDoubleCid);
  __ b(&check_mint, NE);
  __ CompareClassId(right, kDoubleCid);
  __ b(&done, NE);

  // Double values bitwise compare.
  __ LoadFieldFromOffset(left, left, target::Double::value_offset());
  __ LoadFieldFromOffset(right, right, target::Double::value_offset());
  __ b(&reference_compare);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid);
  __ b(&reference_compare, NE);
  __ CompareClassId(right, kMintCid);
  __ b(&done, NE);
  __ LoadFieldFromOffset(left, left, target::Mint::value_offset());
  __ LoadFieldFromOffset(right, right, target::Mint::value_offset());

  __ Bind(&reference_compare);
  __ CompareRegisters(left, right);
  __ Bind(&done);
}

// Called only from unoptimized code. All relevant registers have been saved.
// LR: return address.
// SP + 4: left operand.
// SP + 0: right operand.
// Return Zero condition flag set if equal.
void StubCodeCompiler::GenerateUnoptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
#if !defined(PRODUCT)
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(R1);
  __ LoadFromOffset(R1, R1, target::Isolate::single_step_offset(),
                    kUnsignedByte);
  __ CompareImmediate(R1, 0);
  __ b(&stepping, NE);
  __ Bind(&done_stepping);
#endif

  const Register left = R1;
  const Register right = R0;
  __ LoadFromOffset(left, SP, 1 * target::kWordSize);
  __ LoadFromOffset(right, SP, 0 * target::kWordSize);
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ b(&done_stepping);
#endif
}

// Called from optimized code only.
// LR: return address.
// SP + 4: left operand.
// SP + 0: right operand.
// Return Zero condition flag set if equal.
void StubCodeCompiler::GenerateOptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  const Register left = R1;
  const Register right = R0;
  __ LoadFromOffset(left, SP, 1 * target::kWordSize);
  __ LoadFromOffset(right, SP, 0 * target::kWordSize);
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();
}

// Called from megamorphic call sites.
//  R0: receiver (passed to target)
//  R5: MegamorphicCache (preserved)
// Passed to target:
//  R0: receiver
//  CODE_REG: target Code
//  R4: arguments descriptor
//  R5: MegamorphicCache
void StubCodeCompiler::GenerateMegamorphicCallStub(Assembler* assembler) {
  // Jump if receiver is a smi.
  Label smi_case;
  __ BranchIfSmi(R0, &smi_case);

  // Loads the cid of the object.
  __ LoadClassId(R8, R0);

  Label cid_loaded;
  __ Bind(&cid_loaded);
  __ ldr(R2, FieldAddress(R5, target::MegamorphicCache::buckets_offset()));
  __ ldr(R1, FieldAddress(R5, target::MegamorphicCache::mask_offset()));
  // R2: cache buckets array.
  // R1: mask as a smi.

  // Make the cid into a smi.
  __ SmiTag(R8);
  // R8: class ID of the receiver (smi).

  // Compute the table index.
  ASSERT(target::MegamorphicCache::kSpreadFactor == 7);
  // Use lsl and sub to multiply with 7 == 8 - 1.
  __ LslImmediate(R3, R8, 3);
  __ sub(R3, R3, Operand(R8));
  // R3: probe.
  Label loop;
  __ Bind(&loop);
  __ and_(R3, R3, Operand(R1));

  const intptr_t base = target::Array::data_offset();
  // R3 is smi tagged, but table entries are 16 bytes, so LSL 3.
  __ add(TMP, R2, Operand(R3, LSL, 3));
  __ ldr(R6, FieldAddress(TMP, base));
  Label probe_failed;
  __ CompareRegisters(R6, R8);
  __ b(&probe_failed, NE);

  Label load_target;
  __ Bind(&load_target);
  // Call the target found in the cache.  For a class id match, this is a
  // proper target for the given name and arguments descriptor.  If the
  // illegal class id was found, the target is a cache miss handler that can
  // be invoked as a normal Dart function.
  const auto target_address = FieldAddress(TMP, base + target::kWordSize);
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ ldr(R1, target_address);
    __ ldr(
        ARGS_DESC_REG,
        FieldAddress(R5, target::CallSiteData::arguments_descriptor_offset()));
  } else {
    __ ldr(R0, target_address);
    __ ldr(R1, FieldAddress(R0, target::Function::entry_point_offset()));
    __ ldr(
        ARGS_DESC_REG,
        FieldAddress(R5, target::CallSiteData::arguments_descriptor_offset()));
    __ ldr(CODE_REG, FieldAddress(R0, target::Function::code_offset()));
  }
  __ br(R1);

  // Probe failed, check if it is a miss.
  __ Bind(&probe_failed);
  ASSERT(kIllegalCid == 0);
  __ tst(R6, Operand(R6));
  Label miss;
  __ b(&miss, EQ);  // branch if miss.

  // Try next extry in the table.
  __ AddImmediate(R3, target::ToRawSmi(1));
  __ b(&loop);

  // Load cid for the Smi case.
  __ Bind(&smi_case);
  __ LoadImmediate(R8, kSmiCid);
  __ b(&cid_loaded);

  __ Bind(&miss);
  GenerateSwitchableCallMissStub(assembler);
}

// Input:
//   R0 - receiver
//   R5 - icdata
void StubCodeCompiler::GenerateICCallThroughCodeStub(Assembler* assembler) {
  Label loop, found, miss;
  __ ldr(R8, FieldAddress(R5, target::ICData::entries_offset()));
  __ ldr(R4,
         FieldAddress(R5, target::CallSiteData::arguments_descriptor_offset()));
  __ AddImmediate(R8, target::Array::data_offset() - kHeapObjectTag);
  // R8: first IC entry
  __ LoadTaggedClassIdMayBeSmi(R1, R0);
  // R1: receiver cid as Smi

  __ Bind(&loop);
  __ ldr(R2, Address(R8, 0));
  __ cmp(R1, Operand(R2));
  __ b(&found, EQ);
  __ CompareImmediate(R2, target::ToRawSmi(kIllegalCid));
  __ b(&miss, EQ);

  const intptr_t entry_length =
      target::ICData::TestEntryLengthFor(1, /*tracking_exactness=*/false) *
      target::kWordSize;
  __ AddImmediate(R8, entry_length);  // Next entry.
  __ b(&loop);

  __ Bind(&found);
  const intptr_t code_offset =
      target::ICData::CodeIndexFor(1) * target::kWordSize;
  const intptr_t entry_offset =
      target::ICData::EntryPointIndexFor(1) * target::kWordSize;
  __ ldr(R1, Address(R8, entry_offset));
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    __ ldr(CODE_REG, Address(R8, code_offset));
  }
  __ br(R1);

  __ Bind(&miss);
  __ LoadIsolate(R2);
  __ ldr(CODE_REG, Address(R2, target::Isolate::ic_miss_code_offset()));
  __ ldr(R1, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ br(R1);
}

// Implement the monomorphic entry check for call-sites where the receiver
// might be a Smi.
//
//   R0: receiver
//   R5: MonomorphicSmiableCall object
//
//   R1: clobbered
void StubCodeCompiler::GenerateMonomorphicSmiableCheckStub(
    Assembler* assembler) {
  Label miss;
  __ LoadClassIdMayBeSmi(IP0, R0);

  if (FLAG_use_bare_instructions) {
    __ LoadField(
        IP1, FieldAddress(
                 R5, target::MonomorphicSmiableCall::expected_cid_offset()));
    __ LoadField(
        R1,
        FieldAddress(R5, target::MonomorphicSmiableCall::entrypoint_offset()));
    __ cmp(IP0, Operand(IP1));
    __ b(&miss, NE);
    __ br(R1);
  } else {
    __ LoadField(
        IP1, FieldAddress(
                 R5, target::MonomorphicSmiableCall::expected_cid_offset()));
    __ LoadField(
        CODE_REG,
        FieldAddress(R5, target::MonomorphicSmiableCall::target_offset()));
    __ LoadField(
        R1,
        FieldAddress(R5, target::MonomorphicSmiableCall::entrypoint_offset()));
    __ cmp(IP0, Operand(IP1));
    __ b(&miss, NE);
    __ br(R1);
  }

  __ Bind(&miss);
  __ ldr(IP0,
         Address(THR, target::Thread::switchable_call_miss_entry_offset()));
  __ br(IP0);
}

// Called from switchable IC calls.
//  R0: receiver
void StubCodeCompiler::GenerateSwitchableCallMissStub(Assembler* assembler) {
  __ ldr(CODE_REG,
         Address(THR, target::Thread::switchable_call_miss_stub_offset()));
  __ EnterStubFrame();
  __ Push(R0);  // Preserve receiver.

  __ Push(ZR);  // Result slot.
  __ Push(ZR);  // Arg0: stub out.
  __ Push(R0);  // Arg1: Receiver
  __ CallRuntime(kSwitchableCallMissRuntimeEntry, 2);
  __ Drop(1);
  __ Pop(CODE_REG);  // result = stub
  __ Pop(R5);        // result = IC

  __ Pop(R0);  // Restore receiver.
  __ LeaveStubFrame();

  __ ldr(R1, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                        CodeEntryKind::kNormal)));
  __ br(R1);
}

// Called from switchable IC calls.
//  R0: receiver
//  R5: SingleTargetCache
// Passed to target:
//  CODE_REG: target Code object
void StubCodeCompiler::GenerateSingleTargetCallStub(Assembler* assembler) {
  Label miss;
  __ LoadClassIdMayBeSmi(R1, R0);
  __ ldr(R2,
         FieldAddress(R5, target::SingleTargetCache::lower_limit_offset(),
                      kTwoBytes),
         kUnsignedTwoBytes);
  __ ldr(R3,
         FieldAddress(R5, target::SingleTargetCache::upper_limit_offset(),
                      kTwoBytes),
         kUnsignedTwoBytes);

  __ cmp(R1, Operand(R2));
  __ b(&miss, LT);
  __ cmp(R1, Operand(R3));
  __ b(&miss, GT);

  __ ldr(R1, FieldAddress(R5, target::SingleTargetCache::entry_point_offset()));
  __ ldr(CODE_REG,
         FieldAddress(R5, target::SingleTargetCache::target_offset()));
  __ br(R1);

  __ Bind(&miss);
  __ EnterStubFrame();
  __ Push(R0);  // Preserve receiver.

  __ Push(ZR);  // Result slot.
  __ Push(ZR);  // Arg0: Stub out.
  __ Push(R0);  // Arg1: Receiver
  __ CallRuntime(kSwitchableCallMissRuntimeEntry, 2);
  __ Drop(1);
  __ Pop(CODE_REG);  // result = stub
  __ Pop(R5);        // result = IC

  __ Pop(R0);  // Restore receiver.
  __ LeaveStubFrame();

  __ ldr(R1, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                        CodeEntryKind::kMonomorphic)));
  __ br(R1);
}

void StubCodeCompiler::GenerateFrameAwaitingMaterializationStub(
    Assembler* assembler) {
  __ brk(0);
}

void StubCodeCompiler::GenerateAsynchronousGapMarkerStub(Assembler* assembler) {
  __ brk(0);
}

void StubCodeCompiler::GenerateNotLoadedStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ CallRuntime(kNotLoadedRuntimeEntry, 0);
  __ brk(0);
}

// Instantiate type arguments from instantiator and function type args.
// R3 uninstantiated type arguments.
// R2 instantiator type arguments.
// R1: function type arguments.
// Returns instantiated type arguments in R0.
void StubCodeCompiler::GenerateInstantiateTypeArgumentsStub(
    Assembler* assembler) {
  // Lookup cache before calling runtime.
  __ LoadFieldFromOffset(R0, InstantiationABI::kUninstantiatedTypeArgumentsReg,
                         target::TypeArguments::instantiations_offset());
  __ AddImmediate(R0, Array::data_offset() - kHeapObjectTag);
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  compiler::Label loop, next, found, call_runtime;
  __ Bind(&loop);

  // Use load-acquire to test for sentinel, if we found non-sentinel it is safe
  // to access the other entries. If we found a sentinel we go to runtime.
  __ LoadAcquire(R5, R0,
                 TypeArguments::Instantiation::kInstantiatorTypeArgsIndex *
                     target::kWordSize);
  __ CompareImmediate(R5, Smi::RawValue(TypeArguments::kNoInstantiator));
  __ b(&call_runtime, EQ);

  __ CompareRegisters(R5, InstantiationABI::kInstantiatorTypeArgumentsReg);
  __ b(&next, NE);
  __ LoadFromOffset(
      R4, R0,
      TypeArguments::Instantiation::kFunctionTypeArgsIndex * target::kWordSize);
  __ CompareRegisters(R4, InstantiationABI::kFunctionTypeArgumentsReg);
  __ b(&found, EQ);
  __ Bind(&next);
  __ AddImmediate(
      R0, TypeArguments::Instantiation::kSizeInWords * target::kWordSize);
  __ b(&loop);

  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ Bind(&call_runtime);
  __ EnterStubFrame();
  __ PushPair(InstantiationABI::kUninstantiatedTypeArgumentsReg, NULL_REG);
  __ PushPair(InstantiationABI::kFunctionTypeArgumentsReg,
              InstantiationABI::kInstantiatorTypeArgumentsReg);
  __ CallRuntime(kInstantiateTypeArgumentsRuntimeEntry, 3);
  __ Drop(3);  // Drop 2 type vectors, and uninstantiated type.
  __ Pop(InstantiationABI::kResultTypeArgumentsReg);
  __ LeaveStubFrame();
  __ Ret();

  __ Bind(&found);
  __ LoadFromOffset(InstantiationABI::kResultTypeArgumentsReg, R0,
                    TypeArguments::Instantiation::kInstantiatedTypeArgsIndex *
                        target::kWordSize);
  __ Ret();
}

void StubCodeCompiler::
    GenerateInstantiateTypeArgumentsMayShareInstantiatorTAStub(
        Assembler* assembler) {
  // Return the instantiator type arguments if its nullability is compatible for
  // sharing, otherwise proceed to instantiation cache lookup.
  compiler::Label cache_lookup;
  __ LoadFieldFromOffset(R0, InstantiationABI::kUninstantiatedTypeArgumentsReg,
                         target::TypeArguments::nullability_offset());
  __ LoadFieldFromOffset(R4, InstantiationABI::kInstantiatorTypeArgumentsReg,
                         target::TypeArguments::nullability_offset());
  __ and_(R4, R4, Operand(R0));
  __ cmp(R4, Operand(R0));
  __ b(&cache_lookup, NE);
  __ mov(InstantiationABI::kResultTypeArgumentsReg,
         InstantiationABI::kInstantiatorTypeArgumentsReg);
  __ Ret();

  __ Bind(&cache_lookup);
  GenerateInstantiateTypeArgumentsStub(assembler);
}

void StubCodeCompiler::GenerateInstantiateTypeArgumentsMayShareFunctionTAStub(
    Assembler* assembler) {
  // Return the function type arguments if its nullability is compatible for
  // sharing, otherwise proceed to instantiation cache lookup.
  compiler::Label cache_lookup;
  __ LoadFieldFromOffset(R0, InstantiationABI::kUninstantiatedTypeArgumentsReg,
                         target::TypeArguments::nullability_offset());
  __ LoadFieldFromOffset(R4, InstantiationABI::kFunctionTypeArgumentsReg,
                         target::TypeArguments::nullability_offset());
  __ and_(R4, R4, Operand(R0));
  __ cmp(R4, Operand(R0));
  __ b(&cache_lookup, NE);
  __ mov(InstantiationABI::kResultTypeArgumentsReg,
         InstantiationABI::kFunctionTypeArgumentsReg);
  __ Ret();

  __ Bind(&cache_lookup);
  GenerateInstantiateTypeArgumentsStub(assembler);
}

static int GetScaleFactor(intptr_t size) {
  switch (size) {
    case 1:
      return 0;
    case 2:
      return 1;
    case 4:
      return 2;
    case 8:
      return 3;
    case 16:
      return 4;
  }
  UNREACHABLE();
  return -1;
}

void StubCodeCompiler::GenerateAllocateTypedDataArrayStub(Assembler* assembler,
                                                          intptr_t cid) {
  const intptr_t element_size = TypedDataElementSizeInBytes(cid);
  const intptr_t max_len = TypedDataMaxNewSpaceElements(cid);
  const intptr_t scale_shift = GetScaleFactor(element_size);

  COMPILE_ASSERT(AllocateTypedDataArrayABI::kLengthReg == R4);
  COMPILE_ASSERT(AllocateTypedDataArrayABI::kResultReg == R0);

  Label call_runtime;
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, R2, &call_runtime));
  __ mov(R2, AllocateTypedDataArrayABI::kLengthReg);
  /* Check that length is a positive Smi. */
  /* R2: requested array length argument. */
  __ BranchIfNotSmi(R2, &call_runtime);
  __ CompareRegisters(R2, ZR);
  __ b(&call_runtime, LT);
  __ SmiUntag(R2);
  /* Check for maximum allowed length. */
  /* R2: untagged array length. */
  __ CompareImmediate(R2, max_len);
  __ b(&call_runtime, GT);
  __ LslImmediate(R2, R2, scale_shift);
  const intptr_t fixed_size_plus_alignment_padding =
      target::TypedData::InstanceSize() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ AddImmediate(R2, fixed_size_plus_alignment_padding);
  __ andi(R2, R2, Immediate(~(target::ObjectAlignment::kObjectAlignment - 1)));
  __ ldr(R0, Address(THR, target::Thread::top_offset()));

  /* R2: allocation size. */
  __ adds(R1, R0, Operand(R2));
  __ b(&call_runtime, CS); /* Fail on unsigned overflow. */

  /* Check if the allocation fits into the remaining space. */
  /* R0: potential new object start. */
  /* R1: potential next object start. */
  /* R2: allocation size. */
  __ ldr(R6, Address(THR, target::Thread::end_offset()));
  __ cmp(R1, Operand(R6));
  __ b(&call_runtime, CS);

  /* Successfully allocated the object(s), now update top to point to */
  /* next object start and initialize the object. */
  __ str(R1, Address(THR, target::Thread::top_offset()));
  __ AddImmediate(R0, kHeapObjectTag);
  /* Initialize the tags. */
  /* R0: new object start as a tagged pointer. */
  /* R1: new object end address. */
  /* R2: allocation size. */
  {
    __ CompareImmediate(R2, target::ObjectLayout::kSizeTagMaxSizeTag);
    __ LslImmediate(R2, R2,
                    target::ObjectLayout::kTagBitsSizeTagPos -
                        target::ObjectAlignment::kObjectAlignmentLog2);
    __ csel(R2, ZR, R2, HI);

    /* Get the class index and insert it into the tags. */
    uword tags = target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
    __ LoadImmediate(TMP, tags);
    __ orr(R2, R2, Operand(TMP));
    __ str(R2, FieldAddress(R0, target::Object::tags_offset())); /* Tags. */
  }
  /* Set the length field. */
  /* R0: new object start as a tagged pointer. */
  /* R1: new object end address. */
  __ mov(R2, AllocateTypedDataArrayABI::kLengthReg); /* Array length. */
  __ StoreIntoObjectNoBarrier(
      R0, FieldAddress(R0, target::TypedDataBase::length_offset()), R2);
  /* Initialize all array elements to 0. */
  /* R0: new object start as a tagged pointer. */
  /* R1: new object end address. */
  /* R2: iterator which initially points to the start of the variable */
  /* R3: scratch register. */
  /* data area to be initialized. */
  __ mov(R3, ZR);
  __ AddImmediate(R2, R0, target::TypedData::InstanceSize() - 1);
  __ StoreInternalPointer(
      R0, FieldAddress(R0, target::TypedDataBase::data_field_offset()), R2);
  Label init_loop, done;
  __ Bind(&init_loop);
  __ cmp(R2, Operand(R1));
  __ b(&done, CS);
  __ str(R3, Address(R2, 0));
  __ add(R2, R2, Operand(target::kWordSize));
  __ b(&init_loop);
  __ Bind(&done);

  __ Ret();

  __ Bind(&call_runtime);
  __ EnterStubFrame();
  __ Push(ZR);                                     // Result slot.
  __ PushImmediate(target::ToRawSmi(cid));         // Cid
  __ Push(AllocateTypedDataArrayABI::kLengthReg);  // Array length
  __ CallRuntime(kAllocateTypedDataRuntimeEntry, 2);
  __ Drop(2);  // Drop arguments.
  __ Pop(AllocateTypedDataArrayABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

}  // namespace compiler

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
