// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

// For `AllocateObjectInstr::WillAllocateNewOrRemembered`
// For `GenericCheckBoundInstr::UseUnboxedRepresentation`
#include "vm/compiler/backend/il.h"

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/stub_code_compiler.h"

#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

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

// Ensures that [A0] is a new object, if not it will be added to the remembered
// set via a leaf runtime call.
//
// WARNING: This might clobber all registers except for [A0], [THR] and [FP].
// The caller should simply call LeaveStubFrame() and return.
void StubCodeCompiler::EnsureIsNewOrRemembered(bool preserve_registers) {
  // If the object is not remembered we call a leaf-runtime to add it to the
  // remembered set.
  Label done;
  __ andi(TMP2, A0, 1 << target::ObjectAlignment::kNewObjectBitPosition);
  __ bnez(TMP2, &done);

  {
    LeafRuntimeScope rt(assembler, /*frame_size=*/0, preserve_registers);
    // A0 already loaded.
    __ mv(A1, THR);
    rt.Call(kEnsureRememberedAndMarkingDeferredRuntimeEntry,
            /*argument_count=*/2);
  }

  __ Bind(&done);
}

// Input parameters:
//   RA : return address.
//   SP : address of last argument in argument array.
//   SP + 8*T4 - 8 : address of first argument in argument array.
//   SP + 8*T4 : address of return value.
//   T5 : address of the runtime function to call.
//   T4 : number of arguments to the call.
void StubCodeCompiler::GenerateCallToRuntimeStub() {
  const intptr_t thread_offset = target::NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = target::NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = target::NativeArguments::argv_offset();
  const intptr_t retval_offset = target::NativeArguments::retval_offset();

  __ Comment("CallToRuntimeStub");
  __ lx(CODE_REG, Address(THR, target::Thread::call_to_runtime_stub_offset()));
  __ SetPrologueOffset();
  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ StoreToOffset(FP, THR, target::Thread::top_exit_frame_info_offset());

  // Mark that the thread exited generated code through a runtime call.
  __ LoadImmediate(TMP, target::Thread::exit_through_runtime_call());
  __ StoreToOffset(TMP, THR, target::Thread::exit_through_ffi_offset());

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(TMP, THR, target::Thread::vm_tag_offset());
    __ CompareImmediate(TMP, VMTag::kDartTagId);
    __ BranchIf(EQ, &ok);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing VM code.
  __ StoreToOffset(T5, THR, target::Thread::vm_tag_offset());

  // Reserve space for arguments and align frame before entering C++ world.
  // target::NativeArguments are passed in registers.
  __ Comment("align stack");
  // Reserve space for arguments.
  ASSERT(target::NativeArguments::StructSize() == 4 * target::kWordSize);
  __ ReserveAlignedFrameSpace(target::NativeArguments::StructSize());

  // Pass target::NativeArguments structure by value and call runtime.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * target::kWordSize);
  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * target::kWordSize);
  ASSERT(argv_offset == 2 * target::kWordSize);
  __ slli(T2, T4, target::kWordSizeLog2);
  __ add(T2, FP, T2);  // Compute argv.
  // Set argv in target::NativeArguments.
  __ AddImmediate(T2,
                  target::frame_layout.param_end_from_fp * target::kWordSize);

  ASSERT(retval_offset == 3 * target::kWordSize);
  __ AddImmediate(T3, T2, target::kWordSize);

  __ StoreToOffset(THR, SP, thread_offset);
  __ StoreToOffset(T4, SP, argc_tag_offset);
  __ StoreToOffset(T2, SP, argv_offset);
  __ StoreToOffset(T3, SP, retval_offset);
  __ mv(A0, SP);  // Pass the pointer to the target::NativeArguments.

  ASSERT(IsAbiPreservedRegister(THR));
  __ jalr(T5);
  __ Comment("CallToRuntimeStub return");

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();

  // Retval is next to 1st argument.
  // Mark that the thread is executing Dart code.
  __ LoadImmediate(TMP, VMTag::kDartTagId);
  __ StoreToOffset(TMP, THR, target::Thread::vm_tag_offset());

  // Mark that the thread has not exited generated Dart code.
  __ StoreToOffset(ZR, THR, target::Thread::exit_through_ffi_offset());

  // Reset exit frame information in Isolate's mutator thread structure.
  __ StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());

  // Restore the global object pool after returning from runtime (old space is
  // moving, so the GOP could have been relocated).
  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
  }

  __ LeaveStubFrame();

  // The following return can jump to a lazy-deopt stub, which assumes A0
  // contains a return value and will save it in a GC-visible way.  We therefore
  // have to ensure A0 does not contain any garbage value left from the C
  // function we called (which has return type "void").
  // (See GenerateDeoptimizationSequence::saved_result_slot_from_fp.)
  __ LoadImmediate(A0, 0);
  __ ret();
}

void StubCodeCompiler::GenerateSharedStubGeneric(
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
  __ PushRegister(RA);
  __ PushRegisters(all_registers);
  __ lx(CODE_REG, Address(THR, self_code_stub_offset_from_thread));
  __ EnterStubFrame();
  perform_runtime_call();
  if (!allow_return) {
    __ Breakpoint();
    return;
  }
  __ LeaveStubFrame();
  __ PopRegisters(all_registers);
  __ Drop(1);  // We use the RA restored via LeaveStubFrame.
  __ ret();
}

void StubCodeCompiler::GenerateSharedStub(
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
      __ PopRegister(A0);
      __ sx(A0, Address(FP, target::kWordSize *
                                StubCodeCompiler::WordOffsetFromFpToCpuRegister(
                                    SharedSlowPathStubABI::kResultReg)));
    }
  };
  GenerateSharedStubGeneric(save_fpu_registers,
                            self_code_stub_offset_from_thread, allow_return,
                            perform_runtime_call);
}

void StubCodeCompiler::GenerateEnterSafepointStub() {
  RegisterSet all_registers;
  all_registers.AddAllGeneralRegisters();

  __ PushRegisters(all_registers);
  __ EnterFrame(0);

  __ ReserveAlignedFrameSpace(0);

  __ lx(TMP, Address(THR, kEnterSafepointRuntimeEntry.OffsetFromThread()));
  __ jalr(TMP);

  __ LeaveFrame();
  __ PopRegisters(all_registers);
  __ ret();
}

static void GenerateExitSafepointStubCommon(Assembler* assembler,
                                            uword runtime_entry_offset) {
  RegisterSet all_registers;
  all_registers.AddAllGeneralRegisters();

  __ PushRegisters(all_registers);
  __ EnterFrame(0);

  __ ReserveAlignedFrameSpace(0);

  // Set the execution state to VM while waiting for the safepoint to end.
  // This isn't strictly necessary but enables tests to check that we're not
  // in native code anymore. See tests/ffi/function_gc_test.dart for example.
  __ LoadImmediate(TMP, target::Thread::vm_execution_state());
  __ sx(TMP, Address(THR, target::Thread::execution_state_offset()));

  __ lx(TMP, Address(THR, runtime_entry_offset));
  __ jalr(TMP);

  __ LeaveFrame();
  __ PopRegisters(all_registers);
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

// Calls native code within a safepoint.
//
// On entry:
//   T0: target to call
//   Stack: set up for native call (SP), aligned, CSP < SP
//
// On exit:
//   S3: clobbered, although normally callee-saved
//   Stack: preserved, CSP == SP
void StubCodeCompiler::GenerateCallNativeThroughSafepointStub() {
  COMPILE_ASSERT(IsAbiPreservedRegister(S3));
  __ mv(S3, RA);
  __ LoadImmediate(T1, target::Thread::exit_through_ffi());
  __ TransitionGeneratedToNative(T0, FPREG, T1 /*volatile*/,
                                 /*enter_safepoint=*/true);

#if defined(DEBUG)
  // Check SP alignment.
  __ andi(T2 /*volatile*/, SP, ~(OS::ActivationFrameAlignment() - 1));
  Label done;
  __ beq(T2, SP, &done);
  __ Breakpoint();
  __ Bind(&done);
#endif

  __ jalr(T0);

  __ TransitionNativeToGenerated(T1, /*leave_safepoint=*/true);
  __ jr(S3);
}

void StubCodeCompiler::GenerateLoadFfiCallbackMetadataRuntimeFunction(
    uword function_index,
    Register dst) {
  // Keep in sync with FfiCallbackMetadata::EnsureFirstTrampolinePageLocked.
  // Note: If the stub was aligned, this could be a single PC relative load.

  // Load a pointer to the beginning of the stub into dst.
  const intptr_t code_size = __ CodeSize();
  __ auipc(dst, 0);
  __ AddImmediate(dst, -code_size);

  // Round dst down to the page size.
  __ AndImmediate(dst, FfiCallbackMetadata::kPageMask);

  // Load the function from the function table.
  __ LoadFromOffset(
      dst,
      Address(dst, FfiCallbackMetadata::RuntimeFunctionOffset(function_index)));
}

void StubCodeCompiler::GenerateFfiCallbackTrampolineStub() {
#if defined(USING_SIMULATOR) && !defined(DART_PRECOMPILER)
  // TODO(37299): FFI is not supported in SIMRISCV32/64.
  __ ebreak();
#else
  Label body;

  // T1 is volatile and not used for passing any arguments.
  COMPILE_ASSERT(!IsCalleeSavedRegister(T1) && !IsArgumentRegister(T1));
  for (intptr_t i = 0; i < FfiCallbackMetadata::NumCallbackTrampolinesPerPage();
       ++i) {
    // The FfiCallbackMetadata table is keyed by the trampoline entry point. So
    // look up the current PC, then jump to the shared section.
    __ auipc(T1, 0);
    __ j(&body);
  }

  ASSERT_EQUAL(__ CodeSize(),
               FfiCallbackMetadata::kNativeCallbackTrampolineSize *
                   FfiCallbackMetadata::NumCallbackTrampolinesPerPage());

  const intptr_t shared_stub_start = __ CodeSize();

  __ Bind(&body);

  // Save THR (callee-saved) and RA. Keeps stack aligned.
  COMPILE_ASSERT(FfiCallbackMetadata::kNativeCallbackTrampolineStackDelta == 2);
  __ PushRegisterPair(RA, THR);
  COMPILE_ASSERT(!IsArgumentRegister(THR));

  RegisterSet all_registers;
  all_registers.AddAllArgumentRegisters();

  // The call below might clobber T1 (volatile, holding callback_id).
  all_registers.Add(Location::RegisterLocation(T1));

  // Load the thread, verify the callback ID and exit the safepoint.
  //
  // We exit the safepoint inside DLRT_GetFfiCallbackMetadata in order to save
  // code size on this shared stub.
  {
    __ PushRegisters(all_registers);

    __ EnterFrame(0);
    // Reserve one slot for the entry point and one for the tramp abi.
    __ ReserveAlignedFrameSpace(2 * target::kWordSize);

    // Since DLRT_GetFfiCallbackMetadata can theoretically be loaded anywhere,
    // we use the same trick as before to ensure a predictable instruction
    // sequence.
    Label call;
    __ mv(A0, T1);                          // trampoline
    __ mv(A1, SPREG);                       // out_entry_point
    __ addi(A2, SPREG, target::kWordSize);  // out_trampoline_type

    GenerateLoadFfiCallbackMetadataRuntimeFunction(
        FfiCallbackMetadata::kGetFfiCallbackMetadata, T1);

    __ Bind(&call);
    __ jalr(T1);
    __ mv(THR, A0);
    __ lx(T2, Address(SPREG, 0));                  // entry_point
    __ lx(T3, Address(SPREG, target::kWordSize));  // trampoline_type

    __ LeaveFrame();

    __ PopRegisters(all_registers);
  }

  COMPILE_ASSERT(!IsCalleeSavedRegister(T2) && !IsArgumentRegister(T2));
  COMPILE_ASSERT(!IsCalleeSavedRegister(T3) && !IsArgumentRegister(T3));

  // Clobbers all volatile registers, including the callback ID in T1.
  __ jalr(T2);

  // Clobbers TMP, TMP2 and T1 -- all volatile and not holding return values.
  __ EnterFullSafepoint(/*scratch=*/T1);

  __ PopRegisterPair(RA, THR);
  __ ret();

  ASSERT_LESS_OR_EQUAL(__ CodeSize() - shared_stub_start,
                       FfiCallbackMetadata::kNativeCallbackSharedStubSize);
  ASSERT_LESS_OR_EQUAL(__ CodeSize(), FfiCallbackMetadata::kPageSize);

#if defined(DEBUG)
  while (__ CodeSize() < FfiCallbackMetadata::kPageSize) {
    __ ebreak();
  }
#endif
#endif
}

// T1: The extracted method.
// T4: The type_arguments_field_offset (or 0)
void StubCodeCompiler::GenerateBuildMethodExtractorStub(
    const Code& closure_allocation_stub,
    const Code& context_allocation_stub,
    bool generic) {
  const intptr_t kReceiverOffset = target::frame_layout.param_end_from_fp + 1;

  __ EnterStubFrame();

  // Build type_arguments vector (or null)
  Label no_type_args;
  __ lx(T3, Address(THR, target::Thread::object_null_offset()));
  __ CompareImmediate(T4, 0);
  __ BranchIf(EQ, &no_type_args);
  __ lx(T0, Address(FP, kReceiverOffset * target::kWordSize));
  __ add(TMP, T0, T4);
  __ LoadCompressed(T3, Address(TMP, 0));
  __ Bind(&no_type_args);

  // Push type arguments & extracted method.
  __ PushRegistersInOrder({T3, T1});

  // Allocate context.
  {
    Label done, slow_path;
    if (!FLAG_use_slow_path && FLAG_inline_alloc) {
      __ TryAllocateArray(kContextCid, target::Context::InstanceSize(1),
                          &slow_path,
                          A0,  // instance
                          T1,  // end address
                          T2, T3);
      __ StoreCompressedIntoObjectNoBarrier(
          A0, FieldAddress(A0, target::Context::parent_offset()), NULL_REG);
      __ LoadImmediate(T1, 1);
      __ sw(T1, FieldAddress(A0, target::Context::num_variables_offset()));
      __ j(&done, compiler::Assembler::kNearJump);
    }

    __ Bind(&slow_path);

    __ LoadImmediate(/*num_vars=*/T1, 1);
    __ LoadObject(CODE_REG, context_allocation_stub);
    __ lx(RA, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
    __ jalr(RA);

    __ Bind(&done);
  }

  // Put context in right register for AllocateClosure call.
  __ MoveRegister(AllocateClosureABI::kContextReg, A0);

  // Store receiver in context
  __ lx(AllocateClosureABI::kScratchReg,
        Address(FP, target::kWordSize * kReceiverOffset));
  __ StoreCompressedIntoObject(
      AllocateClosureABI::kContextReg,
      FieldAddress(AllocateClosureABI::kContextReg,
                   target::Context::variable_offset(0)),
      AllocateClosureABI::kScratchReg);

  // Pop function before pushing context.
  __ PopRegister(AllocateClosureABI::kFunctionReg);

  // Allocate closure. After this point, we only use the registers in
  // AllocateClosureABI.
  __ LoadObject(CODE_REG, closure_allocation_stub);
  __ lx(AllocateClosureABI::kScratchReg,
        FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ jalr(AllocateClosureABI::kScratchReg);

  // Populate closure object.
  __ PopRegister(AllocateClosureABI::kScratchReg);  // Pop type arguments.
  __ StoreCompressedIntoObjectNoBarrier(
      AllocateClosureABI::kResultReg,
      FieldAddress(AllocateClosureABI::kResultReg,
                   target::Closure::instantiator_type_arguments_offset()),
      AllocateClosureABI::kScratchReg);
  // Keep delayed_type_arguments as null if non-generic (see Closure::New).
  if (generic) {
    __ LoadObject(AllocateClosureABI::kScratchReg, EmptyTypeArguments());
    __ StoreCompressedIntoObjectNoBarrier(
        AllocateClosureABI::kResultReg,
        FieldAddress(AllocateClosureABI::kResultReg,
                     target::Closure::delayed_type_arguments_offset()),
        AllocateClosureABI::kScratchReg);
  }

  __ LeaveStubFrame();
  // No-op if the two are the same.
  __ MoveRegister(A0, AllocateClosureABI::kResultReg);
  __ Ret();
}

void StubCodeCompiler::GenerateDispatchTableNullErrorStub() {
  __ EnterStubFrame();
  __ SmiTag(DispatchTableNullErrorABI::kClassIdReg);
  __ PushRegister(DispatchTableNullErrorABI::kClassIdReg);
  __ CallRuntime(kDispatchTableNullErrorRuntimeEntry, /*argument_count=*/1);
  // The NullError runtime entry does not return.
  __ Breakpoint();
}

void StubCodeCompiler::GenerateRangeError(bool with_fpu_regs) {
  auto perform_runtime_call = [&]() {
  // If the generated code has unboxed index/length we need to box them before
  // calling the runtime entry.
#if XLEN == 32
    ASSERT(!GenericCheckBoundInstr::UseUnboxedRepresentation());
#else
    if (GenericCheckBoundInstr::UseUnboxedRepresentation()) {
      Label length, smi_case;

      // The user-controlled index might not fit into a Smi.
      __ mv(TMP, RangeErrorABI::kIndexReg);
      __ SmiTag(RangeErrorABI::kIndexReg, RangeErrorABI::kIndexReg);
      __ SmiUntag(TMP2, RangeErrorABI::kIndexReg);
      __ beq(TMP, TMP2, &length);  // No overflow.
      {
        // Allocate a mint, reload the two registers and populate the mint.
        __ PushRegister(NULL_REG);
        __ CallRuntime(kAllocateMintRuntimeEntry, /*argument_count=*/0);
        __ PopRegister(RangeErrorABI::kIndexReg);
        __ lx(TMP,
              Address(FP, target::kWordSize *
                              StubCodeCompiler::WordOffsetFromFpToCpuRegister(
                                  RangeErrorABI::kIndexReg)));
        __ sx(TMP, FieldAddress(RangeErrorABI::kIndexReg,
                                target::Mint::value_offset()));
        __ lx(RangeErrorABI::kLengthReg,
              Address(FP, target::kWordSize *
                              StubCodeCompiler::WordOffsetFromFpToCpuRegister(
                                  RangeErrorABI::kLengthReg)));
      }

      // Length is guaranteed to be in positive Smi range (it comes from a load
      // of a vm recognized array).
      __ Bind(&length);
      __ SmiTag(RangeErrorABI::kLengthReg);
    }
#endif  // XLEN != 32
    __ PushRegistersInOrder(
        {RangeErrorABI::kLengthReg, RangeErrorABI::kIndexReg});
    __ CallRuntime(kRangeErrorRuntimeEntry, /*argument_count=*/2);
    __ Breakpoint();
  };

  GenerateSharedStubGeneric(
      /*save_fpu_registers=*/with_fpu_regs,
      with_fpu_regs
          ? target::Thread::range_error_shared_with_fpu_regs_stub_offset()
          : target::Thread::range_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false, perform_runtime_call);
}

void StubCodeCompiler::GenerateWriteError(bool with_fpu_regs) {
  auto perform_runtime_call = [&]() {
    __ CallRuntime(kWriteErrorRuntimeEntry, /*argument_count=*/0);
    __ Breakpoint();
  };

  GenerateSharedStubGeneric(
      /*save_fpu_registers=*/with_fpu_regs,
      with_fpu_regs
          ? target::Thread::write_error_shared_with_fpu_regs_stub_offset()
          : target::Thread::write_error_shared_without_fpu_regs_stub_offset(),
      /*allow_return=*/false, perform_runtime_call);
}

// Input parameters:
//   RA : return address.
//   SP : address of return value.
//   T5 : address of the native function to call.
//   T2 : address of first argument in argument array.
//   T1 : argc_tag including number of arguments and function kind.
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
  __ LoadImmediate(TMP, target::Thread::exit_through_runtime_call());
  __ StoreToOffset(TMP, THR, target::Thread::exit_through_ffi_offset());

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ LoadFromOffset(TMP, THR, target::Thread::vm_tag_offset());
    __ CompareImmediate(TMP, VMTag::kDartTagId);
    __ BranchIf(EQ, &ok);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Mark that the thread is executing native code.
  __ StoreToOffset(T5, THR, target::Thread::vm_tag_offset());

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // R0) and align frame before entering the C++ world.
  __ ReserveAlignedFrameSpace(target::NativeArguments::StructSize());

  // Initialize target::NativeArguments structure and call native function.
  ASSERT(thread_offset == 0 * target::kWordSize);
  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * target::kWordSize);
  // Set argc in target::NativeArguments: R1 already contains argc.
  ASSERT(argv_offset == 2 * target::kWordSize);
  // Set argv in target::NativeArguments: R2 already contains argv.
  // Set retval in NativeArgs.
  ASSERT(retval_offset == 3 * target::kWordSize);
  __ AddImmediate(
      T3, FP, (target::frame_layout.param_end_from_fp + 1) * target::kWordSize);

  // Passing the structure by value as in runtime calls would require changing
  // Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ StoreToOffset(THR, SP, thread_offset);
  __ StoreToOffset(T1, SP, argc_tag_offset);
  __ StoreToOffset(T2, SP, argv_offset);
  __ StoreToOffset(T3, SP, retval_offset);
  __ mv(A0, SP);  // Pass the pointer to the target::NativeArguments.
  __ mv(A1, T5);  // Pass the function entrypoint to call.

  // Call native function invocation wrapper or redirection via simulator.
  ASSERT(IsAbiPreservedRegister(THR));
  __ Call(wrapper);

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(TMP, VMTag::kDartTagId);
  __ StoreToOffset(TMP, THR, target::Thread::vm_tag_offset());

  // Mark that the thread has not exited generated Dart code.
  __ StoreToOffset(ZR, THR, target::Thread::exit_through_ffi_offset());

  // Reset exit frame information in Isolate's mutator thread structure.
  __ StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());

  // Restore the global object pool after returning from runtime (old space is
  // moving, so the GOP could have been relocated).
  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
  }

  __ LeaveStubFrame();
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
//   RA : return address.
//   SP : address of return value.
//   R5 : address of the native function to call.
//   R2 : address of first argument in argument array.
//   R1 : argc_tag including number of arguments and function kind.
void StubCodeCompiler::GenerateCallBootstrapNativeStub() {
  GenerateCallNativeWithWrapperStub(
      assembler,
      Address(THR,
              target::Thread::bootstrap_native_wrapper_entry_point_offset()));
}

// Input parameters:
//   ARGS_DESC_REG: arguments descriptor array.
void StubCodeCompiler::GenerateCallStaticFunctionStub() {
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ subi(SP, SP, 2 * target::kWordSize);
  __ sx(ARGS_DESC_REG,
        Address(SP, 1 * target::kWordSize));      // Preserve args descriptor.
  __ sx(ZR, Address(SP, 0 * target::kWordSize));  // Result slot.
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  __ lx(CODE_REG, Address(SP, 0 * target::kWordSize));  // Result.
  __ lx(ARGS_DESC_REG,
        Address(SP, 1 * target::kWordSize));  // Restore args descriptor.
  __ addi(SP, SP, 2 * target::kWordSize);
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ jr(TMP);
}

// Called from a static call only when an invalid code has been entered
// (invalid because its function was optimized or deoptimized).
// ARGS_DESC_REG: arguments descriptor array.
void StubCodeCompiler::GenerateFixCallersTargetStub() {
  Label monomorphic;
  __ BranchOnMonomorphicCheckedEntryJIT(&monomorphic);

  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ lx(CODE_REG,
        Address(THR, target::Thread::fix_callers_target_code_offset()));
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value and preserve arguments descriptor.
  __ PushRegistersInOrder({ARGS_DESC_REG, ZR});
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  // Get Code object result and restore arguments descriptor array.
  __ PopRegister(CODE_REG);
  __ PopRegister(ARGS_DESC_REG);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ jr(TMP);

  __ Bind(&monomorphic);
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ lx(CODE_REG,
        Address(THR, target::Thread::fix_callers_target_code_offset()));
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup result slot, preserve receiver and
  // push old cache value (also 2nd return value).
  __ PushRegistersInOrder({ZR, A0, S5});
  __ CallRuntime(kFixCallersTargetMonomorphicRuntimeEntry, 2);
  __ PopRegister(S5);        // Get target cache object.
  __ PopRegister(A0);        // Restore receiver.
  __ PopRegister(CODE_REG);  // Get target Code object.
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(
      TMP, CODE_REG,
      target::Code::entry_point_offset(CodeEntryKind::kMonomorphic));
  __ jr(TMP);
}

// Called from object allocate instruction when the allocation stub has been
// disabled.
void StubCodeCompiler::GenerateFixAllocationStubTargetStub() {
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ lx(CODE_REG,
        Address(THR, target::Thread::fix_allocation_stub_code_offset()));
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ PushRegister(ZR);
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  // Get Code object result.
  __ PopRegister(CODE_REG);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ jr(TMP);
}

// Called from object allocate instruction when the allocation stub for a
// generic class has been disabled.
void StubCodeCompiler::GenerateFixParameterizedAllocationStubTargetStub() {
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ lx(CODE_REG,
        Address(THR, target::Thread::fix_allocation_stub_code_offset()));
  __ EnterStubFrame();
  // Preserve type arguments register.
  __ PushRegister(AllocateObjectABI::kTypeArgumentsReg);
  // Setup space on stack for return value.
  __ PushRegister(ZR);
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  // Get Code object result.
  __ PopRegister(CODE_REG);
  // Restore type arguments register.
  __ PopRegister(AllocateObjectABI::kTypeArgumentsReg);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ jr(TMP);
}

// Input parameters:
//   T2: smi-tagged argument count, may be zero.
//   FP[target::frame_layout.param_end_from_fp + 1]: last argument.
static void PushArrayOfArguments(Assembler* assembler) {
  COMPILE_ASSERT(AllocateArrayABI::kLengthReg == T2);
  COMPILE_ASSERT(AllocateArrayABI::kTypeArgumentsReg == T1);

  // Allocate array to store arguments of caller.
  __ LoadObject(T1, NullObject());
  // T1: null element type for raw Array.
  // T2: smi-tagged argument count, may be zero.
  __ JumpAndLink(StubCodeAllocateArray());
  // A0: newly allocated array.
  // T2: smi-tagged argument count, may be zero (was preserved by the stub).
  __ PushRegister(A0);  // Array is in A0 and on top of stack.
  __ SmiUntag(T2);
  __ slli(T1, T2, target::kWordSizeLog2);
  __ add(T1, T1, FP);
  __ AddImmediate(T1,
                  target::frame_layout.param_end_from_fp * target::kWordSize);
  __ AddImmediate(T3, A0, target::Array::data_offset() - kHeapObjectTag);
  // T1: address of first argument on stack.
  // T3: address of first argument in array.

  Label loop, loop_exit;
  __ Bind(&loop);
  __ beqz(T2, &loop_exit);
  __ lx(T6, Address(T1, 0));
  __ addi(T1, T1, -target::kWordSize);
  __ StoreCompressedIntoObject(A0, Address(T3, 0), T6);
  __ addi(T3, T3, target::kCompressedWordSize);
  __ addi(T2, T2, -1);
  __ j(&loop);
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
//   | Saved FP         |
//   +------------------+
//   | return-address   |  (deoptimization point)
//   +------------------+
//   | Saved CODE_REG   | <- FP of stub
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
      (kNumberOfCpuRegisters - A0);
  const intptr_t saved_exception_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - A0);
  const intptr_t saved_stacktrace_slot_from_fp =
      target::frame_layout.first_local_from_fp + 1 -
      (kNumberOfCpuRegisters - A1);
  // Result in A0 is preserved as part of pushing all registers below.

  // Push registers in their enumeration order: lowest register number at
  // lowest address.
  __ subi(SP, SP, kNumberOfCpuRegisters * target::kWordSize);
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    const Register r = static_cast<Register>(i);
    if (r == CODE_REG) {
      // Save the original value of CODE_REG pushed before invoking this stub
      // instead of the value used to call this stub.
      COMPILE_ASSERT(TMP > CODE_REG);  // TMP saved first
      __ lx(TMP, Address(FP, 0 * target::kWordSize));
      __ sx(TMP, Address(SP, i * target::kWordSize));
    } else {
      __ sx(r, Address(SP, i * target::kWordSize));
    }
  }

  __ subi(SP, SP, kNumberOfFpuRegisters * kFpuRegisterSize);
  for (intptr_t i = kNumberOfFpuRegisters - 1; i >= 0; i--) {
    FRegister freg = static_cast<FRegister>(i);
    __ fsd(freg, Address(SP, i * kFpuRegisterSize));
  }

  {
    __ mv(A0, SP);  // Pass address of saved registers block.
    LeafRuntimeScope rt(assembler,
                        /*frame_size=*/0,
                        /*preserve_registers=*/false);
    bool is_lazy =
        (kind == kLazyDeoptFromReturn) || (kind == kLazyDeoptFromThrow);
    __ li(A1, is_lazy ? 1 : 0);
    rt.Call(kDeoptimizeCopyFrameRuntimeEntry, 2);
    // Result (A0) is stack-size (FP - SP) in bytes.
  }

  if (kind == kLazyDeoptFromReturn) {
    // Restore result into T1 temporarily.
    __ LoadFromOffset(T1, FP, saved_result_slot_from_fp * target::kWordSize);
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into T1 temporarily.
    __ LoadFromOffset(T1, FP, saved_exception_slot_from_fp * target::kWordSize);
    __ LoadFromOffset(T2, FP,
                      saved_stacktrace_slot_from_fp * target::kWordSize);
  }

  // There is a Dart Frame on the stack. We must restore PP and leave frame.
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ sub(SP, FP, A0);

  // DeoptimizeFillFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ EnterStubFrame();

  if (kind == kLazyDeoptFromReturn) {
    __ PushRegister(T1);  // Preserve result as first local.
  } else if (kind == kLazyDeoptFromThrow) {
    // Preserve exception as first local.
    // Preserve stacktrace as second local.
    __ PushRegistersInOrder({T1, T2});
  }
  {
    __ mv(A0, FP);  // Pass last FP as parameter in R0.
    LeafRuntimeScope rt(assembler,
                        /*frame_size=*/0,
                        /*preserve_registers=*/false);
    rt.Call(kDeoptimizeFillFrameRuntimeEntry, 1);
  }
  if (kind == kLazyDeoptFromReturn) {
    // Restore result into T1.
    __ LoadFromOffset(
        T1, FP, target::frame_layout.first_local_from_fp * target::kWordSize);
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into T1.
    __ LoadFromOffset(
        T1, FP, target::frame_layout.first_local_from_fp * target::kWordSize);
    __ LoadFromOffset(
        T2, FP,
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
    __ PushRegister(T1);  // Preserve result, it will be GC-d here.
  } else if (kind == kLazyDeoptFromThrow) {
    // Preserve exception, it will be GC-d here.
    // Preserve stacktrace, it will be GC-d here.
    __ PushRegistersInOrder({T1, T2});
  }

  __ PushRegister(ZR);  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ PopRegister(T2);
  __ SmiUntag(T2);
  if (kind == kLazyDeoptFromReturn) {
    __ PopRegister(A0);  // Restore result.
  } else if (kind == kLazyDeoptFromThrow) {
    __ PopRegister(A1);  // Restore stacktrace.
    __ PopRegister(A0);  // Restore exception.
  }
  __ LeaveStubFrame();
  // Remove materialization arguments.
  __ add(SP, SP, T2);
  // The caller is responsible for emitting the return instruction.
}

// A0: result, must be preserved
void StubCodeCompiler::GenerateDeoptimizeLazyFromReturnStub() {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ PushRegister(TMP);
  // Return address for "call" to deopt stub.
  __ LoadImmediate(RA, kZapReturnAddress);
  __ lx(CODE_REG,
        Address(THR, target::Thread::lazy_deopt_from_return_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromReturn);
  __ ret();
}

// A0: exception, must be preserved
// A1: stacktrace, must be preserved
void StubCodeCompiler::GenerateDeoptimizeLazyFromThrowStub() {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ PushRegister(TMP);
  // Return address for "call" to deopt stub.
  __ LoadImmediate(RA, kZapReturnAddress);
  __ lx(CODE_REG,
        Address(THR, target::Thread::lazy_deopt_from_throw_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromThrow);
  __ ret();
}

void StubCodeCompiler::GenerateDeoptimizeStub() {
  __ PushRegister(CODE_REG);
  __ lx(CODE_REG, Address(THR, target::Thread::deoptimize_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);
  __ ret();
}

// IC_DATA_REG: ICData/MegamorphicCache
static void GenerateNoSuchMethodDispatcherBody(Assembler* assembler) {
  __ EnterStubFrame();

  __ lx(ARGS_DESC_REG,
        FieldAddress(IC_DATA_REG,
                     target::CallSiteData::arguments_descriptor_offset()));

  // Load the receiver.
  __ LoadCompressedSmiFieldFromOffset(
      T2, ARGS_DESC_REG, target::ArgumentsDescriptor::size_offset());
  __ AddShifted(TMP, FP, T2, target::kWordSizeLog2 - 1);  // T2 is Smi.
  __ LoadFromOffset(A0, TMP,
                    target::frame_layout.param_end_from_fp * target::kWordSize);
  // Push: result slot, receiver, ICData/MegamorphicCache,
  // arguments descriptor.
  __ PushRegistersInOrder({ZR, A0, IC_DATA_REG, ARGS_DESC_REG});

  // Adjust arguments count.
  __ LoadCompressedSmiFieldFromOffset(
      T3, ARGS_DESC_REG, target::ArgumentsDescriptor::type_args_len_offset());
  Label args_count_ok;
  __ beqz(T3, &args_count_ok, Assembler::kNearJump);
  // Include the type arguments.
  __ addi(T2, T2, target::ToRawSmi(1));
  __ Bind(&args_count_ok);

  // T2: Smi-tagged arguments array length.
  PushArrayOfArguments(assembler);
  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromCallStubRuntimeEntry, kNumArgs);
  __ Drop(4);
  __ PopRegister(A0);  // Return value.
  __ LeaveStubFrame();
  __ ret();
}

static void GenerateDispatcherCode(Assembler* assembler,
                                   Label* call_target_function) {
  __ Comment("NoSuchMethodDispatch");
  // When lazily generated invocation dispatchers are disabled, the
  // miss-handler may return null.
  __ bne(T0, NULL_REG, call_target_function);

  GenerateNoSuchMethodDispatcherBody(assembler);
}

// Input:
//   ARGS_DESC_REG - arguments descriptor
//   IC_DATA_REG - icdata/megamorphic_cache
void StubCodeCompiler::GenerateNoSuchMethodDispatcherStub() {
  GenerateNoSuchMethodDispatcherBody(assembler);
}

// Called for inline allocation of arrays.
// Input registers (preserved):
//   RA: return address.
//   AllocateArrayABI::kLengthReg: array length as Smi.
//   AllocateArrayABI::kTypeArgumentsReg: type arguments of array.
// Output registers:
//   AllocateArrayABI::kResultReg: newly allocated array.
// Clobbered:
//   T3, T4, T5
void StubCodeCompiler::GenerateAllocateArrayStub() {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;
    // Compute the size to be allocated, it is based on the array length
    // and is computed as:
    // RoundedAllocationSize(
    //     (array_length * kCompressedWordSize) + target::Array::header_size()).
    // Check that length is a Smi.
    __ BranchIfNotSmi(AllocateArrayABI::kLengthReg, &slow_case);

    // Check length >= 0 && length <= kMaxNewSpaceElements
    const intptr_t max_len =
        target::ToRawSmi(target::Array::kMaxNewSpaceElements);
    __ CompareImmediate(AllocateArrayABI::kLengthReg, max_len, kObjectBytes);
    __ BranchIf(HI, &slow_case);

    const intptr_t cid = kArrayCid;
    NOT_IN_PRODUCT(__ MaybeTraceAllocation(kArrayCid, &slow_case, T4));

    // Calculate and align allocation size.
    // Load new object start and calculate next object start.
    // AllocateArrayABI::kTypeArgumentsReg: type arguments of array.
    // AllocateArrayABI::kLengthReg: array length as Smi.
    __ lx(AllocateArrayABI::kResultReg,
          Address(THR, target::Thread::top_offset()));
    intptr_t fixed_size_plus_alignment_padding =
        target::Array::header_size() +
        target::ObjectAlignment::kObjectAlignment - 1;
    // AllocateArrayABI::kLengthReg is Smi.
    __ slli(T3, AllocateArrayABI::kLengthReg,
            target::kWordSizeLog2 - kSmiTagSize);
    __ AddImmediate(T3, fixed_size_plus_alignment_padding);
    __ andi(T3, T3, ~(target::ObjectAlignment::kObjectAlignment - 1));
    // AllocateArrayABI::kResultReg: potential new object start.
    // T3: object size in bytes.
    __ add(T4, AllocateArrayABI::kResultReg, T3);
    // Branch if unsigned overflow.
    __ bltu(T4, AllocateArrayABI::kResultReg, &slow_case);

    // Check if the allocation fits into the remaining space.
    // AllocateArrayABI::kResultReg: potential new object start.
    // AllocateArrayABI::kTypeArgumentsReg: type arguments of array.
    // AllocateArrayABI::kLengthReg: array length as Smi.
    // T3: array size.
    // T4: potential next object start.
    __ LoadFromOffset(TMP, THR, target::Thread::end_offset());
    __ bgeu(T4, TMP, &slow_case);  // Branch if unsigned higher or equal.

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    // AllocateArrayABI::kResultReg: potential new object start.
    // T3: array size.
    // T4: potential next object start.
    __ sx(T4, Address(THR, target::Thread::top_offset()));
    __ addi(AllocateArrayABI::kResultReg, AllocateArrayABI::kResultReg,
            kHeapObjectTag);

    // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
    // AllocateArrayABI::kTypeArgumentsReg: type arguments of array.
    // AllocateArrayABI::kLengthReg: array length as Smi.
    // R3: array size.
    // R7: new object end address.

    // Store the type argument field.
    __ StoreCompressedIntoObjectOffsetNoBarrier(
        AllocateArrayABI::kResultReg, target::Array::type_arguments_offset(),
        AllocateArrayABI::kTypeArgumentsReg);

    // Set the length field.
    __ StoreCompressedIntoObjectOffsetNoBarrier(AllocateArrayABI::kResultReg,
                                                target::Array::length_offset(),
                                                AllocateArrayABI::kLengthReg);

    // Calculate the size tag.
    // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
    // AllocateArrayABI::kLengthReg: array length as Smi.
    // T3: array size.
    // T4: new object end address.
    const intptr_t shift = target::UntaggedObject::kTagBitsSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2;
    __ li(T5, 0);
    __ CompareImmediate(T3, target::UntaggedObject::kSizeTagMaxSizeTag);
    compiler::Label zero_tag;
    __ BranchIf(UNSIGNED_GREATER, &zero_tag);
    __ slli(T5, T3, shift);
    __ Bind(&zero_tag);

    // Get the class index and insert it into the tags.
    const uword tags =
        target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);

    __ OrImmediate(T5, T5, tags);
    __ StoreFieldToOffset(T5, AllocateArrayABI::kResultReg,
                          target::Array::tags_offset());

    // Initialize all array elements to raw_null.
    // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
    // R7: new object end address.
    // AllocateArrayABI::kLengthReg: array length as Smi.
    __ AddImmediate(T3, AllocateArrayABI::kResultReg,
                    target::Array::data_offset() - kHeapObjectTag);
    // R3: iterator which initially points to the start of the variable
    // data area to be initialized.
    Label loop;
    __ Bind(&loop);
    for (intptr_t offset = 0; offset < target::kObjectAlignment;
         offset += target::kCompressedWordSize) {
      __ StoreCompressedIntoObjectNoBarrier(AllocateArrayABI::kResultReg,
                                            Address(T3, offset), NULL_REG);
    }
    // Safe to only check every kObjectAlignment bytes instead of each word.
    ASSERT(kAllocationRedZoneSize >= target::kObjectAlignment);
    __ addi(T3, T3, target::kObjectAlignment);
    __ bltu(T3, T4, &loop);

    // Done allocating and initializing the array.
    // AllocateArrayABI::kResultReg: new object.
    // AllocateArrayABI::kLengthReg: array length as Smi (preserved).
    __ ret();

    // Unable to allocate the array using the fast inline code, just call
    // into the runtime.
    __ Bind(&slow_case);
  }

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ subi(SP, SP, 3 * target::kWordSize);
  __ sx(ZR, Address(SP, 2 * target::kWordSize));  // Result slot.
  __ sx(AllocateArrayABI::kLengthReg, Address(SP, 1 * target::kWordSize));
  __ sx(AllocateArrayABI::kTypeArgumentsReg,
        Address(SP, 0 * target::kWordSize));
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);
  __ lx(AllocateArrayABI::kTypeArgumentsReg,
        Address(SP, 0 * target::kWordSize));
  __ lx(AllocateArrayABI::kLengthReg, Address(SP, 1 * target::kWordSize));
  __ lx(AllocateArrayABI::kResultReg, Address(SP, 2 * target::kWordSize));
  __ addi(SP, SP, 3 * target::kWordSize);
  __ LeaveStubFrame();

  // Write-barrier elimination might be enabled for this array (depending on the
  // array length). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  ASSERT(AllocateArrayABI::kResultReg == A0);
  EnsureIsNewOrRemembered(assembler);

  __ ret();
}

void StubCodeCompiler::GenerateAllocateMintSharedWithFPURegsStub() {
  // For test purpose call allocation stub without inline allocation attempt.
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;
    __ TryAllocate(compiler::MintClass(), &slow_case, Assembler::kNearJump,
                   AllocateMintABI::kResultReg, AllocateMintABI::kTempReg);
    __ ret();

    __ Bind(&slow_case);
  }
  COMPILE_ASSERT(AllocateMintABI::kResultReg ==
                 SharedSlowPathStubABI::kResultReg);
  GenerateSharedStub(/*save_fpu_registers=*/true, &kAllocateMintRuntimeEntry,
                     target::Thread::allocate_mint_with_fpu_regs_stub_offset(),
                     /*allow_return=*/true,
                     /*store_runtime_result_in_result_register=*/true);
}

void StubCodeCompiler::GenerateAllocateMintSharedWithoutFPURegsStub() {
  // For test purpose call allocation stub without inline allocation attempt.
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;
    __ TryAllocate(compiler::MintClass(), &slow_case, Assembler::kNearJump,
                   AllocateMintABI::kResultReg, AllocateMintABI::kTempReg);
    __ ret();

    __ Bind(&slow_case);
  }
  COMPILE_ASSERT(AllocateMintABI::kResultReg ==
                 SharedSlowPathStubABI::kResultReg);
  GenerateSharedStub(
      /*save_fpu_registers=*/false, &kAllocateMintRuntimeEntry,
      target::Thread::allocate_mint_without_fpu_regs_stub_offset(),
      /*allow_return=*/true,
      /*store_runtime_result_in_result_register=*/true);
}

// Called when invoking Dart code from C++ (VM code).
// Input parameters:
//   RA : points to return address.
//   A0 : target code or entry point (in bare instructions mode).
//   A1 : arguments descriptor array.
//   A2 : arguments array.
//   A3 : current thread.
// Beware!  TMP == A3
void StubCodeCompiler::GenerateInvokeDartCodeStub() {
  __ Comment("InvokeDartCodeStub");

  __ EnterFrame(1 * target::kWordSize);

  // Push code object to PC marker slot.
  __ lx(TMP2, Address(A3, target::Thread::invoke_dart_code_stub_offset()));
  __ sx(TMP2, Address(SP, 0 * target::kWordSize));

#if defined(DART_TARGET_OS_FUCHSIA) || defined(DART_TARGET_OS_ANDROID)
  __ sx(GP, Address(A3, target::Thread::saved_shadow_call_stack_offset()));
#elif defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // TODO(riscv): Consider using only volatile FPU registers in Dart code so we
  // don't need to save the preserved FPU registers here.
  __ PushNativeCalleeSavedRegisters();

  // Set up THR, which caches the current thread in Dart code.
  if (THR != A3) {
    __ mv(THR, A3);
  }

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();

  // Save the current VMTag, top resource and top exit frame info on the stack.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ subi(SP, SP, 4 * target::kWordSize);
  __ lx(TMP, Address(THR, target::Thread::vm_tag_offset()));
  __ sx(TMP, Address(SP, 3 * target::kWordSize));
  __ lx(TMP, Address(THR, target::Thread::top_resource_offset()));
  __ sx(ZR, Address(THR, target::Thread::top_resource_offset()));
  __ sx(TMP, Address(SP, 2 * target::kWordSize));
  __ lx(TMP, Address(THR, target::Thread::exit_through_ffi_offset()));
  __ sx(ZR, Address(THR, target::Thread::exit_through_ffi_offset()));
  __ sx(TMP, Address(SP, 1 * target::kWordSize));
  __ lx(TMP, Address(THR, target::Thread::top_exit_frame_info_offset()));
  __ sx(ZR, Address(THR, target::Thread::top_exit_frame_info_offset()));
  __ sx(TMP, Address(SP, 0 * target::kWordSize));
  // target::frame_layout.exit_link_slot_from_entry_fp must be kept in sync
  // with the code below.
#if XLEN == 32
  ASSERT_EQUAL(target::frame_layout.exit_link_slot_from_entry_fp, -42);
#elif XLEN == 64
  ASSERT_EQUAL(target::frame_layout.exit_link_slot_from_entry_fp, -30);
#endif
  // In debug mode, verify that we've pushed the top exit frame info at the
  // correct offset from FP.
  __ EmitEntryFrameVerification();

  // Mark that the thread is executing Dart code. Do this after initializing the
  // exit link for the profiler.
  __ LoadImmediate(TMP, VMTag::kDartTagId);
  __ StoreToOffset(TMP, THR, target::Thread::vm_tag_offset());

  // Load arguments descriptor array, which is passed to Dart code.
  __ LoadFromOffset(ARGS_DESC_REG, A1, VMHandles::kOffsetOfRawPtrInHandle);

  // Load number of arguments into T5 and adjust count for type arguments.
  __ LoadFieldFromOffset(T5, ARGS_DESC_REG,
                         target::ArgumentsDescriptor::count_offset());
  __ LoadFieldFromOffset(T3, ARGS_DESC_REG,
                         target::ArgumentsDescriptor::type_args_len_offset());
  __ SmiUntag(T5);
  // Include the type arguments.
  __ snez(T3, T3);  // T3 <- T3 == 0 ? 0 : 1
  __ add(T5, T5, T3);

  // Compute address of 'arguments array' data area into A2.
  __ LoadFromOffset(A2, A2, VMHandles::kOffsetOfRawPtrInHandle);
  __ AddImmediate(A2, target::Array::data_offset() - kHeapObjectTag);

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ beqz(T5, &done_push_arguments);  // check if there are arguments.
  __ LoadImmediate(T2, 0);
  __ Bind(&push_arguments);
  __ lx(T3, Address(A2, 0));
  __ PushRegister(T3);
  __ addi(T2, T2, 1);
  __ addi(A2, A2, target::kWordSize);
  __ blt(T2, T5, &push_arguments, compiler::Assembler::kNearJump);
  __ Bind(&done_push_arguments);

  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
    __ mv(CODE_REG, ZR);  // GC-safe value into CODE_REG.
  } else {
    // We now load the pool pointer(PP) with a GC safe value as we are about to
    // invoke dart code. We don't need a real object pool here.
    __ li(PP, 1);  // PP is untagged, callee will tag and spill PP.
    __ lx(CODE_REG, Address(A0, VMHandles::kOffsetOfRawPtrInHandle));
    __ lx(A0, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  }

  // Call the Dart code entrypoint.
  __ jalr(A0);  // ARGS_DESC_REG is the arguments descriptor array.
  __ Comment("InvokeDartCodeStub return");

  // Get rid of arguments pushed on the stack.
  __ addi(
      SP, FP,
      target::frame_layout.exit_link_slot_from_entry_fp * target::kWordSize);

  // Restore the current VMTag, the saved top exit frame info and top resource
  // back into the Thread structure.
  __ lx(TMP, Address(SP, 0 * target::kWordSize));
  __ sx(TMP, Address(THR, target::Thread::top_exit_frame_info_offset()));
  __ lx(TMP, Address(SP, 1 * target::kWordSize));
  __ sx(TMP, Address(THR, target::Thread::exit_through_ffi_offset()));
  __ lx(TMP, Address(SP, 2 * target::kWordSize));
  __ sx(TMP, Address(THR, target::Thread::top_resource_offset()));
  __ lx(TMP, Address(SP, 3 * target::kWordSize));
  __ sx(TMP, Address(THR, target::Thread::vm_tag_offset()));
  __ addi(SP, SP, 4 * target::kWordSize);

  __ PopNativeCalleeSavedRegisters();

  // Restore the frame pointer and C stack pointer and return.
  __ LeaveFrame();
  __ ret();
}

// Helper to generate space allocation of context stub.
// This does not initialise the fields of the context.
// Input:
//   T1: number of context variables.
// Output:
//   A0: new allocated Context object.
// Clobbered:
//   T2, T3, T4, TMP
static void GenerateAllocateContextSpaceStub(Assembler* assembler,
                                             Label* slow_case) {
  // First compute the rounded instance size.
  // R1: number of context variables.
  intptr_t fixed_size_plus_alignment_padding =
      target::Context::header_size() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ slli(T2, T1, kCompressedWordSizeLog2);
  __ AddImmediate(T2, fixed_size_plus_alignment_padding);
  __ andi(T2, T2, ~(target::ObjectAlignment::kObjectAlignment - 1));

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(kContextCid, slow_case, T4));
  // Now allocate the object.
  // T1: number of context variables.
  // T2: object size.
  __ lx(A0, Address(THR, target::Thread::top_offset()));
  __ add(T3, T2, A0);
  // Check if the allocation fits into the remaining space.
  // A0: potential new object.
  // T1: number of context variables.
  // T2: object size.
  // T3: potential next object start.
  __ lx(TMP, Address(THR, target::Thread::end_offset()));
  __ CompareRegisters(T3, TMP);
  __ BranchIf(CS, slow_case);  // Branch if unsigned higher or equal.

  // Successfully allocated the object, now update top to point to
  // next object start and initialize the object.
  // A0: new object.
  // T1: number of context variables.
  // T2: object size.
  // T3: next object start.
  __ sx(T3, Address(THR, target::Thread::top_offset()));
  __ addi(A0, A0, kHeapObjectTag);

  // Calculate the size tag.
  // A0: new object.
  // T1: number of context variables.
  // T2: object size.
  const intptr_t shift = target::UntaggedObject::kTagBitsSizeTagPos -
                         target::ObjectAlignment::kObjectAlignmentLog2;
  __ li(T3, 0);
  __ CompareImmediate(T2, target::UntaggedObject::kSizeTagMaxSizeTag);
  // If no size tag overflow, shift R2 left, else set R2 to zero.
  compiler::Label zero_tag;
  __ BranchIf(HI, &zero_tag);
  __ slli(T3, T2, shift);
  __ Bind(&zero_tag);

  // Get the class index and insert it into the tags.
  // T3: size and bit tags.
  const uword tags =
      target::MakeTagWordForNewSpaceObject(kContextCid, /*instance_size=*/0);

  __ OrImmediate(T3, T3, tags);
  __ StoreFieldToOffset(T3, A0, target::Object::tags_offset());

  // Setup up number of context variables field.
  // A0: new object.
  // T1: number of context variables as integer value (not object).
  __ StoreFieldToOffset(T1, A0, target::Context::num_variables_offset(),
                        kFourBytes);
}

// Called for inline allocation of contexts.
// Input:
//   T1: number of context variables.
// Output:
//   A0: new allocated Context object.
void StubCodeCompiler::GenerateAllocateContextStub() {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    GenerateAllocateContextSpaceStub(assembler, &slow_case);

    // Setup the parent field.
    // A0: new object.
    // T1: number of context variables.
    __ StoreCompressedIntoObjectOffset(A0, target::Context::parent_offset(),
                                       NULL_REG);

    // Initialize the context variables.
    // A0: new object.
    // T1: number of context variables.
    {
      Label loop, done;
      __ AddImmediate(T3, A0,
                      target::Context::variable_offset(0) - kHeapObjectTag);
      __ Bind(&loop);
      __ subi(T1, T1, 1);
      __ bltz(T1, &done);
      __ sx(NULL_REG, Address(T3, 0));
      __ addi(T3, T3, target::kCompressedWordSize);
      __ j(&loop);
      __ Bind(&done);
    }

    // Done allocating and initializing the context.
    // A0: new object.
    __ ret();

    __ Bind(&slow_case);
  }

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ SmiTag(T1);
  __ PushObject(NullObject());
  __ PushRegister(T1);
  __ CallRuntime(kAllocateContextRuntimeEntry, 1);  // Allocate context.
  __ Drop(1);          // Pop number of context variables argument.
  __ PopRegister(A0);  // Pop the new context object.

  // Write-barrier elimination might be enabled for this context (depending on
  // the size). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(/*preserve_registers=*/false);

  // A0: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();
  __ ret();
}

// Called for clone of contexts.
// Input:
//   T5: context variable to clone.
// Output:
//   A0: new allocated Context object.
void StubCodeCompiler::GenerateCloneContextStub() {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    // Load num. variable (int32) in the existing context.
    __ lw(T1, FieldAddress(T5, target::Context::num_variables_offset()));

    GenerateAllocateContextSpaceStub(assembler, &slow_case);

    // Load parent in the existing context.
    __ LoadCompressed(T3, FieldAddress(T5, target::Context::parent_offset()));
    // Setup the parent field.
    // A0: new context.
    __ StoreCompressedIntoObjectNoBarrier(
        A0, FieldAddress(A0, target::Context::parent_offset()), T3);

    // Clone the context variables.
    // A0: new context.
    // T1: number of context variables.
    {
      Label loop, done;
      // T3: Variable array address, new context.
      __ AddImmediate(T3, A0,
                      target::Context::variable_offset(0) - kHeapObjectTag);
      // T4: Variable array address, old context.
      __ AddImmediate(T4, T5,
                      target::Context::variable_offset(0) - kHeapObjectTag);

      __ Bind(&loop);
      __ subi(T1, T1, 1);
      __ bltz(T1, &done);
      __ lx(T5, Address(T4, 0));
      __ addi(T4, T4, target::kCompressedWordSize);
      __ sx(T5, Address(T3, 0));
      __ addi(T3, T3, target::kCompressedWordSize);
      __ j(&loop);

      __ Bind(&done);
    }

    // Done allocating and initializing the context.
    // A0: new object.
    __ ret();

    __ Bind(&slow_case);
  }

  __ EnterStubFrame();

  __ subi(SP, SP, 2 * target::kWordSize);
  __ sx(NULL_REG, Address(SP, 1 * target::kWordSize));  // Result slot.
  __ sx(T5, Address(SP, 0 * target::kWordSize));        // Context argument.
  __ CallRuntime(kCloneContextRuntimeEntry, 1);
  __ lx(A0, Address(SP, 1 * target::kWordSize));  // Context result.
  __ subi(SP, SP, 2 * target::kWordSize);

  // Write-barrier elimination might be enabled for this context (depending on
  // the size). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(/*preserve_registers=*/false);

  // A0: new object
  __ LeaveStubFrame();
  __ ret();
}

void StubCodeCompiler::GenerateWriteBarrierWrappersStub() {
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if ((kDartAvailableCpuRegs & (1 << i)) == 0) continue;

    Register reg = static_cast<Register>(i);
    intptr_t start = __ CodeSize();
    __ addi(SP, SP, -3 * target::kWordSize);
    __ sx(RA, Address(SP, 2 * target::kWordSize));
    __ sx(TMP, Address(SP, 1 * target::kWordSize));
    __ sx(kWriteBarrierObjectReg, Address(SP, 0 * target::kWordSize));
    __ mv(kWriteBarrierObjectReg, reg);
    __ Call(Address(THR, target::Thread::write_barrier_entry_point_offset()));
    __ lx(kWriteBarrierObjectReg, Address(SP, 0 * target::kWordSize));
    __ lx(TMP, Address(SP, 1 * target::kWordSize));
    __ lx(RA, Address(SP, 2 * target::kWordSize));
    __ addi(SP, SP, 3 * target::kWordSize);
    __ jr(TMP);  // Return.
    intptr_t end = __ CodeSize();
    ASSERT_EQUAL(end - start, kStoreBufferWrapperSize);
  }
}

// Helper stub to implement Assembler::StoreIntoObject/Array.
// Input parameters:
//   A0: Object (old)
//   A1: Value (old or new)
//   A6: Slot
// If A1 is new, add A0 to the store buffer. Otherwise A1 is old, mark A1
// and add it to the mark list.
COMPILE_ASSERT(kWriteBarrierObjectReg == A0);
COMPILE_ASSERT(kWriteBarrierValueReg == A1);
COMPILE_ASSERT(kWriteBarrierSlotReg == A6);
static void GenerateWriteBarrierStubHelper(Assembler* assembler,
                                           bool cards) {
  Label add_to_mark_stack, remember_card, lost_race;
  __ andi(TMP2, A1, 1 << target::ObjectAlignment::kNewObjectBitPosition);
  __ beqz(TMP2, &add_to_mark_stack);

  if (cards) {
    __ lbu(TMP2, FieldAddress(A0, target::Object::tags_offset()));
    __ andi(TMP2, TMP2, 1 << target::UntaggedObject::kCardRememberedBit);
    __ bnez(TMP2, &remember_card);
  } else {
#if defined(DEBUG)
    Label ok;
    __ lbu(TMP2, FieldAddress(A0, target::Object::tags_offset()));
    __ andi(TMP2, TMP2, 1 << target::UntaggedObject::kCardRememberedBit);
    __ beqz(TMP2, &ok, Assembler::kNearJump);
    __ Stop("Wrong barrier!");
    __ Bind(&ok);
#endif
  }

  // Spill T2, T3, T4.
  __ subi(SP, SP, 3 * target::kWordSize);
  __ sx(T2, Address(SP, 2 * target::kWordSize));
  __ sx(T3, Address(SP, 1 * target::kWordSize));
  __ sx(T4, Address(SP, 0 * target::kWordSize));

  // Atomically clear kOldAndNotRememberedBit.
  ASSERT(target::Object::tags_offset() == 0);
  __ subi(T3, A0, kHeapObjectTag);
  // T3: Untagged address of header word (amo's do not support offsets).
  __ li(TMP2, ~(1 << target::UntaggedObject::kOldAndNotRememberedBit));
#if XLEN == 32
  __ amoandw(TMP2, TMP2, Address(T3, 0));
#else
  __ amoandd(TMP2, TMP2, Address(T3, 0));
#endif
  __ andi(TMP2, TMP2, 1 << target::UntaggedObject::kOldAndNotRememberedBit);
  __ beqz(TMP2, &lost_race);  // Was already clear -> lost race.

  // Load the StoreBuffer block out of the thread. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  __ LoadFromOffset(T4, THR, target::Thread::store_buffer_block_offset());
  __ LoadFromOffset(T2, T4, target::StoreBufferBlock::top_offset(),
                    kUnsignedFourBytes);
  __ slli(T3, T2, target::kWordSizeLog2);
  __ add(T3, T4, T3);
  __ StoreToOffset(A0, T3, target::StoreBufferBlock::pointers_offset());

  // Increment top_ and check for overflow.
  // T2: top_.
  // T4: StoreBufferBlock.
  Label overflow;
  __ addi(T2, T2, 1);
  __ StoreToOffset(T2, T4, target::StoreBufferBlock::top_offset(),
                   kUnsignedFourBytes);
  __ CompareImmediate(T2, target::StoreBufferBlock::kSize);
  // Restore values.
  __ BranchIf(EQ, &overflow);

  // Restore T2, T3, T4.
  __ lx(T4, Address(SP, 0 * target::kWordSize));
  __ lx(T3, Address(SP, 1 * target::kWordSize));
  __ lx(T2, Address(SP, 2 * target::kWordSize));
  __ addi(SP, SP, 3 * target::kWordSize);
  __ ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&overflow);
  // Restore T2, T3, T4.
  __ lx(T4, Address(SP, 0 * target::kWordSize));
  __ lx(T3, Address(SP, 1 * target::kWordSize));
  __ lx(T2, Address(SP, 2 * target::kWordSize));
  __ addi(SP, SP, 3 * target::kWordSize);
  {
    LeafRuntimeScope rt(assembler, /*frame_size=*/0,
                        /*preserve_registers=*/true);
    __ mv(A0, THR);
    rt.Call(kStoreBufferBlockProcessRuntimeEntry, /*argument_count=*/1);
  }
  __ ret();

  __ Bind(&add_to_mark_stack);
  // Spill T2, T3, T4.
  __ subi(SP, SP, 3 * target::kWordSize);
  __ sx(T2, Address(SP, 2 * target::kWordSize));
  __ sx(T3, Address(SP, 1 * target::kWordSize));
  __ sx(T4, Address(SP, 0 * target::kWordSize));

  // Atomically clear kOldAndNotMarkedBit.
  Label marking_overflow;
  ASSERT(target::Object::tags_offset() == 0);
  __ subi(T3, A1, kHeapObjectTag);
  // T3: Untagged address of header word (amo's do not support offsets).
  __ li(TMP2, ~(1 << target::UntaggedObject::kOldAndNotMarkedBit));
#if XLEN == 32
  __ amoandw(TMP2, TMP2, Address(T3, 0));
#else
  __ amoandd(TMP2, TMP2, Address(T3, 0));
#endif
  __ andi(TMP2, TMP2, 1 << target::UntaggedObject::kOldAndNotMarkedBit);
  __ beqz(TMP2, &lost_race);  // Was already clear -> lost race.

  __ LoadFromOffset(T4, THR, target::Thread::marking_stack_block_offset());
  __ LoadFromOffset(T2, T4, target::MarkingStackBlock::top_offset(),
                    kUnsignedFourBytes);
  __ slli(T3, T2, target::kWordSizeLog2);
  __ add(T3, T4, T3);
  __ StoreToOffset(A1, T3, target::MarkingStackBlock::pointers_offset());
  __ addi(T2, T2, 1);
  __ StoreToOffset(T2, T4, target::MarkingStackBlock::top_offset(),
                   kUnsignedFourBytes);
  __ CompareImmediate(T2, target::MarkingStackBlock::kSize);
  __ BranchIf(EQ, &marking_overflow);
  // Restore T2, T3, T4.
  __ lx(T4, Address(SP, 0 * target::kWordSize));
  __ lx(T3, Address(SP, 1 * target::kWordSize));
  __ lx(T2, Address(SP, 2 * target::kWordSize));
  __ addi(SP, SP, 3 * target::kWordSize);
  __ ret();

  __ Bind(&marking_overflow);
  // Restore T2, T3, T4.
  __ lx(T4, Address(SP, 0 * target::kWordSize));
  __ lx(T3, Address(SP, 1 * target::kWordSize));
  __ lx(T2, Address(SP, 2 * target::kWordSize));
  __ addi(SP, SP, 3 * target::kWordSize);
  {
    LeafRuntimeScope rt(assembler, /*frame_size=*/0,
                        /*preserve_registers=*/true);
    __ mv(A0, THR);
    rt.Call(kMarkingStackBlockProcessRuntimeEntry, /*argument_count=*/1);
  }
  __ ret();

  __ Bind(&lost_race);
  // Restore T2, T3, T4.
  __ lx(T4, Address(SP, 0 * target::kWordSize));
  __ lx(T3, Address(SP, 1 * target::kWordSize));
  __ lx(T2, Address(SP, 2 * target::kWordSize));
  __ addi(SP, SP, 3 * target::kWordSize);
  __ ret();

  if (cards) {
    Label remember_card_slow;

    // Get card table.
    __ Bind(&remember_card);
    __ AndImmediate(TMP, A0, target::kPageMask);                  // Page.
    __ lx(TMP, Address(TMP, target::Page::card_table_offset()));  // Card table.
    __ beqz(TMP, &remember_card_slow);

    // Dirty the card.
    __ AndImmediate(TMP, A0, target::kPageMask);     // Page.
    __ sub(A6, A6, TMP);                             // Offset in page.
    __ lx(TMP, Address(TMP, target::Page::card_table_offset()));  // Card table.
    __ srli(A6, A6, target::Page::kBytesPerCardLog2);
    __ add(TMP, TMP, A6);        // Card address.
    __ sb(A0, Address(TMP, 0));  // Low byte of A0 is non-zero from object tag.
    __ ret();

    // Card table not yet allocated.
    __ Bind(&remember_card_slow);
    {
      LeafRuntimeScope rt(assembler, /*frame_size=*/0,
                          /*preserve_registers=*/true);
      __ mv(A0, A0);  // Arg0 = Object
      __ mv(A1, A6);  // Arg1 = Slot
      rt.Call(kRememberCardRuntimeEntry, /*argument_count=*/2);
    }
    __ ret();
  }
}

void StubCodeCompiler::GenerateWriteBarrierStub() {
  GenerateWriteBarrierStubHelper(assembler, false);
}

void StubCodeCompiler::GenerateArrayWriteBarrierStub() {
  GenerateWriteBarrierStubHelper(assembler, true);
}

static void GenerateAllocateObjectHelper(Assembler* assembler,
                                         bool is_cls_parameterized) {
  const Register kTagsReg = AllocateObjectABI::kTagsReg;

  {
    Label slow_case;

    const Register kNewTopReg = T3;

    // Bump allocation.
    {
      const Register kInstanceSizeReg = T4;
      const Register kEndReg = T5;

      __ ExtractInstanceSizeFromTags(kInstanceSizeReg, kTagsReg);

      // Load two words from Thread::top: top and end.
      // AllocateObjectABI::kResultReg: potential next object start.
      __ lx(AllocateObjectABI::kResultReg,
            Address(THR, target::Thread::top_offset()));
      __ lx(kEndReg, Address(THR, target::Thread::end_offset()));

      __ add(kNewTopReg, AllocateObjectABI::kResultReg, kInstanceSizeReg);

      __ CompareRegisters(kEndReg, kNewTopReg);
      __ BranchIf(UNSIGNED_LESS_EQUAL, &slow_case);

      // Successfully allocated the object, now update top to point to
      // next object start and store the class in the class field of object.
      __ sx(kNewTopReg, Address(THR, target::Thread::top_offset()));
    }  // kInstanceSizeReg = R4, kEndReg = R5

    // Tags.
    __ sx(kTagsReg, Address(AllocateObjectABI::kResultReg,
                            target::Object::tags_offset()));

    // Initialize the remaining words of the object.
    {
      const Register kFieldReg = T4;

      __ AddImmediate(kFieldReg, AllocateObjectABI::kResultReg,
                      target::Instance::first_field_offset());
      Label loop;
      __ Bind(&loop);
      for (intptr_t offset = 0; offset < target::kObjectAlignment;
           offset += target::kCompressedWordSize) {
        __ StoreCompressedIntoObjectNoBarrier(AllocateObjectABI::kResultReg,
                                              Address(kFieldReg, offset),
                                              NULL_REG);
      }
      // Safe to only check every kObjectAlignment bytes instead of each word.
      ASSERT(kAllocationRedZoneSize >= target::kObjectAlignment);
      __ addi(kFieldReg, kFieldReg, target::kObjectAlignment);
      __ bltu(kFieldReg, kNewTopReg, &loop);
    }  // kFieldReg = T4

    if (is_cls_parameterized) {
      Label not_parameterized_case;

      const Register kClsIdReg = T4;
      const Register kTypeOffsetReg = T5;

      __ ExtractClassIdFromTags(kClsIdReg, kTagsReg);

      // Load class' type_arguments_field offset in words.
      __ LoadClassById(kTypeOffsetReg, kClsIdReg);
      __ lw(
          kTypeOffsetReg,
          FieldAddress(kTypeOffsetReg,
                       target::Class::
                           host_type_arguments_field_offset_in_words_offset()));

      // Set the type arguments in the new object.
      __ slli(kTypeOffsetReg, kTypeOffsetReg, target::kWordSizeLog2);
      __ add(kTypeOffsetReg, kTypeOffsetReg, AllocateObjectABI::kResultReg);
      __ sx(AllocateObjectABI::kTypeArgumentsReg, Address(kTypeOffsetReg, 0));

      __ Bind(&not_parameterized_case);
    }  // kClsIdReg = R4, kTypeOffsetReg = R5

    __ AddImmediate(AllocateObjectABI::kResultReg,
                    AllocateObjectABI::kResultReg, kHeapObjectTag);

    __ ret();

    __ Bind(&slow_case);
  }  // kNewTopReg = R3

  // Fall back on slow case:
  if (!is_cls_parameterized) {
    __ mv(AllocateObjectABI::kTypeArgumentsReg, NULL_REG);
  }
  // Tail call to generic allocation stub.
  __ lx(
      TMP,
      Address(THR, target::Thread::allocate_object_slow_entry_point_offset()));
  __ jr(TMP);
}

// Called for inline allocation of objects (any class).
void StubCodeCompiler::GenerateAllocateObjectStub() {
  GenerateAllocateObjectHelper(assembler, /*is_cls_parameterized=*/false);
}

void StubCodeCompiler::GenerateAllocateObjectParameterizedStub() {
  GenerateAllocateObjectHelper(assembler, /*is_cls_parameterized=*/true);
}

void StubCodeCompiler::GenerateAllocateObjectSlowStub() {
  if (!FLAG_precompiled_mode) {
    __ lx(CODE_REG,
          Address(THR, target::Thread::call_to_runtime_stub_offset()));
  }

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();

  __ ExtractClassIdFromTags(AllocateObjectABI::kTagsReg,
                            AllocateObjectABI::kTagsReg);
  __ LoadClassById(A0, AllocateObjectABI::kTagsReg);

  __ subi(SP, SP, 3 * target::kWordSize);
  __ sx(ZR, Address(SP, 2 * target::kWordSize));  // Result slot.
  __ sx(A0, Address(SP, 1 * target::kWordSize));  // Arg0: Class object.
  __ sx(AllocateObjectABI::kTypeArgumentsReg,
        Address(SP, 0 * target::kWordSize));  // Arg1: Type args or null.
  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);
  __ lx(AllocateObjectABI::kResultReg, Address(SP, 2 * target::kWordSize));
  __ addi(SP, SP, 3 * target::kWordSize);

  // Write-barrier elimination is enabled for [cls] and we therefore need to
  // ensure that the object is in new-space or has remembered bit set.
  EnsureIsNewOrRemembered(/*preserve_registers=*/false);

  __ LeaveStubFrame();

  __ ret();
}

// Called for inline allocation of objects.
void StubCodeCompiler::GenerateAllocationStubForClass(
    UnresolvedPcRelativeCalls* unresolved_calls,
    const Class& cls,
    const Code& allocate_object,
    const Code& allocat_object_parametrized) {
  classid_t cls_id = target::Class::GetId(cls);
  ASSERT(cls_id != kIllegalCid);

  // The generated code is different if the class is parameterized.
  const bool is_cls_parameterized = target::Class::NumTypeArguments(cls) > 0;
  ASSERT(!is_cls_parameterized || target::Class::TypeArgumentsFieldOffset(
                                      cls) != target::Class::kNoTypeArguments);

  const intptr_t instance_size = target::Class::GetInstanceSize(cls);
  ASSERT(instance_size > 0);

  const uword tags =
      target::MakeTagWordForNewSpaceObject(cls_id, instance_size);

  // Note: Keep in sync with helper function.
  const Register kTagsReg = AllocateObjectABI::kTagsReg;
  ASSERT(kTagsReg != AllocateObjectABI::kTypeArgumentsReg);

  __ LoadImmediate(kTagsReg, tags);

  if (!FLAG_use_slow_path && FLAG_inline_alloc &&
      !target::Class::TraceAllocation(cls) &&
      target::SizeFitsInSizeTag(instance_size)) {
    RELEASE_ASSERT(AllocateObjectInstr::WillAllocateNewOrRemembered(cls));
    RELEASE_ASSERT(target::Heap::IsAllocatableInNewSpace(instance_size));
    if (is_cls_parameterized) {
      if (!IsSameObject(NullObject(),
                        CastHandle<Object>(allocat_object_parametrized))) {
        __ GenerateUnRelocatedPcRelativeTailCall();
        unresolved_calls->Add(new UnresolvedPcRelativeCall(
            __ CodeSize(), allocat_object_parametrized, /*is_tail_call=*/true));
      } else {
        __ lx(TMP,
              Address(THR,
                      target::Thread::
                          allocate_object_parameterized_entry_point_offset()));
        __ jr(TMP);
      }
    } else {
      if (!IsSameObject(NullObject(), CastHandle<Object>(allocate_object))) {
        __ GenerateUnRelocatedPcRelativeTailCall();
        unresolved_calls->Add(new UnresolvedPcRelativeCall(
            __ CodeSize(), allocate_object, /*is_tail_call=*/true));
      } else {
        __ lx(
            TMP,
            Address(THR, target::Thread::allocate_object_entry_point_offset()));
        __ jr(TMP);
      }
    }
  } else {
    if (!is_cls_parameterized) {
      __ LoadObject(AllocateObjectABI::kTypeArgumentsReg, NullObject());
    }
    __ lx(TMP,
          Address(THR,
                  target::Thread::allocate_object_slow_entry_point_offset()));
    __ jr(TMP);
  }
}

// Called for invoking "dynamic noSuchMethod(Invocation invocation)" function
// from the entry code of a dart function after an error in passed argument
// name or number is detected.
// Input parameters:
//  RA : return address.
//  SP : address of last argument.
//  S4: arguments descriptor array.
void StubCodeCompiler::GenerateCallClosureNoSuchMethodStub() {
  __ EnterStubFrame();

  // Load the receiver.
  __ LoadCompressedSmiFieldFromOffset(
      T2, S4, target::ArgumentsDescriptor::size_offset());
  __ AddShifted(TMP, FP, T2, target::kWordSizeLog2 - 1);  // T2 is Smi
  __ LoadFromOffset(A0, TMP,
                    target::frame_layout.param_end_from_fp * target::kWordSize);

  // Load the function.
  __ LoadCompressedFieldFromOffset(TMP, A0, target::Closure::function_offset());

  // Push result slot, receiver, function, arguments descriptor.
  __ PushRegistersInOrder({ZR, A0, TMP, S4});

  // Adjust arguments count.
  __ LoadCompressedSmiFieldFromOffset(
      T3, S4, target::ArgumentsDescriptor::type_args_len_offset());
  Label args_count_ok;
  __ beqz(T3, &args_count_ok, Assembler::kNearJump);
  // Include the type arguments.
  __ addi(T2, T2, target::ToRawSmi(1));
  __ Bind(&args_count_ok);

  // T2: Smi-tagged arguments array length.
  PushArrayOfArguments(assembler);

  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromPrologueRuntimeEntry, kNumArgs);
  // noSuchMethod on closures always throws an error, so it will never return.
  __ ebreak();
}

//  A6: function object.
//  S5: inline cache data object.
// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCodeCompiler::GenerateOptimizedUsageCounterIncrement() {
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }
  if (FLAG_trace_optimized_ic_calls) {
    __ Stop("Unimplemented");
  }
  __ LoadFieldFromOffset(TMP, A6, target::Function::usage_counter_offset(),
                         kFourBytes);
  __ addi(TMP, TMP, 1);
  __ StoreFieldToOffset(TMP, A6, target::Function::usage_counter_offset(),
                        kFourBytes);
}

// Loads function into 'func_reg'.
void StubCodeCompiler::GenerateUsageCounterIncrement(Register func_reg) {
  if (FLAG_precompiled_mode) {
    __ trap();
    return;
  }
  if (FLAG_optimization_counter_threshold >= 0) {
    __ Comment("Increment function counter");
    __ LoadFieldFromOffset(func_reg, IC_DATA_REG,
                           target::ICData::owner_offset());
    __ LoadFieldFromOffset(
        A1, func_reg, target::Function::usage_counter_offset(), kFourBytes);
    __ AddImmediate(A1, 1);
    __ StoreFieldToOffset(A1, func_reg,
                          target::Function::usage_counter_offset(), kFourBytes);
  }
}

// Note: S5 must be preserved.
// Attempt a quick Smi operation for known operations ('kind'). The ICData
// must have been primed with a Smi/Smi check that will be used for counting
// the invocations.
static void EmitFastSmiOp(Assembler* assembler,
                          Token::Kind kind,
                          intptr_t num_args,
                          Label* not_smi_or_overflow) {
  __ Comment("Fast Smi op");
  __ lx(A0, Address(SP, +1 * target::kWordSize));  // Left.
  __ lx(A1, Address(SP, +0 * target::kWordSize));  // Right.
  __ or_(TMP2, A0, A1);
  __ andi(TMP2, TMP2, kSmiTagMask);
  __ bnez(TMP2, not_smi_or_overflow);
  switch (kind) {
    case Token::kADD: {
      __ AddBranchOverflow(A0, A0, A1, not_smi_or_overflow);
      break;
    }
    case Token::kLT: {
      // TODO(riscv): Bit tricks with stl and NULL_REG.
      Label load_true, done;
      __ blt(A0, A1, &load_true, compiler::Assembler::kNearJump);
      __ LoadObject(A0, CastHandle<Object>(FalseObject()));
      __ j(&done, Assembler::kNearJump);
      __ Bind(&load_true);
      __ LoadObject(A0, CastHandle<Object>(TrueObject()));
      __ Bind(&done);
      break;
    }
    case Token::kEQ: {
      // TODO(riscv): Bit tricks with stl and NULL_REG.
      Label load_true, done;
      __ beq(A0, A1, &load_true, Assembler::kNearJump);
      __ LoadObject(A0, CastHandle<Object>(FalseObject()));
      __ j(&done, Assembler::kNearJump);
      __ Bind(&load_true);
      __ LoadObject(A0, CastHandle<Object>(TrueObject()));
      __ Bind(&done);
      break;
    }
    default:
      UNIMPLEMENTED();
  }

  // S5: IC data object (preserved).
  __ LoadFieldFromOffset(A6, IC_DATA_REG, target::ICData::entries_offset());
  // R6: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(A6, target::Array::data_offset() - kHeapObjectTag);
// R6: points directly to the first ic data array element.
#if defined(DEBUG)
  // Check that first entry is for Smi/Smi.
  Label error, ok;
  const intptr_t imm_smi_cid = target::ToRawSmi(kSmiCid);
  __ LoadCompressedSmiFromOffset(TMP, A6, 0);
  __ CompareImmediate(TMP, imm_smi_cid);
  __ BranchIf(NE, &error);
  __ LoadCompressedSmiFromOffset(TMP, A6, target::kCompressedWordSize);
  __ CompareImmediate(TMP, imm_smi_cid);
  __ BranchIf(EQ, &ok);
  __ Bind(&error);
  __ Stop("Incorrect IC data");
  __ Bind(&ok);
#endif
  if (FLAG_optimization_counter_threshold >= 0) {
    const intptr_t count_offset =
        target::ICData::CountIndexFor(num_args) * target::kCompressedWordSize;
    // Update counter, ignore overflow.
    __ LoadCompressedSmiFromOffset(A1, A6, count_offset);
    __ addi(A1, A1, target::ToRawSmi(1));
    __ StoreToOffset(A1, A6, count_offset);
  }

  __ ret();
}

// Saves the offset of the target entry-point (from the Function) into T6.
//
// Must be the first code generated, since any code before will be skipped in
// the unchecked entry-point.
static void GenerateRecordEntryPoint(Assembler* assembler) {
  Label done;
  __ LoadImmediate(T6, target::Function::entry_point_offset() - kHeapObjectTag);
  __ j(&done, Assembler::kNearJump);
  __ BindUncheckedEntryPoint();
  __ LoadImmediate(
      T6, target::Function::entry_point_offset(CodeEntryKind::kUnchecked) -
              kHeapObjectTag);
  __ Bind(&done);
}

// Generate inline cache check for 'num_args'.
//  A0: receiver (if instance call)
//  S5: ICData
//  RA: return address
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
  const bool save_entry_point = kind == Token::kILLEGAL;
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }

  if (save_entry_point) {
    GenerateRecordEntryPoint(assembler);
    // T6: untagged entry point offset
  }

  if (optimized == kOptimized) {
    GenerateOptimizedUsageCounterIncrement();
  } else {
    GenerateUsageCounterIncrement(/*scratch=*/T0);
  }

  ASSERT(exactness == kIgnoreExactness);  // Unimplemented.
  ASSERT(num_args == 1 || num_args == 2);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ LoadFromOffset(TMP, IC_DATA_REG,
                      target::ICData::state_bits_offset() - kHeapObjectTag,
                      kUnsignedFourBytes);
    ASSERT(target::ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andi(TMP, TMP, target::ICData::NumArgsTestedMask());
    __ CompareImmediate(TMP2, num_args);
    __ BranchIf(EQ, &ok, Assembler::kNearJump);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

#if !defined(PRODUCT)
  Label stepping, done_stepping;
  if (optimized == kUnoptimized) {
    __ Comment("Check single stepping");
    __ LoadIsolate(TMP);
    __ LoadFromOffset(TMP, TMP, target::Isolate::single_step_offset(),
                      kUnsignedByte);
    __ bnez(TMP, &stepping);
    __ Bind(&done_stepping);
  }
#endif

  Label not_smi_or_overflow;
  if (kind != Token::kILLEGAL) {
    EmitFastSmiOp(assembler, kind, num_args, &not_smi_or_overflow);
  }
  __ Bind(&not_smi_or_overflow);

  __ Comment("Extract ICData initial values and receiver cid");
  // S5: IC data object (preserved).
  __ LoadFieldFromOffset(A1, IC_DATA_REG, target::ICData::entries_offset());
  // A1: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(A1, target::Array::data_offset() - kHeapObjectTag);
  // A1: points directly to the first ic data array element.

  if (type == kInstanceCall) {
    __ LoadTaggedClassIdMayBeSmi(T1, A0);
    __ LoadFieldFromOffset(ARGS_DESC_REG, IC_DATA_REG,
                           target::CallSiteData::arguments_descriptor_offset());
    if (num_args == 2) {
      __ LoadCompressedSmiFieldFromOffset(
          A7, ARGS_DESC_REG, target::ArgumentsDescriptor::count_offset());
      __ slli(A7, A7, target::kWordSizeLog2 - kSmiTagSize);
      __ add(A7, SP, A7);
      __ lx(A6, Address(A7, -2 * target::kWordSize));
      __ LoadTaggedClassIdMayBeSmi(T2, A6);
    }
  } else {
    __ LoadFieldFromOffset(ARGS_DESC_REG, IC_DATA_REG,
                           target::CallSiteData::arguments_descriptor_offset());
    __ LoadCompressedSmiFieldFromOffset(
        A7, ARGS_DESC_REG, target::ArgumentsDescriptor::count_offset());
    __ slli(A7, A7, target::kWordSizeLog2 - kSmiTagSize);
    __ add(A7, A7, SP);
    __ lx(A6, Address(A7, -1 * target::kWordSize));
    __ LoadTaggedClassIdMayBeSmi(T1, A6);
    if (num_args == 2) {
      __ lx(A6, Address(A7, -2 * target::kWordSize));
      __ LoadTaggedClassIdMayBeSmi(T2, A6);
    }
  }
  // T1: first argument class ID as Smi.
  // T2: second argument class ID as Smi.
  // S4: args descriptor

  // We unroll the generic one that is generated once more than the others.
  const bool optimize = kind == Token::kILLEGAL;

  // Loop that checks if there is an IC data match.
  Label loop, found, miss;
  __ Comment("ICData loop");

  __ Bind(&loop);
  for (int unroll = optimize ? 4 : 2; unroll >= 0; unroll--) {
    Label update;

    __ LoadCompressedSmiFromOffset(A7, A1, 0);
    if (num_args == 1) {
      __ beq(A7, T1, &found);  // Class id match?
    } else {
      __ bne(A7, T1, &update);  // Continue.
      __ LoadCompressedSmiFromOffset(A7, A1, target::kCompressedWordSize);
      __ beq(A7, T2, &found);  // Class id match?
    }
    __ Bind(&update);

    const intptr_t entry_size = target::ICData::TestEntryLengthFor(
                                    num_args, exactness == kCheckExactness) *
                                target::kCompressedWordSize;
    __ AddImmediate(A1, entry_size);  // Next entry.

    __ CompareImmediate(A7, target::ToRawSmi(kIllegalCid));  // Done?
    if (unroll == 0) {
      __ BranchIf(NE, &loop);
    } else {
      __ BranchIf(EQ, &miss);
    }
  }

  __ Bind(&miss);
  __ Comment("IC miss");

  // Compute address of arguments.
  __ LoadCompressedSmiFieldFromOffset(
      A7, ARGS_DESC_REG, target::ArgumentsDescriptor::count_offset());
  __ slli(A7, A7, target::kWordSizeLog2 - kSmiTagSize);
  __ add(A7, A7, SP);
  __ subi(A7, A7, 1 * target::kWordSize);

  // A7: address of receiver
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Preserve IC data object and arguments descriptor array and
  // setup space on stack for result (target code object).
  __ PushRegistersInOrder({ARGS_DESC_REG, IC_DATA_REG});
  if (save_entry_point) {
    __ SmiTag(T6);
    __ PushRegister(T6);
  }
  // Setup space on stack for the result (target code object).
  __ PushRegister(ZR);
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ LoadFromOffset(TMP, A7, -target::kWordSize * i);
    __ PushRegister(TMP);
  }
  // Pass IC data object.
  __ PushRegister(IC_DATA_REG);
  __ CallRuntime(handle_ic_miss, num_args + 1);
  // Remove the call arguments pushed earlier, including the IC data object.
  __ Drop(num_args + 1);
  // Pop returned function object into R0.
  // Restore arguments descriptor array and IC data array.
  __ PopRegister(FUNCTION_REG);  // Pop returned function object into T0.
  if (save_entry_point) {
    __ PopRegister(T6);
    __ SmiUntag(T6);
  }
  __ PopRegister(IC_DATA_REG);    // Restore IC Data.
  __ PopRegister(ARGS_DESC_REG);  // Restore arguments descriptor array.
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  Label call_target_function;
  if (!FLAG_lazy_dispatchers) {
    GenerateDispatcherCode(assembler, &call_target_function);
  } else {
    __ j(&call_target_function);
  }

  __ Bind(&found);
  __ Comment("Update caller's counter");
  // A1: pointer to an IC data check group.
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(num_args) * target::kCompressedWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(num_args) * target::kCompressedWordSize;
  __ LoadCompressedFromOffset(FUNCTION_REG, A1, target_offset);

  if (FLAG_optimization_counter_threshold >= 0) {
    // Update counter, ignore overflow.
    __ LoadCompressedSmiFromOffset(TMP, A1, count_offset);
    __ addi(TMP, TMP, target::ToRawSmi(1));
    __ StoreToOffset(TMP, A1, count_offset);
  }

  __ Comment("Call target");
  __ Bind(&call_target_function);
  // T0: target function.
  __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                   target::Function::code_offset());
  if (save_entry_point) {
    __ add(A7, FUNCTION_REG, T6);
    __ lx(A7, Address(A7, 0));
  } else {
    __ LoadFieldFromOffset(A7, FUNCTION_REG,
                           target::Function::entry_point_offset());
  }
  __ jr(A7);  // FUNCTION_REG: Function, argument to lazy compile stub.

#if !defined(PRODUCT)
  if (optimized == kUnoptimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    if (type == kInstanceCall) {
      __ PushRegister(A0);  // Preserve receiver.
    }
    if (save_entry_point) {
      __ SmiTag(T6);
      __ PushRegister(T6);
    }
    __ PushRegister(IC_DATA_REG);  // Preserve IC data.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ PopRegister(IC_DATA_REG);
    if (save_entry_point) {
      __ PopRegister(T6);
      __ SmiUntag(T6);
    }
    if (type == kInstanceCall) {
      __ PopRegister(A0);
    }
    __ RestoreCodePointer();
    __ LeaveStubFrame();
    __ j(&done_stepping);
  }
#endif
}

// A0: receiver
// S5: ICData
// RA: return address
void StubCodeCompiler::GenerateOneArgCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

// A0: receiver
// S5: ICData
// RA: return address
void StubCodeCompiler::GenerateOneArgCheckInlineCacheWithExactnessCheckStub() {
  __ Stop("Unimplemented");
}

// A0: receiver
// S5: ICData
// RA: return address
void StubCodeCompiler::GenerateTwoArgsCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

// A0: receiver
// S5: ICData
// RA: return address
void StubCodeCompiler::GenerateSmiAddInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kADD, kUnoptimized,
      kInstanceCall, kIgnoreExactness);
}

// A0: receiver
// S5: ICData
// RA: return address
void StubCodeCompiler::GenerateSmiLessInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kLT, kUnoptimized,
      kInstanceCall, kIgnoreExactness);
}

// A0: receiver
// S5: ICData
// RA: return address
void StubCodeCompiler::GenerateSmiEqualInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ, kUnoptimized,
      kInstanceCall, kIgnoreExactness);
}

// A0: receiver
// S5: ICData
// A6: Function
// RA: return address
void StubCodeCompiler::GenerateOneArgOptimizedCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL, kOptimized,
      kInstanceCall, kIgnoreExactness);
}

// A0: receiver
// S5: ICData
// A6: Function
// RA: return address
void StubCodeCompiler::
    GenerateOneArgOptimizedCheckInlineCacheWithExactnessCheckStub() {
  __ Stop("Unimplemented");
}

// A0: receiver
// S5: ICData
// A6: Function
// RA: return address
void StubCodeCompiler::GenerateTwoArgsOptimizedCheckInlineCacheStub() {
  GenerateNArgsCheckInlineCacheStub(
      2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kIgnoreExactness);
}

// S5: ICData
// RA: return address
void StubCodeCompiler::GenerateZeroArgsUnoptimizedStaticCallStub() {
  GenerateRecordEntryPoint(assembler);
  GenerateUsageCounterIncrement(/* scratch */ T0);

#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == 0.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ LoadFromOffset(TMP, IC_DATA_REG,
                      target::ICData::state_bits_offset() - kHeapObjectTag,
                      kUnsignedFourBytes);
    ASSERT(target::ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ andi(TMP, TMP, target::ICData::NumArgsTestedMask());
    __ CompareImmediate(TMP, 0);
    __ BranchIf(EQ, &ok);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif  // DEBUG

  // Check single stepping.
#if !defined(PRODUCT)
  Label stepping, done_stepping;
  __ LoadIsolate(TMP);
  __ LoadFromOffset(TMP, TMP, target::Isolate::single_step_offset(),
                    kUnsignedByte);
  __ bnez(TMP, &stepping, Assembler::kNearJump);
  __ Bind(&done_stepping);
#endif

  // T5: IC data object (preserved).
  __ LoadFieldFromOffset(A0, IC_DATA_REG, target::ICData::entries_offset());
  // A0: ic_data_array with entries: target functions and count.
  __ AddImmediate(A0, target::Array::data_offset() - kHeapObjectTag);
  // A0: points directly to the first ic data array element.
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(0) * target::kCompressedWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(0) * target::kCompressedWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    // Increment count for this call, ignore overflow.
    __ LoadCompressedSmiFromOffset(TMP, A0, count_offset);
    __ addi(TMP, TMP, target::ToRawSmi(1));
    __ StoreToOffset(TMP, A0, count_offset);
  }

  // Load arguments descriptor into T4.
  __ LoadFieldFromOffset(ARGS_DESC_REG, IC_DATA_REG,
                         target::CallSiteData::arguments_descriptor_offset());

  // Get function and call it, if possible.
  __ LoadCompressedFromOffset(FUNCTION_REG, A0, target_offset);
  __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                   target::Function::code_offset());
  __ add(A0, FUNCTION_REG, T6);
  __ lx(TMP, Address(A0, 0));
  __ jr(TMP);  // FUNCTION_REG: Function, argument to lazy compile stub.

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ PushRegister(IC_DATA_REG);  // Preserve IC data.
  __ SmiTag(T6);
  __ PushRegister(T6);
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ PopRegister(T6);
  __ SmiUntag(T6);
  __ PopRegister(IC_DATA_REG);
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ j(&done_stepping);
#endif
}

// S5: ICData
// RA: return address
void StubCodeCompiler::GenerateOneArgUnoptimizedStaticCallStub() {
  GenerateUsageCounterIncrement(/* scratch */ T0);
  GenerateNArgsCheckInlineCacheStub(1, kStaticCallMissHandlerOneArgRuntimeEntry,
                                    Token::kILLEGAL, kUnoptimized, kStaticCall,
                                    kIgnoreExactness);
}

// S5: ICData
// RA: return address
void StubCodeCompiler::GenerateTwoArgsUnoptimizedStaticCallStub() {
  GenerateUsageCounterIncrement(/* scratch */ T0);
  GenerateNArgsCheckInlineCacheStub(
      2, kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kStaticCall, kIgnoreExactness);
}

// Stub for compiling a function and jumping to the compiled code.
// ARGS_DESC_REG: Arguments descriptor.
// FUNCTION_REG: Function.
void StubCodeCompiler::GenerateLazyCompileStub() {
  // Preserve arg desc.
  __ EnterStubFrame();
  // Save arguments descriptor and pass function.
  __ PushRegistersInOrder({ARGS_DESC_REG, FUNCTION_REG});
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ PopRegister(FUNCTION_REG);   // Restore function.
  __ PopRegister(ARGS_DESC_REG);  // Restore arg desc.
  __ LeaveStubFrame();

  __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                   target::Function::code_offset());
  __ LoadFieldFromOffset(TMP, FUNCTION_REG,
                         target::Function::entry_point_offset());
  __ jr(TMP);
}

// A0: Receiver
// S5: ICData
void StubCodeCompiler::GenerateICCallBreakpointStub() {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ subi(SP, SP, 3 * target::kWordSize);
  __ sx(A0, Address(SP, 2 * target::kWordSize));  // Preserve receiver.
  __ sx(S5, Address(SP, 1 * target::kWordSize));  // Preserve IC data.
  __ sx(ZR, Address(SP, 0 * target::kWordSize));  // Space for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ lx(CODE_REG, Address(SP, 0 * target::kWordSize));  // Original stub.
  __ lx(S5, Address(SP, 1 * target::kWordSize));        // Restore IC data.
  __ lx(A0, Address(SP, 2 * target::kWordSize));        // Restore receiver.
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ jr(TMP);
#endif
}

// S5: ICData
void StubCodeCompiler::GenerateUnoptStaticCallBreakpointStub() {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ subi(SP, SP, 2 * target::kWordSize);
  __ sx(S5, Address(SP, 1 * target::kWordSize));  // Preserve IC data.
  __ sx(ZR, Address(SP, 0 * target::kWordSize));  // Space for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ lx(CODE_REG, Address(SP, 0 * target::kWordSize));  // Original stub.
  __ lx(S5, Address(SP, 1 * target::kWordSize));        // Restore IC data.
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ jr(TMP);
#endif  // defined(PRODUCT)
}

void StubCodeCompiler::GenerateRuntimeCallBreakpointStub() {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ subi(SP, SP, 1 * target::kWordSize);
  __ sx(ZR, Address(SP, 0 * target::kWordSize));  // Space for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ lx(CODE_REG, Address(SP, 0 * target::kWordSize));
  __ LeaveStubFrame();
  __ LoadFieldFromOffset(TMP, CODE_REG, target::Code::entry_point_offset());
  __ jr(TMP);
#endif  // defined(PRODUCT)
}

// Called only from unoptimized code. All relevant registers have been saved.
void StubCodeCompiler::GenerateDebugStepCheckStub() {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(A1);
  __ LoadFromOffset(A1, A1, target::Isolate::single_step_offset(),
                    kUnsignedByte);
  __ bnez(A1, &stepping, compiler::Assembler::kNearJump);
  __ Bind(&done_stepping);
  __ ret();

  __ Bind(&stepping);
  __ EnterStubFrame();
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ j(&done_stepping);
#endif  // defined(PRODUCT)
}

// Used to check class and type arguments. Arguments passed in registers:
//
// Inputs (mostly from TypeTestABI struct):
//   - kSubtypeTestCacheReg: UntaggedSubtypeTestCache
//   - kInstanceReg: instance to test against.
//   - kDstTypeReg: destination type (for n>=3).
//   - kInstantiatorTypeArgumentsReg: instantiator type arguments (for n=5).
//   - kFunctionTypeArgumentsReg: function type arguments (for n=5).
//   - RA: return address.
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
  __ lx(kCacheArrayReg, FieldAddress(TypeTestABI::kSubtypeTestCacheReg,
                                     target::SubtypeTestCache::cache_offset()));
  __ AddImmediate(kCacheArrayReg,
                  target::Array::data_offset() - kHeapObjectTag);

  Label loop, not_closure;
  if (n >= 5) {
    __ LoadClassIdMayBeSmi(STCInternalRegs::kInstanceCidOrSignatureReg,
                           TypeTestABI::TypeTestABI::kInstanceReg);
  } else {
    __ LoadClassId(STCInternalRegs::kInstanceCidOrSignatureReg,
                   TypeTestABI::kInstanceReg);
  }
  __ CompareImmediate(STCInternalRegs::kInstanceCidOrSignatureReg, kClosureCid);
  __ BranchIf(NE, &not_closure);

  // Closure handling.
  {
    __ Comment("Closure");
    __ LoadCompressed(STCInternalRegs::kInstanceCidOrSignatureReg,
                      FieldAddress(TypeTestABI::kInstanceReg,
                                   target::Closure::function_offset()));
    __ LoadCompressed(STCInternalRegs::kInstanceCidOrSignatureReg,
                      FieldAddress(STCInternalRegs::kInstanceCidOrSignatureReg,
                                   target::Function::signature_offset()));
    if (n >= 3) {
      __ LoadCompressed(
          STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg,
          FieldAddress(TypeTestABI::kInstanceReg,
                       target::Closure::instantiator_type_arguments_offset()));
      if (n >= 7) {
        __ LoadCompressed(
            STCInternalRegs::kInstanceParentFunctionTypeArgumentsReg,
            FieldAddress(TypeTestABI::kInstanceReg,
                         target::Closure::function_type_arguments_offset()));
        __ LoadCompressed(
            STCInternalRegs::kInstanceDelayedFunctionTypeArgumentsReg,
            FieldAddress(TypeTestABI::kInstanceReg,
                         target::Closure::delayed_type_arguments_offset()));
      }
    }
    __ j(&loop);
  }

  // Non-Closure handling.
  {
    __ Comment("Non-Closure");
    __ Bind(&not_closure);
    if (n >= 3) {
      Label has_no_type_arguments;
      __ LoadClassById(kScratchReg,
                       STCInternalRegs::kInstanceCidOrSignatureReg);
      __ mv(STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg, kNullReg);
      __ LoadFieldFromOffset(
          kScratchReg, kScratchReg,
          target::Class::host_type_arguments_field_offset_in_words_offset(),
          kFourBytes);
      __ CompareImmediate(kScratchReg, target::Class::kNoTypeArguments);
      __ BranchIf(EQ, &has_no_type_arguments);
      __ slli(kScratchReg, kScratchReg, kCompressedWordSizeLog2);
      __ add(kScratchReg, kScratchReg, TypeTestABI::kInstanceReg);
      __ LoadCompressed(STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg,
                        FieldAddress(kScratchReg, 0));
      __ Bind(&has_no_type_arguments);
      __ Comment("No type arguments");

      if (n >= 7) {
        __ mv(STCInternalRegs::kInstanceParentFunctionTypeArgumentsReg,
              kNullReg);
        __ mv(STCInternalRegs::kInstanceDelayedFunctionTypeArgumentsReg,
              kNullReg);
      }
    }
    __ SmiTag(STCInternalRegs::kInstanceCidOrSignatureReg);
  }

  Label found, done, next_iteration;

  // Loop header
  __ Bind(&loop);
  __ Comment("Loop");
  __ LoadCompressed(
      kScratchReg,
      Address(kCacheArrayReg,
              target::kCompressedWordSize *
                  target::SubtypeTestCache::kInstanceCidOrSignature));
  __ CompareObjectRegisters(kScratchReg, kNullReg);
  __ BranchIf(EQ, &done);
  __ CompareObjectRegisters(kScratchReg,
                            STCInternalRegs::kInstanceCidOrSignatureReg);
  if (n == 1) {
    __ BranchIf(EQ, &found);
  } else {
    __ BranchIf(NE, &next_iteration);
    __ LoadCompressed(kScratchReg,
                      Address(kCacheArrayReg,
                              target::kCompressedWordSize *
                                  target::SubtypeTestCache::kDestinationType));
    __ CompareRegisters(kScratchReg, TypeTestABI::kDstTypeReg);
    __ BranchIf(NE, &next_iteration);
    __ LoadCompressed(
        kScratchReg,
        Address(kCacheArrayReg,
                target::kCompressedWordSize *
                    target::SubtypeTestCache::kInstanceTypeArguments));
    __ CompareRegisters(kScratchReg,
                        STCInternalRegs::kInstanceInstantiatorTypeArgumentsReg);
    if (n == 3) {
      __ BranchIf(EQ, &found);
    } else {
      __ BranchIf(NE, &next_iteration);
      __ LoadCompressed(
          kScratchReg,
          Address(kCacheArrayReg,
                  target::kCompressedWordSize *
                      target::SubtypeTestCache::kInstantiatorTypeArguments));
      __ CompareRegisters(kScratchReg,
                          TypeTestABI::kInstantiatorTypeArgumentsReg);
      __ BranchIf(NE, &next_iteration);
      __ LoadCompressed(
          kScratchReg,
          Address(kCacheArrayReg,
                  target::kCompressedWordSize *
                      target::SubtypeTestCache::kFunctionTypeArguments));
      __ CompareRegisters(kScratchReg, TypeTestABI::kFunctionTypeArgumentsReg);
      if (n == 5) {
        __ BranchIf(EQ, &found);
      } else {
        ASSERT(n == 7);
        __ BranchIf(NE, &next_iteration);

        __ LoadCompressed(
            kScratchReg, Address(kCacheArrayReg,
                                 target::kCompressedWordSize *
                                     target::SubtypeTestCache::
                                         kInstanceParentFunctionTypeArguments));
        __ CompareRegisters(
            kScratchReg,
            STCInternalRegs::kInstanceParentFunctionTypeArgumentsReg);
        __ BranchIf(NE, &next_iteration);

        __ LoadCompressed(
            kScratchReg,
            Address(kCacheArrayReg,
                    target::kCompressedWordSize *
                        target::SubtypeTestCache::
                            kInstanceDelayedFunctionTypeArguments));
        __ CompareRegisters(
            kScratchReg,
            STCInternalRegs::kInstanceDelayedFunctionTypeArgumentsReg);
        __ BranchIf(EQ, &found);
      }
    }
  }
  __ Bind(&next_iteration);
  __ Comment("Next iteration");
  __ AddImmediate(
      kCacheArrayReg,
      target::kCompressedWordSize * target::SubtypeTestCache::kTestEntryLength);
  __ j(&loop);

  __ Bind(&found);
  __ Comment("Found");
  __ LoadCompressed(
      TypeTestABI::kSubtypeTestCacheResultReg,
      Address(kCacheArrayReg, target::kCompressedWordSize *
                                  target::SubtypeTestCache::kTestResult));
  __ Bind(&done);
  __ Comment("Done");
  __ ret();
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype1TestCacheStub() {
  GenerateSubtypeNTestCacheStub(assembler, 1);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype3TestCacheStub() {
  GenerateSubtypeNTestCacheStub(assembler, 3);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype5TestCacheStub() {
  GenerateSubtypeNTestCacheStub(assembler, 5);
}

// See comment on [GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype7TestCacheStub() {
  GenerateSubtypeNTestCacheStub(assembler, 7);
}

void StubCodeCompiler::GenerateGetCStackPointerStub() {
  __ mv(A0, SP);
  __ ret();
}

// Jump to a frame on the call stack.
// RA: return address.
// A0: program_counter.
// A1: stack_pointer.
// A2: frame_pointer.
// A3: thread.
// Does not return.
//
// Notice: We need to keep this in sync with `Simulator::JumpToFrame()`.
void StubCodeCompiler::GenerateJumpToFrameStub() {
  ASSERT(kExceptionObjectReg == A0);
  ASSERT(kStackTraceObjectReg == A1);
  __ mv(CALLEE_SAVED_TEMP, A0);  // Program counter.
  __ mv(SP, A1);                 // Stack pointer.
  __ mv(FP, A2);                 // Frame_pointer.
  __ mv(THR, A3);
#if defined(DART_TARGET_OS_FUCHSIA) || defined(DART_TARGET_OS_ANDROID)
  // We need to restore the shadow call stack pointer like longjmp would,
  // effectively popping all the return addresses between the Dart exit frame
  // and Exceptions::JumpToFrame, otherwise the shadow call stack might
  // eventually overflow.
  __ lx(GP, Address(THR, target::Thread::saved_shadow_call_stack_offset()));
#elif defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif
  Label exit_through_non_ffi;
  // Check if we exited generated from FFI. If so do transition - this is needed
  // because normally runtime calls transition back to generated via destructor
  // of TransitionGeneratedToVM/Native that is part of runtime boilerplate
  // code (see DEFINE_RUNTIME_ENTRY_IMPL in runtime_entry.h). Ffi calls don't
  // have this boilerplate, don't have this stack resource, have to transition
  // explicitly.
  __ LoadFromOffset(TMP, THR,
                    compiler::target::Thread::exit_through_ffi_offset());
  __ LoadImmediate(TMP2, target::Thread::exit_through_ffi());
  __ bne(TMP, TMP2, &exit_through_non_ffi);
  __ TransitionNativeToGenerated(TMP, /*leave_safepoint=*/true,
                                 /*ignore_unwind_in_progress=*/true);
  __ Bind(&exit_through_non_ffi);

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();
  // Set the tag.
  __ LoadImmediate(TMP, VMTag::kDartTagId);
  __ StoreToOffset(TMP, THR, target::Thread::vm_tag_offset());
  // Clear top exit frame.
  __ StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());
  // Restore the pool pointer.
  __ RestoreCodePointer();
  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
  } else {
    __ LoadPoolPointer();
  }
  __ jr(CALLEE_SAVED_TEMP);  // Jump to continuation point.
}

// Run an exception handler.  Execution comes from JumpToFrame
// stub or from the simulator.
//
// The arguments are stored in the Thread object.
// Does not return.
void StubCodeCompiler::GenerateRunExceptionHandlerStub() {
  // Exception object.
  ASSERT(kExceptionObjectReg == A0);
  __ LoadFromOffset(A0, THR, target::Thread::active_exception_offset());
  __ StoreToOffset(NULL_REG, THR, target::Thread::active_exception_offset());

  // StackTrace object.
  ASSERT(kStackTraceObjectReg == A1);
  __ LoadFromOffset(A1, THR, target::Thread::active_stacktrace_offset());
  __ StoreToOffset(NULL_REG, THR, target::Thread::active_stacktrace_offset());

  __ LoadFromOffset(RA, THR, target::Thread::resume_pc_offset());
  __ ret();  // Jump to the exception handler code.
}

// Deoptimize a frame on the call stack before rewinding.
// The arguments are stored in the Thread object.
// No result.
void StubCodeCompiler::GenerateDeoptForRewindStub() {
  // Push zap value instead of CODE_REG.
  __ LoadImmediate(TMP, kZapCodeReg);
  __ PushRegister(TMP);

  // Load the deopt pc into RA.
  __ LoadFromOffset(RA, THR, target::Thread::resume_pc_offset());
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);

  // After we have deoptimized, jump to the correct frame.
  __ EnterStubFrame();
  __ CallRuntime(kRewindPostDeoptRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ ebreak();
}

// Calls to the runtime to optimize the given function.
// A0: function to be re-optimized.
// ARGS_DESC_REG: argument descriptor (preserved).
void StubCodeCompiler::GenerateOptimizeFunctionStub() {
  __ LoadFromOffset(CODE_REG, THR, target::Thread::optimize_stub_offset());
  __ EnterStubFrame();

  __ subi(SP, SP, 3 * target::kWordSize);
  __ sx(ARGS_DESC_REG,
        Address(SP, 2 * target::kWordSize));      // Preserves args descriptor.
  __ sx(ZR, Address(SP, 1 * target::kWordSize));  // Result slot.
  __ sx(A0, Address(SP, 0 * target::kWordSize));  // Function argument.
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ lx(FUNCTION_REG, Address(SP, 1 * target::kWordSize));  // Function result.
  __ lx(ARGS_DESC_REG,
        Address(SP, 2 * target::kWordSize));  // Restore args descriptor.
  __ addi(SP, SP, 3 * target::kWordSize);

  __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                   target::Function::code_offset());
  __ LoadFieldFromOffset(A1, FUNCTION_REG,
                         target::Function::entry_point_offset());
  __ LeaveStubFrame();
  __ jr(A1);
  __ ebreak();
}

// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers and returns with TMP = 0 iff left and right are
// identical.
static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right) {
  Label reference_compare, check_mint, done;
  // If any of the arguments is Smi do reference compare.
  // Note: A Mint cannot contain a value that would fit in Smi.
  __ BranchIfSmi(left, &reference_compare, Assembler::kNearJump);
  __ BranchIfSmi(right, &reference_compare, Assembler::kNearJump);

  // Value compare for two doubles.
  __ CompareClassId(left, kDoubleCid, /*scratch*/ TMP);
  __ BranchIf(NOT_EQUAL, &check_mint, Assembler::kNearJump);
  __ CompareClassId(right, kDoubleCid, /*scratch*/ TMP);
  __ BranchIf(NOT_EQUAL, &reference_compare, Assembler::kNearJump);

  // Double values bitwise compare.
#if XLEN == 32
  __ lw(T0, FieldAddress(left, target::Double::value_offset()));
  __ lw(T1, FieldAddress(right, target::Double::value_offset()));
  __ xor_(TMP, T0, T1);
  __ lw(T0, FieldAddress(left, target::Double::value_offset() + 4));
  __ lw(T1, FieldAddress(right, target::Double::value_offset() + 4));
  __ xor_(TMP2, T0, T1);
  __ or_(TMP, TMP, TMP2);
#else
  __ ld(T0, FieldAddress(left, target::Double::value_offset()));
  __ ld(T1, FieldAddress(right, target::Double::value_offset()));
  __ xor_(TMP, T0, T1);
#endif
  __ j(&done, Assembler::kNearJump);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid, /*scratch*/ TMP);
  __ BranchIf(NOT_EQUAL, &reference_compare, Assembler::kNearJump);
  __ CompareClassId(right, kMintCid, /*scratch*/ TMP);
  __ BranchIf(NOT_EQUAL, &reference_compare, Assembler::kNearJump);
#if XLEN == 32
  __ lw(T0, FieldAddress(left, target::Mint::value_offset()));
  __ lw(T1, FieldAddress(right, target::Mint::value_offset()));
  __ xor_(TMP, T0, T1);
  __ lw(T0, FieldAddress(left, target::Mint::value_offset() + 4));
  __ lw(T1, FieldAddress(right, target::Mint::value_offset() + 4));
  __ xor_(TMP2, T0, T1);
  __ or_(TMP, TMP, TMP2);
#else
  __ ld(T0, FieldAddress(left, target::Mint::value_offset()));
  __ ld(T1, FieldAddress(right, target::Mint::value_offset()));
  __ xor_(TMP, T0, T1);
#endif
  __ j(&done, Assembler::kNearJump);

  __ Bind(&reference_compare);
  __ xor_(TMP, left, right);
  __ Bind(&done);
}

// Called only from unoptimized code. All relevant registers have been saved.
// RA: return address.
// SP + 4: left operand.
// SP + 0: right operand.
// Return TMP set to 0 if equal.
void StubCodeCompiler::GenerateUnoptimizedIdenticalWithNumberCheckStub() {
#if !defined(PRODUCT)
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(TMP);
  __ LoadFromOffset(TMP, TMP, target::Isolate::single_step_offset(),
                    kUnsignedByte);
  __ bnez(TMP, &stepping);
  __ Bind(&done_stepping);
#endif

  const Register left = A0;
  const Register right = A1;
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
  __ j(&done_stepping);
#endif
}

// Called from optimized code only.
// RA: return address.
// SP + 4: left operand.
// SP + 0: right operand.
// Return TMP set to 0 if equal.
void StubCodeCompiler::GenerateOptimizedIdenticalWithNumberCheckStub() {
  const Register left = A0;
  const Register right = A1;
  __ LoadFromOffset(left, SP, 1 * target::kWordSize);
  __ LoadFromOffset(right, SP, 0 * target::kWordSize);
  GenerateIdenticalWithNumberCheckStub(assembler, left, right);
  __ ret();
}

// Called from megamorphic call sites.
//  A0: receiver (passed to target)
//  IC_DATA_REG: MegamorphicCache (preserved)
// Passed to target:
//  FUNCTION_REG: target function
//  CODE_REG: target Code
//  ARGS_DESC_REG: arguments descriptor
void StubCodeCompiler::GenerateMegamorphicCallStub() {
  // Jump if receiver is a smi.
  Label smi_case;
  __ BranchIfSmi(A0, &smi_case);

  // Loads the cid of the object.
  __ LoadClassId(T5, A0);

  Label cid_loaded;
  __ Bind(&cid_loaded);
  __ lx(T2,
        FieldAddress(IC_DATA_REG, target::MegamorphicCache::buckets_offset()));
  __ lx(T1, FieldAddress(IC_DATA_REG, target::MegamorphicCache::mask_offset()));
  // T2: cache buckets array.
  // T1: mask as a smi.

  // Make the cid into a smi.
  __ SmiTag(T5);
  // T5: class ID of the receiver (smi).

  // Compute the table index.
  ASSERT(target::MegamorphicCache::kSpreadFactor == 7);
  // Use lsl and sub to multiply with 7 == 8 - 1.
  __ slli(T3, T5, 3);
  __ sub(T3, T3, T5);
  // T3: probe.
  Label loop;
  __ Bind(&loop);
  __ and_(T3, T3, T1);

  const intptr_t base = target::Array::data_offset();
  // T3 is smi tagged, but table entries are 16 bytes, so LSL 3.
  __ AddShifted(TMP, T2, T3, kCompressedWordSizeLog2);
  __ LoadCompressedSmiFieldFromOffset(T4, TMP, base);
  Label probe_failed;
  __ CompareObjectRegisters(T4, T5);
  __ BranchIf(NE, &probe_failed);

  Label load_target;
  __ Bind(&load_target);
  // Call the target found in the cache.  For a class id match, this is a
  // proper target for the given name and arguments descriptor.  If the
  // illegal class id was found, the target is a cache miss handler that can
  // be invoked as a normal Dart function.
  __ LoadCompressed(FUNCTION_REG,
                    FieldAddress(TMP, base + target::kCompressedWordSize));
  __ lx(A1, FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
  __ lx(ARGS_DESC_REG,
        FieldAddress(IC_DATA_REG,
                     target::CallSiteData::arguments_descriptor_offset()));
  if (!FLAG_precompiled_mode) {
    __ LoadCompressed(
        CODE_REG, FieldAddress(FUNCTION_REG, target::Function::code_offset()));
  }
  __ jr(A1);  // T0: Function, argument to lazy compile stub.

  // Probe failed, check if it is a miss.
  __ Bind(&probe_failed);
  ASSERT(kIllegalCid == 0);
  Label miss;
  __ beqz(T4, &miss);  // branch if miss.

  // Try next extry in the table.
  __ AddImmediate(T3, target::ToRawSmi(1));
  __ j(&loop);

  // Load cid for the Smi case.
  __ Bind(&smi_case);
  __ LoadImmediate(T5, kSmiCid);
  __ j(&cid_loaded);

  __ Bind(&miss);
  GenerateSwitchableCallMissStub();
}

// Input:
//   A0 - receiver
//   IC_DATA_REG - icdata
void StubCodeCompiler::GenerateICCallThroughCodeStub() {
  Label loop, found, miss;
  __ lx(T1, FieldAddress(IC_DATA_REG, target::ICData::entries_offset()));
  __ lx(ARGS_DESC_REG,
        FieldAddress(IC_DATA_REG,
                     target::CallSiteData::arguments_descriptor_offset()));
  __ AddImmediate(T1, target::Array::data_offset() - kHeapObjectTag);
  // T1: first IC entry
  __ LoadTaggedClassIdMayBeSmi(A1, A0);
  // A1: receiver cid as Smi

  __ Bind(&loop);
  __ LoadCompressedSmi(T2, Address(T1, 0));
  __ beq(A1, T2, &found);
  __ CompareImmediate(T2, target::ToRawSmi(kIllegalCid));
  __ BranchIf(EQ, &miss);

  const intptr_t entry_length =
      target::ICData::TestEntryLengthFor(1, /*tracking_exactness=*/false) *
      target::kCompressedWordSize;
  __ AddImmediate(T1, entry_length);  // Next entry.
  __ j(&loop);

  __ Bind(&found);
  if (FLAG_precompiled_mode) {
    const intptr_t entry_offset =
        target::ICData::EntryPointIndexFor(1) * target::kCompressedWordSize;
    __ LoadCompressed(A1, Address(T1, entry_offset));
    __ lx(A1, FieldAddress(A1, target::Function::entry_point_offset()));
  } else {
    const intptr_t code_offset =
        target::ICData::CodeIndexFor(1) * target::kCompressedWordSize;
    __ LoadCompressed(CODE_REG, Address(T1, code_offset));
    __ lx(A1, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  }
  __ jr(A1);

  __ Bind(&miss);
  __ LoadIsolate(A1);
  __ lx(CODE_REG, Address(A1, target::Isolate::ic_miss_code_offset()));
  __ lx(A1, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ jr(A1);
}

// Implement the monomorphic entry check for call-sites where the receiver
// might be a Smi.
//
//   A0: receiver
//   S5: MonomorphicSmiableCall object
//
//   T1,T2: clobbered
void StubCodeCompiler::GenerateMonomorphicSmiableCheckStub() {
  Label miss;
  __ LoadClassIdMayBeSmi(T1, A0);

  // Note: this stub is only used in AOT mode, hence the direct (bare) call.
  __ LoadField(
      T2,
      FieldAddress(S5, target::MonomorphicSmiableCall::expected_cid_offset()));
  __ LoadField(
      TMP,
      FieldAddress(S5, target::MonomorphicSmiableCall::entrypoint_offset()));
  __ bne(T1, T2, &miss);
  __ jr(TMP);

  __ Bind(&miss);
  __ lx(TMP, Address(THR, target::Thread::switchable_call_miss_entry_offset()));
  __ jr(TMP);
}

// Called from switchable IC calls.
//  A0: receiver
void StubCodeCompiler::GenerateSwitchableCallMissStub() {
  __ lx(CODE_REG,
        Address(THR, target::Thread::switchable_call_miss_stub_offset()));
  __ EnterStubFrame();
  // Preserve receiver, setup result slot,
  // pass Arg0: stub out and Arg1: Receiver.
  __ PushRegistersInOrder({A0, ZR, ZR, A0});
  __ CallRuntime(kSwitchableCallMissRuntimeEntry, 2);
  __ Drop(1);
  __ PopRegister(CODE_REG);     // result = stub
  __ PopRegister(IC_DATA_REG);  // result = IC

  __ PopRegister(A0);  // Restore receiver.
  __ LeaveStubFrame();

  __ lx(TMP, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                        CodeEntryKind::kNormal)));
  __ jr(TMP);
}

// Called from switchable IC calls.
//  A0: receiver
//  S5: SingleTargetCache
// Passed to target:
//  CODE_REG: target Code object
void StubCodeCompiler::GenerateSingleTargetCallStub() {
  Label miss;
  __ LoadClassIdMayBeSmi(A1, A0);
  __ lhu(T2, FieldAddress(S5, target::SingleTargetCache::lower_limit_offset()));
  __ lhu(T3, FieldAddress(S5, target::SingleTargetCache::upper_limit_offset()));

  __ blt(A1, T2, &miss);
  __ bgt(A1, T3, &miss);

  __ lx(TMP, FieldAddress(S5, target::SingleTargetCache::entry_point_offset()));
  __ lx(CODE_REG, FieldAddress(S5, target::SingleTargetCache::target_offset()));
  __ jr(TMP);

  __ Bind(&miss);
  __ EnterStubFrame();
  // Preserve receiver, setup result slot,
  // pass Arg0: Stub out and Arg1: Receiver.
  __ PushRegistersInOrder({A0, ZR, ZR, A0});
  __ CallRuntime(kSwitchableCallMissRuntimeEntry, 2);
  __ Drop(1);
  __ PopRegister(CODE_REG);  // result = stub
  __ PopRegister(S5);        // result = IC

  __ PopRegister(A0);  // Restore receiver.
  __ LeaveStubFrame();

  __ lx(TMP, FieldAddress(CODE_REG, target::Code::entry_point_offset(
                                        CodeEntryKind::kMonomorphic)));
  __ jr(TMP);
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

void StubCodeCompiler::GenerateAllocateTypedDataArrayStub(intptr_t cid) {
  const intptr_t element_size = TypedDataElementSizeInBytes(cid);
  const intptr_t max_len = TypedDataMaxNewSpaceElements(cid);
  const intptr_t scale_shift = GetScaleFactor(element_size);

  COMPILE_ASSERT(AllocateTypedDataArrayABI::kLengthReg == T2);
  COMPILE_ASSERT(AllocateTypedDataArrayABI::kResultReg == A0);

  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label call_runtime;
    NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, &call_runtime, T3));
    __ mv(T3, AllocateTypedDataArrayABI::kLengthReg);
    /* Check that length is a positive Smi. */
    /* T3: requested array length argument. */
    __ BranchIfNotSmi(T3, &call_runtime);
    __ SmiUntag(T3);
    /* Check for length >= 0 && length <= max_len. */
    /* T3: untagged array length. */
    __ CompareImmediate(T3, max_len, kObjectBytes);
    __ BranchIf(UNSIGNED_GREATER, &call_runtime);
    if (scale_shift != 0) {
      __ slli(T3, T3, scale_shift);
    }
    const intptr_t fixed_size_plus_alignment_padding =
        target::TypedData::HeaderSize() +
        target::ObjectAlignment::kObjectAlignment - 1;
    __ AddImmediate(T3, fixed_size_plus_alignment_padding);
    __ andi(T3, T3, ~(target::ObjectAlignment::kObjectAlignment - 1));
    __ lx(A0, Address(THR, target::Thread::top_offset()));

    /* T3: allocation size. */
    __ add(T4, A0, T3);
    __ bltu(T4, A0, &call_runtime); /* Fail on unsigned overflow. */

    /* Check if the allocation fits into the remaining space. */
    /* A0: potential new object start. */
    /* T4: potential next object start. */
    /* T3: allocation size. */
    __ lx(TMP, Address(THR, target::Thread::end_offset()));
    __ bgeu(T4, TMP, &call_runtime);

    /* Successfully allocated the object(s), now update top to point to */
    /* next object start and initialize the object. */
    __ sx(T4, Address(THR, target::Thread::top_offset()));
    __ AddImmediate(A0, kHeapObjectTag);
    /* Initialize the tags. */
    /* A0: new object start as a tagged pointer. */
    /* T4: new object end address. */
    /* T3: allocation size. */
    {
      __ li(T5, 0);
      __ CompareImmediate(T3, target::UntaggedObject::kSizeTagMaxSizeTag);
      compiler::Label zero_tags;
      __ BranchIf(HI, &zero_tags);
      __ slli(T5, T3,
              target::UntaggedObject::kTagBitsSizeTagPos -
                  target::ObjectAlignment::kObjectAlignmentLog2);
      __ Bind(&zero_tags);

      /* Get the class index and insert it into the tags. */
      uword tags =
          target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
      __ OrImmediate(T5, T5, tags);
      __ sx(T5, FieldAddress(A0, target::Object::tags_offset())); /* Tags. */
    }
    /* Set the length field. */
    /* A0: new object start as a tagged pointer. */
    /* T4: new object end address. */
    __ mv(T3, AllocateTypedDataArrayABI::kLengthReg); /* Array length. */
    __ StoreCompressedIntoObjectNoBarrier(
        A0, FieldAddress(A0, target::TypedDataBase::length_offset()), T3);
    /* Initialize all array elements to 0. */
    /* A0: new object start as a tagged pointer. */
    /* T4: new object end address. */
    /* T3: iterator which initially points to the start of the variable */
    /* R3: scratch register. */
    /* data area to be initialized. */
    __ AddImmediate(T3, A0, target::TypedData::HeaderSize() - 1);
    __ StoreInternalPointer(
        A0, FieldAddress(A0, target::PointerBase::data_offset()), T3);
    Label loop;
    __ Bind(&loop);
    for (intptr_t offset = 0; offset < target::kObjectAlignment;
         offset += target::kWordSize) {
      __ sx(ZR, Address(T3, offset));
    }
    // Safe to only check every kObjectAlignment bytes instead of each word.
    ASSERT(kAllocationRedZoneSize >= target::kObjectAlignment);
    __ addi(T3, T3, target::kObjectAlignment);
    __ bltu(T3, T4, &loop);

    __ Ret();

    __ Bind(&call_runtime);
  }

  __ EnterStubFrame();
  __ PushRegister(ZR);                                     // Result slot.
  __ PushImmediate(target::ToRawSmi(cid));                 // Cid
  __ PushRegister(AllocateTypedDataArrayABI::kLengthReg);  // Array length
  __ CallRuntime(kAllocateTypedDataRuntimeEntry, 2);
  __ Drop(2);  // Drop arguments.
  __ PopRegister(AllocateTypedDataArrayABI::kResultReg);
  __ LeaveStubFrame();
  __ Ret();
}

}  // namespace compiler

}  // namespace dart

#endif  // defined(TARGET_ARCH_RISCV)
