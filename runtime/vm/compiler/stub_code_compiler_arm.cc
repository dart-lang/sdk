// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"
#include "vm/globals.h"

// For `AllocateObjectInstr::WillAllocateNewOrRemembered`
// For `GenericCheckBoundInstr::UseUnboxedRepresentation`
#include "vm/compiler/backend/il.h"

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/stub_code_compiler.h"

#if defined(TARGET_ARCH_ARM)

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
  __ tst(R0, Operand(1 << target::ObjectAlignment::kNewObjectBitPosition));
  __ BranchIf(NOT_ZERO, &done);

  if (preserve_registers) {
    __ EnterCallRuntimeFrame(0);
  } else {
    __ ReserveAlignedFrameSpace(0);
  }
  // [R0] already contains first argument.
  __ mov(R1, Operand(THR));
  __ CallRuntime(kEnsureRememberedAndMarkingDeferredRuntimeEntry, 2);
  if (preserve_registers) {
    __ LeaveCallRuntimeFrame();
  }

  __ Bind(&done);
}

// Input parameters:
//   LR : return address.
//   SP : address of last argument in argument array.
//   SP + 4*R4 - 4 : address of first argument in argument array.
//   SP + 4*R4 : address of return value.
//   R9 : address of the runtime function to call.
//   R4 : number of arguments to the call.
void StubCodeCompiler::GenerateCallToRuntimeStub(Assembler* assembler) {
  const intptr_t thread_offset = target::NativeArguments::thread_offset();
  const intptr_t argc_tag_offset = target::NativeArguments::argc_tag_offset();
  const intptr_t argv_offset = target::NativeArguments::argv_offset();
  const intptr_t retval_offset = target::NativeArguments::retval_offset();

  __ ldr(CODE_REG, Address(THR, target::Thread::call_to_runtime_stub_offset()));
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
  __ StoreToOffset(R9, THR, target::Thread::vm_tag_offset());

  // Reserve space for arguments and align frame before entering C++ world.
  // target::NativeArguments are passed in registers.
  ASSERT(target::NativeArguments::StructSize() == 4 * target::kWordSize);
  __ ReserveAlignedFrameSpace(0);

  // Pass target::NativeArguments structure by value and call runtime.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * target::kWordSize);
  // Set thread in NativeArgs.
  __ mov(R0, Operand(THR));

  // There are no runtime calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * target::kWordSize);
  __ mov(R1, Operand(R4));  // Set argc in target::NativeArguments.

  ASSERT(argv_offset == 2 * target::kWordSize);
  __ add(R2, FP, Operand(R4, LSL, 2));  // Compute argv.
  // Set argv in target::NativeArguments.
  __ AddImmediate(R2,
                  target::frame_layout.param_end_from_fp * target::kWordSize);

  ASSERT(retval_offset == 3 * target::kWordSize);
  __ add(R3, R2,
         Operand(target::kWordSize));  // Retval is next to 1st argument.

  // Call runtime or redirection via simulator.
  __ blx(R9);

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(R2, THR, target::Thread::vm_tag_offset());

  // Mark that the thread has not exited generated Dart code.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(R2, THR, target::Thread::exit_through_ffi_offset());

  // Reset exit frame information in Isolate's mutator thread structure.
  __ StoreToOffset(R2, THR, target::Thread::top_exit_frame_info_offset());

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
  __ Ret();
}

void StubCodeCompiler::GenerateSharedStubGeneric(
    Assembler* assembler,
    bool save_fpu_registers,
    intptr_t self_code_stub_offset_from_thread,
    bool allow_return,
    std::function<void()> perform_runtime_call) {
  // If the target CPU does not support VFP the caller should always use the
  // non-FPU stub.
  if (save_fpu_registers && !TargetCPUFeatures::vfp_supported()) {
    __ Breakpoint();
    return;
  }

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
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR));
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
      // Reserve space for the result on the stack. This needs to be a GC
      // safe value.
      __ PushImmediate(Smi::RawValue(0));
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

// R1: The extracted method.
// R4: The type_arguments_field_offset (or 0)
// SP+0: The object from which we are tearing a method off.
void StubCodeCompiler::GenerateBuildMethodExtractorStub(
    Assembler* assembler,
    const Object& closure_allocation_stub,
    const Object& context_allocation_stub) {
  const intptr_t kReceiverOffset = target::frame_layout.param_end_from_fp + 1;

  __ EnterStubFrame();

  // Build type_arguments vector (or null)
  __ cmp(R4, Operand(0));
  __ ldr(R3, Address(THR, target::Thread::object_null_offset()), EQ);
  __ ldr(R0, Address(FP, kReceiverOffset * target::kWordSize), NE);
  __ ldr(R3, Address(R0, R4), NE);

  // Push type arguments & extracted method.
  __ PushList(1 << R3 | 1 << R1);

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
    __ blx(R0);

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
  __ blx(R1);

  // Populate closure object.
  __ Pop(R1);  // Pop context.
  __ StoreIntoObject(R0, FieldAddress(R0, target::Closure::context_offset()),
                     R1);
  __ PopList(1 << R3 | 1 << R1);  // Pop type arguments & extracted method.
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

void StubCodeCompiler::GenerateEnterSafepointStub(Assembler* assembler) {
  RegisterSet all_registers;
  all_registers.AddAllGeneralRegisters();
  __ PushRegisters(all_registers);

  SPILLS_LR_TO_FRAME(__ EnterFrame((1 << FP) | (1 << LR), 0));
  __ ReserveAlignedFrameSpace(0);
  __ ldr(R0, Address(THR, kEnterSafepointRuntimeEntry.OffsetFromThread()));
  __ blx(R0);
  RESTORES_LR_FROM_FRAME(__ LeaveFrame((1 << FP) | (1 << LR), 0));

  __ PopRegisters(all_registers);
  __ Ret();
}

void StubCodeCompiler::GenerateExitSafepointStub(Assembler* assembler) {
  RegisterSet all_registers;
  all_registers.AddAllGeneralRegisters();
  __ PushRegisters(all_registers);

  SPILLS_LR_TO_FRAME(__ EnterFrame((1 << FP) | (1 << LR), 0));
  __ ReserveAlignedFrameSpace(0);

  // Set the execution state to VM while waiting for the safepoint to end.
  // This isn't strictly necessary but enables tests to check that we're not
  // in native code anymore. See tests/ffi/function_gc_test.dart for example.
  __ LoadImmediate(R0, target::Thread::vm_execution_state());
  __ str(R0, Address(THR, target::Thread::execution_state_offset()));

  __ ldr(R0, Address(THR, kExitSafepointRuntimeEntry.OffsetFromThread()));
  __ blx(R0);
  RESTORES_LR_FROM_FRAME(__ LeaveFrame((1 << FP) | (1 << LR), 0));

  __ PopRegisters(all_registers);
  __ Ret();
}

// Call a native function within a safepoint.
//
// On entry:
//   Stack: set up for call, incl. alignment
//   R8: target to call
//
// On exit:
//   Stack: preserved
//   NOTFP, R4: clobbered, although normally callee-saved
void StubCodeCompiler::GenerateCallNativeThroughSafepointStub(
    Assembler* assembler) {
  COMPILE_ASSERT(IsAbiPreservedRegister(R4));

  // TransitionGeneratedToNative might clobber LR if it takes the slow path.
  SPILLS_RETURN_ADDRESS_FROM_LR_TO_REGISTER(__ mov(R4, Operand(LR)));

  __ LoadImmediate(R9, target::Thread::exit_through_ffi());
  __ TransitionGeneratedToNative(R8, FPREG, R9 /*volatile*/, NOTFP,
                                 /*enter_safepoint=*/true);

  __ blx(R8);

  __ TransitionNativeToGenerated(R9 /*volatile*/, NOTFP,
                                 /*exit_safepoint=*/true);

  __ bx(R4);
}

#if !defined(DART_PRECOMPILER)
void StubCodeCompiler::GenerateJITCallbackTrampolines(
    Assembler* assembler,
    intptr_t next_callback_id) {
#if defined(USING_SIMULATOR)
  // TODO(37299): FFI is not support in SIMARM.
  __ Breakpoint();
#else
  Label done;

  // TMP is volatile and not used for passing any arguments.
  COMPILE_ASSERT(!IsCalleeSavedRegister(TMP) && !IsArgumentRegister(TMP));

  for (intptr_t i = 0;
       i < NativeCallbackTrampolines::NumCallbackTrampolinesPerPage(); ++i) {
    // We don't use LoadImmediate because we need the trampoline size to be
    // fixed independently of the callback ID.
    //
    // PC points two instructions ahead of the current one -- directly where we
    // store the callback ID.
    __ ldr(TMP, Address(PC, 0));
    __ b(&done);
    __ Emit(next_callback_id + i);
  }

  ASSERT(__ CodeSize() ==
         kNativeCallbackTrampolineSize *
             NativeCallbackTrampolines::NumCallbackTrampolinesPerPage());

  __ Bind(&done);

  const intptr_t shared_stub_start = __ CodeSize();

  // Save THR (callee-saved), R4 & R5 (temporaries, callee-saved), and LR.
  COMPILE_ASSERT(StubCodeCompiler::kNativeCallbackTrampolineStackDelta == 4);
  SPILLS_LR_TO_FRAME(
      __ PushList((1 << LR) | (1 << THR) | (1 << R4) | (1 << R5)));

  // Don't rely on TMP being preserved by assembler macros anymore.
  __ mov(R4, Operand(TMP));

  COMPILE_ASSERT(IsCalleeSavedRegister(R4));
  COMPILE_ASSERT(!IsArgumentRegister(THR));

  RegisterSet argument_registers;
  argument_registers.AddAllArgumentRegisters();
  __ PushRegisters(argument_registers);

  // Load the thread, verify the callback ID and exit the safepoint.
  //
  // We exit the safepoint inside DLRT_GetThreadForNativeCallbackTrampoline
  // in order to safe code size on this shared stub.
  {
    __ EnterFrame(1 << FP, 0);
    __ ReserveAlignedFrameSpace(0);

    __ mov(R0, Operand(R4));

    // Since DLRT_GetThreadForNativeCallbackTrampoline can theoretically be
    // loaded anywhere, we use the same trick as before to ensure a predictable
    // instruction sequence.
    Label call;
    __ ldr(R1, Address(PC, 0));
    __ b(&call);
    __ Emit(
        reinterpret_cast<intptr_t>(&DLRT_GetThreadForNativeCallbackTrampoline));

    __ Bind(&call);
    __ blx(R1);
    __ mov(THR, Operand(R0));

    __ LeaveFrame(1 << FP);
  }

  __ PopRegisters(argument_registers);

  COMPILE_ASSERT(!IsArgumentRegister(R8));

  // Load the code object.
  __ LoadFromOffset(R5, THR, compiler::target::Thread::callback_code_offset());
  __ LoadFieldFromOffset(R5, R5,
                         compiler::target::GrowableObjectArray::data_offset());
  __ ldr(R5, __ ElementAddressForRegIndex(
                 /*is_load=*/true,
                 /*external=*/false,
                 /*array_cid=*/kArrayCid,
                 /*index_scale, smi-tagged=*/compiler::target::kWordSize * 2,
                 /*index_unboxed=*/false,
                 /*array=*/R5,
                 /*index=*/R4));
  __ LoadFieldFromOffset(R5, R5, compiler::target::Code::entry_point_offset());

  // On entry to the function, there will be four extra slots on the stack:
  // saved THR, R4, R5 and the return address. The target will know to skip
  // them.
  __ blx(R5);

  // EnterSafepoint clobbers R4, R5 and TMP, all saved or volatile.
  __ EnterSafepoint(R4, R5);

  // Returns.
  __ PopList((1 << PC) | (1 << THR) | (1 << R4) | (1 << R5));

  ASSERT((__ CodeSize() - shared_stub_start) == kNativeCallbackSharedStubSize);
  ASSERT(__ CodeSize() <= VirtualMemory::PageSize());

#if defined(DEBUG)
  while (__ CodeSize() < VirtualMemory::PageSize()) {
    __ Breakpoint();
  }
#endif
#endif
}
#endif  // !defined(DART_PRECOMPILER)

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
    ASSERT(!GenericCheckBoundInstr::UseUnboxedRepresentation());
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
//   R9 : address of the native function to call.
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

  // Mark that the thread is executing native code.
  __ StoreToOffset(R9, THR, target::Thread::vm_tag_offset());

  // Reserve space for the native arguments structure passed on the stack (the
  // outgoing pointer parameter to the native arguments structure is passed in
  // R0) and align frame before entering the C++ world.
  __ ReserveAlignedFrameSpace(target::NativeArguments::StructSize());

  // Initialize target::NativeArguments structure and call native function.
  // Registers R0, R1, R2, and R3 are used.

  ASSERT(thread_offset == 0 * target::kWordSize);
  // Set thread in NativeArgs.
  __ mov(R0, Operand(THR));

  // There are no native calls to closures, so we do not need to set the tag
  // bits kClosureFunctionBit and kInstanceFunctionBit in argc_tag_.
  ASSERT(argc_tag_offset == 1 * target::kWordSize);
  // Set argc in target::NativeArguments: R1 already contains argc.

  ASSERT(argv_offset == 2 * target::kWordSize);
  // Set argv in target::NativeArguments: R2 already contains argv.

  // Set retval in NativeArgs.
  ASSERT(retval_offset == 3 * target::kWordSize);
  __ add(R3, FP, Operand(2 * target::kWordSize));

  // Passing the structure by value as in runtime calls would require changing
  // Dart API for native functions.
  // For now, space is reserved on the stack and we pass a pointer to it.
  __ stm(IA, SP, (1 << R0) | (1 << R1) | (1 << R2) | (1 << R3));
  __ mov(R0, Operand(SP));  // Pass the pointer to the target::NativeArguments.

  __ mov(R1, Operand(R9));  // Pass the function entrypoint to call.

  // Call native function invocation wrapper or redirection via simulator.
  __ Call(wrapper);

  // Mark that the thread is executing Dart code.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(R2, THR, target::Thread::vm_tag_offset());

  // Mark that the thread has not exited generated Dart code.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(R2, THR, target::Thread::exit_through_ffi_offset());

  // Reset exit frame information in Isolate's mutator thread structure.
  __ StoreToOffset(R2, THR, target::Thread::top_exit_frame_info_offset());

  // Restore the global object pool after returning from runtime (old space is
  // moving, so the GOP could have been relocated).
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ SetupGlobalPoolAndDispatchTable();
  }

  __ LeaveStubFrame();
  __ Ret();
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
//   R9 : address of the native function to call.
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
  __ LoadImmediate(R0, 0);
  __ PushList((1 << R0) | (1 << R4));
  __ CallRuntime(kPatchStaticCallRuntimeEntry, 0);
  // Get Code object result and restore arguments descriptor array.
  __ PopList((1 << R0) | (1 << R4));
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ mov(CODE_REG, Operand(R0));
  __ Branch(FieldAddress(R0, target::Code::entry_point_offset()));
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
  __ LoadImmediate(R0, 0);
  __ PushList((1 << R0) | (1 << R4));
  __ CallRuntime(kFixCallersTargetRuntimeEntry, 0);
  // Get Code object result and restore arguments descriptor array.
  __ PopList((1 << R0) | (1 << R4));
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ mov(CODE_REG, Operand(R0));
  __ Branch(FieldAddress(R0, target::Code::entry_point_offset()));

  __ Bind(&monomorphic);
  // Load code pointer to this stub from the thread:
  // The one that is passed in, is not correct - it points to the code object
  // that needs to be replaced.
  __ ldr(CODE_REG,
         Address(THR, target::Thread::fix_callers_target_code_offset()));
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ LoadImmediate(R1, 0);
  __ Push(R9);  // Preserve cache (guarded CID as Smi).
  __ Push(R0);  // Preserve receiver.
  __ Push(R1);
  __ CallRuntime(kFixCallersTargetMonomorphicRuntimeEntry, 0);
  __ Pop(CODE_REG);
  __ Pop(R0);  // Restore receiver.
  __ Pop(R9);  // Restore cache (guarded CID as Smi).
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ Branch(FieldAddress(
      CODE_REG, target::Code::entry_point_offset(CodeEntryKind::kMonomorphic)));
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
  __ LoadImmediate(R0, 0);
  __ Push(R0);
  __ CallRuntime(kFixAllocationStubTargetRuntimeEntry, 0);
  // Get Code object result.
  __ Pop(R0);
  // Remove the stub frame.
  __ LeaveStubFrame();
  // Jump to the dart function.
  __ mov(CODE_REG, Operand(R0));
  __ Branch(FieldAddress(R0, target::Code::entry_point_offset()));
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
  __ AddImmediate(R1, FP,
                  target::frame_layout.param_end_from_fp * target::kWordSize);
  __ AddImmediate(R3, R0, target::Array::data_offset() - kHeapObjectTag);
  // Copy arguments from stack to array (starting at the end).
  // R1: address just beyond last argument on stack.
  // R3: address of first argument in array.
  Label enter;
  __ b(&enter);
  Label loop;
  __ Bind(&loop);
  __ ldr(R8, Address(R1, target::kWordSize, Address::PreIndex));
  // Generational barrier is needed, array is not necessarily in new space.
  __ StoreIntoObject(R0, Address(R3, R2, LSL, 1), R8);
  __ Bind(&enter);
  __ subs(R2, R2, Operand(target::ToRawSmi(1)));  // R2 is Smi.
  __ b(&loop, PL);
}

// Used by eager and lazy deoptimization. Preserve result in R0 if necessary.
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
//   | pc marker        |
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
  __ EnterDartFrame(0);
  __ LoadPoolPointer();

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
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
    if (i == CODE_REG) {
      // Save the original value of CODE_REG pushed before invoking this stub
      // instead of the value used to call this stub.
      __ ldr(IP, Address(FP, 2 * target::kWordSize));
      __ Push(IP);
    } else if (i == SP) {
      // Push(SP) has unpredictable behavior.
      __ mov(IP, Operand(SP));
      __ Push(IP);
    } else {
      __ Push(static_cast<Register>(i));
    }
  }

  if (TargetCPUFeatures::vfp_supported()) {
    ASSERT(kFpuRegisterSize == 4 * target::kWordSize);
    if (kNumberOfDRegisters > 16) {
      __ vstmd(DB_W, SP, D16, kNumberOfDRegisters - 16);
      __ vstmd(DB_W, SP, D0, 16);
    } else {
      __ vstmd(DB_W, SP, D0, kNumberOfDRegisters);
    }
  } else {
    __ AddImmediate(SP, -kNumberOfFpuRegisters * kFpuRegisterSize);
  }

  __ mov(R0, Operand(SP));  // Pass address of saved registers block.
  bool is_lazy =
      (kind == kLazyDeoptFromReturn) || (kind == kLazyDeoptFromThrow);
  __ mov(R1, Operand(is_lazy ? 1 : 0));
  __ ReserveAlignedFrameSpace(0);
  __ CallRuntime(kDeoptimizeCopyFrameRuntimeEntry, 2);
  // Result (R0) is stack-size (FP - SP) in bytes.

  if (kind == kLazyDeoptFromReturn) {
    // Restore result into R1 temporarily.
    __ ldr(R1, Address(FP, saved_result_slot_from_fp * target::kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into R1 temporarily.
    __ ldr(R1, Address(FP, saved_exception_slot_from_fp * target::kWordSize));
    __ ldr(R2, Address(FP, saved_stacktrace_slot_from_fp * target::kWordSize));
  }

  __ RestoreCodePointer();
  __ LeaveDartFrame();
  __ sub(SP, FP, Operand(R0));

  // DeoptimizeFillFrame expects a Dart frame, i.e. EnterDartFrame(0), but there
  // is no need to set the correct PC marker or load PP, since they get patched.
  __ EnterStubFrame();
  __ mov(R0, Operand(FP));  // Get last FP address.
  if (kind == kLazyDeoptFromReturn) {
    __ Push(R1);  // Preserve result as first local.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Push(R1);  // Preserve exception as first local.
    __ Push(R2);  // Preserve stacktrace as second local.
  }
  __ ReserveAlignedFrameSpace(0);
  __ CallRuntime(kDeoptimizeFillFrameRuntimeEntry, 1);  // Pass last FP in R0.
  if (kind == kLazyDeoptFromReturn) {
    // Restore result into R1.
    __ ldr(R1, Address(FP, target::frame_layout.first_local_from_fp *
                               target::kWordSize));
  } else if (kind == kLazyDeoptFromThrow) {
    // Restore result into R1.
    __ ldr(R1, Address(FP, target::frame_layout.first_local_from_fp *
                               target::kWordSize));
    __ ldr(R2, Address(FP, (target::frame_layout.first_local_from_fp - 1) *
                               target::kWordSize));
  }
  // Code above cannot cause GC.
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
  __ PushObject(NullObject());  // Space for the result.
  __ CallRuntime(kDeoptimizeMaterializeRuntimeEntry, 0);
  // Result tells stub how many bytes to remove from the expression stack
  // of the bottom-most frame. They were used as materialization arguments.
  __ Pop(R2);
  if (kind == kLazyDeoptFromReturn) {
    __ Pop(R0);  // Restore result.
  } else if (kind == kLazyDeoptFromThrow) {
    __ Pop(R1);  // Restore stacktrace.
    __ Pop(R0);  // Restore exception.
  }
  __ LeaveStubFrame();
  // Remove materialization arguments.
  __ add(SP, SP, Operand(R2, ASR, kSmiTagSize));
  // The caller is responsible for emitting the return instruction.
}

// R0: result, must be preserved
void StubCodeCompiler::GenerateDeoptimizeLazyFromReturnStub(
    Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(IP, kZapCodeReg);
  __ Push(IP);
  // Return address for "call" to deopt stub.
  WRITES_RETURN_ADDRESS_TO_LR(__ LoadImmediate(LR, kZapReturnAddress));
  __ ldr(CODE_REG,
         Address(THR, target::Thread::lazy_deopt_from_return_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromReturn);
  __ Ret();
}

// R0: exception, must be preserved
// R1: stacktrace, must be preserved
void StubCodeCompiler::GenerateDeoptimizeLazyFromThrowStub(
    Assembler* assembler) {
  // Push zap value instead of CODE_REG for lazy deopt.
  __ LoadImmediate(IP, kZapCodeReg);
  __ Push(IP);
  // Return address for "call" to deopt stub.
  WRITES_RETURN_ADDRESS_TO_LR(__ LoadImmediate(LR, kZapReturnAddress));
  __ ldr(CODE_REG,
         Address(THR, target::Thread::lazy_deopt_from_throw_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kLazyDeoptFromThrow);
  __ Ret();
}

void StubCodeCompiler::GenerateDeoptimizeStub(Assembler* assembler) {
  __ Push(CODE_REG);
  __ ldr(CODE_REG, Address(THR, target::Thread::deoptimize_stub_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);
  __ Ret();
}

// R9: ICData/MegamorphicCache
static void GenerateNoSuchMethodDispatcherBody(Assembler* assembler) {
  __ EnterStubFrame();

  __ ldr(R4,
         FieldAddress(R9, target::CallSiteData::arguments_descriptor_offset()));

  // Load the receiver.
  __ ldr(R2, FieldAddress(R4, target::ArgumentsDescriptor::size_offset()));
  __ add(IP, FP, Operand(R2, LSL, 1));  // R2 is Smi.
  __ ldr(R8, Address(IP, target::frame_layout.param_end_from_fp *
                             target::kWordSize));
  __ LoadImmediate(IP, 0);
  __ Push(IP);  // Result slot.
  __ Push(R8);  // Receiver.
  __ Push(R9);  // ICData/MegamorphicCache.
  __ Push(R4);  // Arguments descriptor.

  // Adjust arguments count.
  __ ldr(R3,
         FieldAddress(R4, target::ArgumentsDescriptor::type_args_len_offset()));
  __ cmp(R3, Operand(0));
  __ AddImmediate(R2, R2, target::ToRawSmi(1),
                  NE);  // Include the type arguments.

  // R2: Smi-tagged arguments array length.
  PushArrayOfArguments(assembler);
  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromCallStubRuntimeEntry, kNumArgs);
  __ Drop(4);
  __ Pop(R0);  // Return value.
  __ LeaveStubFrame();
  __ Ret();
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
//   R9 - icdata/megamorphic_cache
void StubCodeCompiler::GenerateNoSuchMethodDispatcherStub(
    Assembler* assembler) {
  GenerateNoSuchMethodDispatcherBody(assembler);
}

// Called for inline allocation of arrays.
// Input parameters:
//   LR: return address.
//   R1: array element type (either NULL or an instantiated type).
//   R2: array length as Smi (must be preserved).
// The newly allocated object is returned in R0.
void StubCodeCompiler::GenerateAllocateArrayStub(Assembler* assembler) {
  if (!FLAG_use_slow_path) {
    Label slow_case;
    // Compute the size to be allocated, it is based on the array length
    // and is computed as:
    // RoundedAllocationSize(
    //     (array_length * kwordSize) + target::Array::header_size()).
    __ mov(R3, Operand(R2));  // Array length.
    // Check that length is a positive Smi.
    __ tst(R3, Operand(kSmiTagMask));
    __ b(&slow_case, NE);

    __ cmp(R3, Operand(0));
    __ b(&slow_case, LT);

    // Check for maximum allowed length.
    const intptr_t max_len =
        target::ToRawSmi(target::Array::kMaxNewSpaceElements);
    __ CompareImmediate(R3, max_len);
    __ b(&slow_case, GT);

    const intptr_t cid = kArrayCid;
    NOT_IN_PRODUCT(__ LoadAllocationStatsAddress(R4, cid));
    NOT_IN_PRODUCT(__ MaybeTraceAllocation(R4, &slow_case));

    const intptr_t fixed_size_plus_alignment_padding =
        target::Array::header_size() +
        target::ObjectAlignment::kObjectAlignment - 1;
    __ LoadImmediate(R9, fixed_size_plus_alignment_padding);
    __ add(R9, R9, Operand(R3, LSL, 1));  // R3 is a Smi.
    ASSERT(kSmiTagShift == 1);
    __ bic(R9, R9, Operand(target::ObjectAlignment::kObjectAlignment - 1));

    // R9: Allocation size.
    // Potential new object start.
    __ ldr(R0, Address(THR, target::Thread::top_offset()));
    __ adds(R3, R0, Operand(R9));  // Potential next object start.
    __ b(&slow_case, CS);          // Branch if unsigned overflow.

    // Check if the allocation fits into the remaining space.
    // R0: potential new object start.
    // R3: potential next object start.
    // R9: allocation size.
    __ ldr(TMP, Address(THR, target::Thread::end_offset()));
    __ cmp(R3, Operand(TMP));
    __ b(&slow_case, CS);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    __ str(R3, Address(THR, target::Thread::top_offset()));
    __ add(R0, R0, Operand(kHeapObjectTag));

    // Initialize the tags.
    // R0: new object start as a tagged pointer.
    // R3: new object end address.
    // R9: allocation size.
    {
      const intptr_t shift = target::ObjectLayout::kTagBitsSizeTagPos -
                             target::ObjectAlignment::kObjectAlignmentLog2;

      __ CompareImmediate(R9, target::ObjectLayout::kSizeTagMaxSizeTag);
      __ mov(R8, Operand(R9, LSL, shift), LS);
      __ mov(R8, Operand(0), HI);

      // Get the class index and insert it into the tags.
      // R8: size and bit tags.
      const uword tags =
          target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
      __ LoadImmediate(TMP, tags);
      __ orr(R8, R8, Operand(TMP));
      __ str(R8,
             FieldAddress(R0, target::Array::tags_offset()));  // Store tags.
    }

    // R0: new object start as a tagged pointer.
    // R3: new object end address.
    // Store the type argument field.
    __ StoreIntoObjectNoBarrier(
        R0, FieldAddress(R0, target::Array::type_arguments_offset()), R1);

    // Set the length field.
    __ StoreIntoObjectNoBarrier(
        R0, FieldAddress(R0, target::Array::length_offset()), R2);

    // Initialize all array elements to raw_null.
    // R0: new object start as a tagged pointer.
    // R8, R9: null
    // R4: iterator which initially points to the start of the variable
    // data area to be initialized.
    // R3: new object end address.
    // R9: allocation size.

    __ LoadObject(R8, NullObject());
    __ mov(R9, Operand(R8));
    __ AddImmediate(R4, R0, target::Array::header_size() - kHeapObjectTag);
    __ InitializeFieldsNoBarrier(R0, R4, R3, R8, R9);
    __ Ret();  // Returns the newly allocated object in R0.
    // Unable to allocate the array using the fast inline code, just call
    // into the runtime.
    __ Bind(&slow_case);
  }

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ LoadImmediate(TMP, 0);
  // Setup space on stack for return value.
  // Push array length as Smi and element type.
  __ PushList((1 << R1) | (1 << R2) | (1 << IP));
  __ CallRuntime(kAllocateArrayRuntimeEntry, 2);
  // Pop arguments; result is popped in IP.
  __ PopList((1 << R1) | (1 << R2) | (1 << IP));  // R2 is restored.
  __ mov(R0, Operand(IP));
  __ LeaveStubFrame();

  // Write-barrier elimination might be enabled for this array (depending on the
  // array length). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(assembler);

  __ Ret();
}

// Called for allocation of Mint.
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

// Called for allocation of Mint.
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
  READS_RETURN_ADDRESS_FROM_LR(__ Push(LR));  // Marker for the profiler.
  SPILLS_LR_TO_FRAME(__ EnterFrame((1 << FP) | (1 << LR), 0));

  // Push code object to PC marker slot.
  __ ldr(IP, Address(R3, target::Thread::invoke_dart_code_stub_offset()));
  __ Push(IP);

  __ PushNativeCalleeSavedRegisters();

  // Set up THR, which caches the current thread in Dart code.
  if (THR != R3) {
    __ mov(THR, Operand(R3));
  }

#if defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Save the current VMTag on the stack.
  __ LoadFromOffset(R9, THR, target::Thread::vm_tag_offset());
  __ Push(R9);

  // Save top resource and top exit frame info. Use R4-6 as temporary registers.
  // StackFrameIterator reads the top exit frame info saved in this frame.
  __ LoadFromOffset(R4, THR, target::Thread::top_resource_offset());
  __ Push(R4);
  __ LoadImmediate(R8, 0);
  __ StoreToOffset(R8, THR, target::Thread::top_resource_offset());

  __ LoadFromOffset(R8, THR, target::Thread::exit_through_ffi_offset());
  __ Push(R8);
  __ LoadImmediate(R8, 0);
  __ StoreToOffset(R8, THR, target::Thread::exit_through_ffi_offset());

  __ LoadFromOffset(R9, THR, target::Thread::top_exit_frame_info_offset());
  __ StoreToOffset(R8, THR, target::Thread::top_exit_frame_info_offset());

  // target::frame_layout.exit_link_slot_from_entry_fp must be kept in sync
  // with the code below.
#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
  ASSERT(target::frame_layout.exit_link_slot_from_entry_fp == -27);
#else
  ASSERT(target::frame_layout.exit_link_slot_from_entry_fp == -28);
#endif
  __ Push(R9);

  __ EmitEntryFrameVerification(R9);

  // Mark that the thread is executing Dart code. Do this after initializing the
  // exit link for the profiler.
  __ LoadImmediate(R9, VMTag::kDartTagId);
  __ StoreToOffset(R9, THR, target::Thread::vm_tag_offset());

  // Load arguments descriptor array into R4, which is passed to Dart code.
  __ ldr(R4, Address(R1, target::VMHandles::kOffsetOfRawPtrInHandle));

  // Load number of arguments into R9 and adjust count for type arguments.
  __ ldr(R3,
         FieldAddress(R4, target::ArgumentsDescriptor::type_args_len_offset()));
  __ ldr(R9, FieldAddress(R4, target::ArgumentsDescriptor::count_offset()));
  __ cmp(R3, Operand(0));
  __ AddImmediate(R9, R9, target::ToRawSmi(1),
                  NE);  // Include the type arguments.
  __ SmiUntag(R9);

  // Compute address of 'arguments array' data area into R2.
  __ ldr(R2, Address(R2, target::VMHandles::kOffsetOfRawPtrInHandle));
  __ AddImmediate(R2, target::Array::data_offset() - kHeapObjectTag);

  // Set up arguments for the Dart call.
  Label push_arguments;
  Label done_push_arguments;
  __ CompareImmediate(R9, 0);  // check if there are arguments.
  __ b(&done_push_arguments, EQ);
  __ LoadImmediate(R1, 0);
  __ Bind(&push_arguments);
  __ ldr(R3, Address(R2));
  __ Push(R3);
  __ AddImmediate(R2, target::kWordSize);
  __ AddImmediate(R1, 1);
  __ cmp(R1, Operand(R9));
  __ b(&push_arguments, LT);
  __ Bind(&done_push_arguments);

  // Call the Dart code entrypoint.
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ SetupGlobalPoolAndDispatchTable();
  } else {
    __ LoadImmediate(PP, 0);  // GC safe value into PP.
  }
  __ ldr(CODE_REG, Address(R0, target::VMHandles::kOffsetOfRawPtrInHandle));
  __ ldr(R0, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  __ blx(R0);  // R4 is the arguments descriptor array.

  // Get rid of arguments pushed on the stack.
  __ AddImmediate(
      SP, FP,
      target::frame_layout.exit_link_slot_from_entry_fp * target::kWordSize);

  // Restore the saved top exit frame info and top resource back into the
  // Isolate structure. Uses R9 as a temporary register for this.
  __ Pop(R9);
  __ StoreToOffset(R9, THR, target::Thread::top_exit_frame_info_offset());
  __ Pop(R9);
  __ StoreToOffset(R9, THR, target::Thread::exit_through_ffi_offset());
  __ Pop(R9);
  __ StoreToOffset(R9, THR, target::Thread::top_resource_offset());

  // Restore the current VMTag from the stack.
  __ Pop(R4);
  __ StoreToOffset(R4, THR, target::Thread::vm_tag_offset());

#if defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  __ PopNativeCalleeSavedRegisters();

  __ set_constant_pool_allowed(false);

  // Restore the frame pointer and return.
  RESTORES_LR_FROM_FRAME(__ LeaveFrame((1 << FP) | (1 << LR)));
  __ Drop(1);
  __ Ret();
}

// Helper to generate space allocation of context stub.
// This does not initialise the fields of the context.
// Input:
//   R1: number of context variables.
// Output:
//   R0: new allocated RawContext object.
// Clobbered:
//   R2, R3, R8, R9
static void GenerateAllocateContext(Assembler* assembler, Label* slow_case) {
  // First compute the rounded instance size.
  // R1: number of context variables.
  const intptr_t fixed_size_plus_alignment_padding =
      target::Context::header_size() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ LoadImmediate(R2, fixed_size_plus_alignment_padding);
  __ add(R2, R2, Operand(R1, LSL, 2));
  ASSERT(kSmiTagShift == 1);
  __ bic(R2, R2, Operand(target::ObjectAlignment::kObjectAlignment - 1));

  NOT_IN_PRODUCT(__ LoadAllocationStatsAddress(R8, kContextCid));
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(R8, slow_case));
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
  __ ldr(IP, Address(THR, target::Thread::end_offset()));
  __ cmp(R3, Operand(IP));
  __ b(slow_case, CS);  // Branch if unsigned higher or equal.

  // Successfully allocated the object, now update top to point to
  // next object start and initialize the object.
  // R0: new object start (untagged).
  // R1: number of context variables.
  // R2: object size.
  // R3: next object start.
  __ str(R3, Address(THR, target::Thread::top_offset()));
  __ add(R0, R0, Operand(kHeapObjectTag));

  // Calculate the size tag.
  // R0: new object (tagged).
  // R1: number of context variables.
  // R2: object size.
  // R3: next object start.
  const intptr_t shift = target::ObjectLayout::kTagBitsSizeTagPos -
                         target::ObjectAlignment::kObjectAlignmentLog2;
  __ CompareImmediate(R2, target::ObjectLayout::kSizeTagMaxSizeTag);
  // If no size tag overflow, shift R2 left, else set R2 to zero.
  __ mov(R9, Operand(R2, LSL, shift), LS);
  __ mov(R9, Operand(0), HI);

  // Get the class index and insert it into the tags.
  // R9: size and bit tags.
  const uword tags =
      target::MakeTagWordForNewSpaceObject(kContextCid, /*instance_size=*/0);

  __ LoadImmediate(IP, tags);
  __ orr(R9, R9, Operand(IP));
  __ str(R9, FieldAddress(R0, target::Object::tags_offset()));

  // Setup up number of context variables field.
  // R0: new object.
  // R1: number of context variables as integer value (not object).
  // R2: object size.
  // R3: next object start.
  __ str(R1, FieldAddress(R0, target::Context::num_variables_offset()));
}

// Called for inline allocation of contexts.
// Input:
//   R1: number of context variables.
// Output:
//   R0: new allocated RawContext object.
// Clobbered:
//   Potentially any since is can go to runtime.
void StubCodeCompiler::GenerateAllocateContextStub(Assembler* assembler) {
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    Label slow_case;

    GenerateAllocateContext(assembler, &slow_case);

    // Setup the parent field.
    // R0: new object.
    // R2: object size.
    // R3: next object start.
    __ LoadObject(R8, NullObject());
    __ MoveRegister(R9, R8);  // Needed for InitializeFieldsNoBarrier.
    __ StoreIntoObjectNoBarrier(
        R0, FieldAddress(R0, target::Context::parent_offset()), R8);

    // Initialize the context variables.
    // R0: new object.
    // R2: object size.
    // R3: next object start.
    // R8, R9: raw null.
    __ AddImmediate(R1, R0,
                    target::Context::variable_offset(0) - kHeapObjectTag);
    __ InitializeFieldsNoBarrier(R0, R1, R3, R8, R9);

    // Done allocating and initializing the context.
    // R0: new object.
    __ Ret();

    __ Bind(&slow_case);
  }

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ LoadImmediate(R2, 0);
  __ SmiTag(R1);
  __ PushList((1 << R1) | (1 << R2));
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

  __ Ret();
}

// Called for clone of contexts.
// Input:
//   R4: context variable to clone.
// Output:
//   R0: new allocated RawContext object.
// Clobbered:
//   Potentially any since it can go to runtime.
void StubCodeCompiler::GenerateCloneContextStub(Assembler* assembler) {
  {
    Label slow_case;

    // Load num. variable in the existing context.
    __ ldr(R1, FieldAddress(R4, target::Context::num_variables_offset()));

    GenerateAllocateContext(assembler, &slow_case);

    // Load parent in the existing context.
    __ ldr(R2, FieldAddress(R4, target::Context::parent_offset()));
    // Setup the parent field.
    // R0: new object.
    __ StoreIntoObjectNoBarrier(
        R0, FieldAddress(R0, target::Context::parent_offset()), R2);

    // Clone the context variables.
    // R0: new object.
    // R1: number of context variables.
    {
      Label loop, done;
      __ AddImmediate(R2, R0,
                      target::Context::variable_offset(0) - kHeapObjectTag);
      __ AddImmediate(R3, R4,
                      target::Context::variable_offset(0) - kHeapObjectTag);

      __ Bind(&loop);
      __ subs(R1, R1, Operand(1));
      __ b(&done, MI);

      __ ldr(R9, Address(R3, R1, LSL, target::kWordSizeLog2));
      __ str(R9, Address(R2, R1, LSL, target::kWordSizeLog2));

      __ b(&loop, NE);  // Loop if R1 not zero.

      __ Bind(&done);
    }

    // Done allocating and initializing the context.
    // R0: new object.
    __ Ret();

    __ Bind(&slow_case);
  }

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  // Setup space on stack for return value.
  __ LoadImmediate(R0, 0);
  __ PushRegisterPair(R4, R0);
  __ CallRuntime(kCloneContextRuntimeEntry, 1);  // Clone context.
  // R4: Pop number of context variables argument.
  // R0: Pop the new context object.
  __ PopRegisterPair(R4, R0);

  // Write-barrier elimination might be enabled for this context (depending on
  // the size). To be sure we will check if the allocated object is in old
  // space and if so call a leaf runtime to add it to the remembered set.
  EnsureIsNewOrRemembered(assembler, /*preserve_registers=*/false);

  // R0: new object
  // Restore the frame pointer.
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateWriteBarrierWrappersStub(Assembler* assembler) {
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    if ((kDartAvailableCpuRegs & (1 << i)) == 0) continue;

    Register reg = static_cast<Register>(i);
    intptr_t start = __ CodeSize();
    SPILLS_LR_TO_FRAME(__ PushList((1 << LR) | (1 << kWriteBarrierObjectReg)));
    __ mov(kWriteBarrierObjectReg, Operand(reg));
    __ Call(Address(THR, target::Thread::write_barrier_entry_point_offset()));
    RESTORES_LR_FROM_FRAME(
        __ PopList((1 << LR) | (1 << kWriteBarrierObjectReg)));
    READS_RETURN_ADDRESS_FROM_LR(__ bx(LR));
    intptr_t end = __ CodeSize();

    RELEASE_ASSERT(end - start == kStoreBufferWrapperSize);
  }
}

// Helper stub to implement Assembler::StoreIntoObject.
// Input parameters:
//   R1: Object (old)
//   R0: Value (old or new)
//   R9: Slot
// If R0 is new, add R1 to the store buffer. Otherwise R0 is old, mark R0
// and add it to the mark list.
COMPILE_ASSERT(kWriteBarrierObjectReg == R1);
COMPILE_ASSERT(kWriteBarrierValueReg == R0);
COMPILE_ASSERT(kWriteBarrierSlotReg == R9);
static void GenerateWriteBarrierStubHelper(Assembler* assembler,
                                           Address stub_code,
                                           bool cards) {
  Label add_to_mark_stack, remember_card;
  __ tst(R0, Operand(1 << target::ObjectAlignment::kNewObjectBitPosition));
  __ b(&add_to_mark_stack, ZERO);

  if (cards) {
    __ ldr(TMP, FieldAddress(R1, target::Object::tags_offset()));
    __ tst(TMP, Operand(1 << target::ObjectLayout::kCardRememberedBit));
    __ b(&remember_card, NOT_ZERO);
  } else {
#if defined(DEBUG)
    Label ok;
    __ ldr(TMP, FieldAddress(R1, target::Object::tags_offset()));
    __ tst(TMP, Operand(1 << target::ObjectLayout::kCardRememberedBit));
    __ b(&ok, ZERO);
    __ Stop("Wrong barrier");
    __ Bind(&ok);
#endif
  }

  // Save values being destroyed.
  __ PushList((1 << R2) | (1 << R3) | (1 << R4));

  // Atomically set the remembered bit of the object header.
  ASSERT(target::Object::tags_offset() == 0);
  __ sub(R3, R1, Operand(kHeapObjectTag));
  // R3: Untagged address of header word (ldrex/strex do not support offsets).
  Label retry;
  __ Bind(&retry);
  __ ldrex(R2, R3);
  __ bic(R2, R2, Operand(1 << target::ObjectLayout::kOldAndNotRememberedBit));
  __ strex(R4, R2, R3);
  __ cmp(R4, Operand(1));
  __ b(&retry, EQ);

  // Load the StoreBuffer block out of the thread. Then load top_ out of the
  // StoreBufferBlock and add the address to the pointers_.
  __ ldr(R4, Address(THR, target::Thread::store_buffer_block_offset()));
  __ ldr(R2, Address(R4, target::StoreBufferBlock::top_offset()));
  __ add(R3, R4, Operand(R2, LSL, target::kWordSizeLog2));
  __ str(R1, Address(R3, target::StoreBufferBlock::pointers_offset()));

  // Increment top_ and check for overflow.
  // R2: top_.
  // R4: StoreBufferBlock.
  Label overflow;
  __ add(R2, R2, Operand(1));
  __ str(R2, Address(R4, target::StoreBufferBlock::top_offset()));
  __ CompareImmediate(R2, target::StoreBufferBlock::kSize);
  // Restore values.
  __ PopList((1 << R2) | (1 << R3) | (1 << R4));
  __ b(&overflow, EQ);
  __ Ret();

  // Handle overflow: Call the runtime leaf function.
  __ Bind(&overflow);
  // Setup frame, push callee-saved registers.

  __ Push(CODE_REG);
  __ ldr(CODE_REG, stub_code);
  __ EnterCallRuntimeFrame(0 * target::kWordSize);
  __ mov(R0, Operand(THR));
  __ CallRuntime(kStoreBufferBlockProcessRuntimeEntry, 1);
  // Restore callee-saved registers, tear down frame.
  __ LeaveCallRuntimeFrame();
  __ Pop(CODE_REG);
  __ Ret();

  __ Bind(&add_to_mark_stack);
  __ PushList((1 << R2) | (1 << R3) | (1 << R4));  // Spill.

  Label marking_retry, lost_race, marking_overflow;
  // Atomically clear kOldAndNotMarkedBit.
  ASSERT(target::Object::tags_offset() == 0);
  __ sub(R3, R0, Operand(kHeapObjectTag));
  // R3: Untagged address of header word (ldrex/strex do not support offsets).
  __ Bind(&marking_retry);
  __ ldrex(R2, R3);
  __ tst(R2, Operand(1 << target::ObjectLayout::kOldAndNotMarkedBit));
  __ b(&lost_race, ZERO);
  __ bic(R2, R2, Operand(1 << target::ObjectLayout::kOldAndNotMarkedBit));
  __ strex(R4, R2, R3);
  __ cmp(R4, Operand(1));
  __ b(&marking_retry, EQ);

  __ ldr(R4, Address(THR, target::Thread::marking_stack_block_offset()));
  __ ldr(R2, Address(R4, target::MarkingStackBlock::top_offset()));
  __ add(R3, R4, Operand(R2, LSL, target::kWordSizeLog2));
  __ str(R0, Address(R3, target::MarkingStackBlock::pointers_offset()));
  __ add(R2, R2, Operand(1));
  __ str(R2, Address(R4, target::MarkingStackBlock::top_offset()));
  __ CompareImmediate(R2, target::MarkingStackBlock::kSize);
  __ PopList((1 << R4) | (1 << R2) | (1 << R3));  // Unspill.
  __ b(&marking_overflow, EQ);
  __ Ret();

  __ Bind(&marking_overflow);
  __ Push(CODE_REG);
  __ ldr(CODE_REG, stub_code);
  __ EnterCallRuntimeFrame(0 * target::kWordSize);
  __ mov(R0, Operand(THR));
  __ CallRuntime(kMarkingStackBlockProcessRuntimeEntry, 1);
  __ LeaveCallRuntimeFrame();
  __ Pop(CODE_REG);
  __ Ret();

  __ Bind(&lost_race);
  __ PopList((1 << R2) | (1 << R3) | (1 << R4));  // Unspill.
  __ Ret();

  if (cards) {
    Label remember_card_slow;

    // Get card table.
    __ Bind(&remember_card);
    __ AndImmediate(TMP, R1, target::kOldPageMask);  // OldPage.
    __ ldr(TMP,
           Address(TMP, target::OldPage::card_table_offset()));  // Card table.
    __ cmp(TMP, Operand(0));
    __ b(&remember_card_slow, EQ);

    // Dirty the card.
    __ AndImmediate(TMP, R1, target::kOldPageMask);  // OldPage.
    __ sub(R9, R9, Operand(TMP));                    // Offset in page.
    __ ldr(TMP,
           Address(TMP, target::OldPage::card_table_offset()));  // Card table.
    __ add(TMP, TMP,
           Operand(R9, LSR,
                   target::OldPage::kBytesPerCardLog2));  // Card address.
    __ strb(R1,
            Address(TMP, 0));  // Low byte of R0 is non-zero from object tag.
    __ Ret();

    // Card table not yet allocated.
    __ Bind(&remember_card_slow);
    __ Push(CODE_REG);
    __ Push(R0);
    __ Push(R1);
    __ ldr(CODE_REG, stub_code);
    __ mov(R0, Operand(R1));  // Arg0 = Object
    __ mov(R1, Operand(R9));  // Arg1 = Slot
    __ EnterCallRuntimeFrame(0);
    __ CallRuntime(kRememberCardRuntimeEntry, 2);
    __ LeaveCallRuntimeFrame();
    __ Pop(R1);
    __ Pop(R0);
    __ Pop(CODE_REG);
    __ Ret();
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
  // R1
  const Register kTagsReg = R2;
  // kAllocationStubTypeArgumentsReg = R3

  {
    Label slow_case;

    const Register kNewTopReg = R8;

    // Bump allocation.
    {
      const Register kEndReg = R1;
      const Register kInstanceSizeReg = R9;

      __ ExtractInstanceSizeFromTags(kInstanceSizeReg, kTagsReg);

      // Load two words from Thread::top: top and end.
      // kInstanceReg: potential next object start.
      __ ldrd(kInstanceReg, kEndReg, THR, target::Thread::top_offset());

      __ add(kNewTopReg, kInstanceReg, Operand(kInstanceSizeReg));

      __ CompareRegisters(kEndReg, kNewTopReg);
      __ b(&slow_case, UNSIGNED_LESS_EQUAL);

      // Successfully allocated the object, now update top to point to
      // next object start and store the class in the class field of object.
      __ str(kNewTopReg, Address(THR, target::Thread::top_offset()));
    }  //  kEndReg = R1, kInstanceSizeReg = R9

    // Tags.
    __ str(kTagsReg, Address(kInstanceReg, target::Object::tags_offset()));

    // Initialize the remaining words of the object.
    {
      const Register kFieldReg = R1;
      const Register kNullReg = R9;

      __ LoadObject(kNullReg, NullObject());

      __ AddImmediate(kFieldReg, kInstanceReg,
                      target::Instance::first_field_offset());
      Label done, init_loop;
      __ Bind(&init_loop);
      __ CompareRegisters(kFieldReg, kNewTopReg);
      __ b(&done, UNSIGNED_GREATER_EQUAL);
      __ str(kNullReg,
             Address(kFieldReg, target::kWordSize, Address::PostIndex));
      __ b(&init_loop);

      __ Bind(&done);
    }  // kFieldReg = R1, kNullReg = R9

    // Store parameterized type.
    if (is_cls_parameterized) {
      Label not_parameterized_case;

      const Register kClsIdReg = R2;
      const Register kTypeOffestReg = R9;

      __ ExtractClassIdFromTags(kClsIdReg, kTagsReg);

      // Load class' type_arguments_field offset in words.
      __ LoadClassById(kTypeOffestReg, kClsIdReg);
      __ ldr(
          kTypeOffestReg,
          FieldAddress(kTypeOffestReg,
                       target::Class::
                           host_type_arguments_field_offset_in_words_offset()));

      // Set the type arguments in the new object.
      __ StoreIntoObjectNoBarrier(
          kInstanceReg,
          Address(kInstanceReg, kTypeOffestReg, LSL, target::kWordSizeLog2),
          kAllocationStubTypeArgumentsReg);

      __ Bind(&not_parameterized_case);
    }  // kClsIdReg = R1, kTypeOffestReg = R9

    __ AddImmediate(kInstanceReg, kInstanceReg, kHeapObjectTag);

    __ Ret();

    __ Bind(&slow_case);
  }  // kNewTopReg = R8

  // Fall back on slow case:
  {
    const Register kStubReg = R8;

    if (!is_cls_parameterized) {
      __ LoadObject(kAllocationStubTypeArgumentsReg, NullObject());
    }

    // Tail call to generic allocation stub.
    __ ldr(kStubReg,
           Address(THR,
                   target::Thread::allocate_object_slow_entry_point_offset()));
    __ bx(kStubReg);
  }  // kStubReg = R8
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
  const Register kClsReg = R1;
  const Register kTagsReg = R2;
  // kAllocationStubTypeArgumentsReg = R3

  if (!FLAG_use_bare_instructions) {
    __ ldr(CODE_REG,
           Address(THR, target::Thread::call_to_runtime_stub_offset()));
  }

  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();

  __ ExtractClassIdFromTags(kInstanceReg, kTagsReg);
  __ LoadClassById(kClsReg, kInstanceReg);

  __ LoadObject(kInstanceReg, NullObject());

  // Pushes result slot, then parameter class.
  __ PushRegisterPair(kClsReg, kInstanceReg);

  // Should be Object::null() if class is non-parameterized.
  __ Push(kAllocationStubTypeArgumentsReg);

  __ CallRuntime(kAllocateObjectRuntimeEntry, 2);

  // Load result off the stack into result register.
  __ ldr(kInstanceReg, Address(SP, 2 * target::kWordSize));

  // Write-barrier elimination is enabled for [cls] and we therefore need to
  // ensure that the object is in new-space or has remembered bit set.
  EnsureIsNewOrRemembered(assembler, /*preserve_registers=*/false);

  __ LeaveDartFrameAndReturn();
}

// Called for inline allocation of objects.
void StubCodeCompiler::GenerateAllocationStubForClass(
    Assembler* assembler,
    UnresolvedPcRelativeCalls* unresolved_calls,
    const Class& cls,
    const Code& allocate_object,
    const Code& allocat_object_parametrized) {
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
  const Register kTagsReg = R2;
  // kAllocationStubTypeArgumentsReg = R3

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
        __ ldr(PC,
               Address(THR,
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
        __ ldr(
            PC,
            Address(THR, target::Thread::allocate_object_entry_point_offset()));
      }
    }
  } else {
    if (!is_cls_parameterized) {
      __ LoadObject(kAllocationStubTypeArgumentsReg, NullObject());
    }
    __ ldr(PC,
           Address(THR,
                   target::Thread::allocate_object_slow_entry_point_offset()));
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
  __ ldr(R2, FieldAddress(R4, target::ArgumentsDescriptor::count_offset()));
  __ add(IP, FP, Operand(R2, LSL, 1));  // R2 is Smi.
  __ ldr(R8, Address(IP, target::frame_layout.param_end_from_fp *
                             target::kWordSize));

  // Load the function.
  __ ldr(R6, FieldAddress(R8, target::Closure::function_offset()));

  // Push space for the return value.
  // Push the receiver.
  // Push arguments descriptor array.
  __ LoadImmediate(IP, 0);
  __ PushList((1 << R4) | (1 << R6) | (1 << R8) | (1 << IP));

  // Adjust arguments count.
  __ ldr(R3,
         FieldAddress(R4, target::ArgumentsDescriptor::type_args_len_offset()));
  __ cmp(R3, Operand(0));
  __ AddImmediate(R2, R2, target::ToRawSmi(1),
                  NE);  // Include the type arguments.

  // R2: Smi-tagged arguments array length.
  PushArrayOfArguments(assembler);

  const intptr_t kNumArgs = 4;
  __ CallRuntime(kNoSuchMethodFromPrologueRuntimeEntry, kNumArgs);
  // noSuchMethod on closures always throws an error, so it will never return.
  __ bkpt(0);
}

//  R8: function object.
//  R9: inline cache data object.
// Cannot use function object from ICData as it may be the inlined
// function and not the top-scope function.
void StubCodeCompiler::GenerateOptimizedUsageCounterIncrement(
    Assembler* assembler) {
  Register ic_reg = R9;
  Register func_reg = R8;
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }
  if (FLAG_trace_optimized_ic_calls) {
    __ EnterStubFrame();
    __ PushList((1 << R9) | (1 << R8));  // Preserve.
    __ Push(ic_reg);                     // Argument.
    __ Push(func_reg);                   // Argument.
    __ CallRuntime(kTraceICCallRuntimeEntry, 2);
    __ Drop(2);                         // Discard argument;
    __ PopList((1 << R9) | (1 << R8));  // Restore.
    __ LeaveStubFrame();
  }
  __ ldr(TMP, FieldAddress(func_reg, target::Function::usage_counter_offset()));
  __ add(TMP, TMP, Operand(1));
  __ str(TMP, FieldAddress(func_reg, target::Function::usage_counter_offset()));
}

// Loads function into 'temp_reg'.
void StubCodeCompiler::GenerateUsageCounterIncrement(Assembler* assembler,
                                                     Register temp_reg) {
  if (FLAG_precompiled_mode) {
    __ Breakpoint();
    return;
  }
  if (FLAG_optimization_counter_threshold >= 0) {
    Register ic_reg = R9;
    Register func_reg = temp_reg;
    ASSERT(temp_reg == R8);
    __ Comment("Increment function counter");
    __ ldr(func_reg, FieldAddress(ic_reg, target::ICData::owner_offset()));
    __ ldr(TMP,
           FieldAddress(func_reg, target::Function::usage_counter_offset()));
    __ add(TMP, TMP, Operand(1));
    __ str(TMP,
           FieldAddress(func_reg, target::Function::usage_counter_offset()));
  }
}

// Note: R9 must be preserved.
// Attempt a quick Smi operation for known operations ('kind'). The ICData
// must have been primed with a Smi/Smi check that will be used for counting
// the invocations.
static void EmitFastSmiOp(Assembler* assembler,
                          Token::Kind kind,
                          intptr_t num_args,
                          Label* not_smi_or_overflow) {
  __ Comment("Fast Smi op");
  __ ldr(R0, Address(SP, 1 * target::kWordSize));  // Left.
  __ ldr(R1, Address(SP, 0 * target::kWordSize));  // Right.
  __ orr(TMP, R0, Operand(R1));
  __ tst(TMP, Operand(kSmiTagMask));
  __ b(not_smi_or_overflow, NE);
  switch (kind) {
    case Token::kADD: {
      __ adds(R0, R1, Operand(R0));   // Adds.
      __ b(not_smi_or_overflow, VS);  // Branch if overflow.
      break;
    }
    case Token::kLT: {
      __ cmp(R0, Operand(R1));
      __ LoadObject(R0, CastHandle<Object>(TrueObject()), LT);
      __ LoadObject(R0, CastHandle<Object>(FalseObject()), GE);
      break;
    }
    case Token::kEQ: {
      __ cmp(R0, Operand(R1));
      __ LoadObject(R0, CastHandle<Object>(TrueObject()), EQ);
      __ LoadObject(R0, CastHandle<Object>(FalseObject()), NE);
      break;
    }
    default:
      UNIMPLEMENTED();
  }
  // R9: IC data object (preserved).
  __ ldr(R8, FieldAddress(R9, target::ICData::entries_offset()));
  // R8: ic_data_array with check entries: classes and target functions.
  __ AddImmediate(R8, target::Array::data_offset() - kHeapObjectTag);
// R8: points directly to the first ic data array element.
#if defined(DEBUG)
  // Check that first entry is for Smi/Smi.
  Label error, ok;
  const intptr_t imm_smi_cid = target::ToRawSmi(kSmiCid);
  __ ldr(R1, Address(R8, 0));
  __ CompareImmediate(R1, imm_smi_cid);
  __ b(&error, NE);
  __ ldr(R1, Address(R8, target::kWordSize));
  __ CompareImmediate(R1, imm_smi_cid);
  __ b(&ok, EQ);
  __ Bind(&error);
  __ Stop("Incorrect IC data");
  __ Bind(&ok);
#endif
  if (FLAG_optimization_counter_threshold >= 0) {
    // Update counter, ignore overflow.
    const intptr_t count_offset =
        target::ICData::CountIndexFor(num_args) * target::kWordSize;
    __ LoadFromOffset(R1, R8, count_offset);
    __ adds(R1, R1, Operand(target::ToRawSmi(1)));
    __ StoreIntoSmiField(Address(R8, count_offset), R1);
  }
  __ Ret();
}

// Saves the offset of the target entry-point (from the Function) into R3.
//
// Must be the first code generated, since any code before will be skipped in
// the unchecked entry-point.
static void GenerateRecordEntryPoint(Assembler* assembler) {
  Label done;
  __ mov(R3, Operand(target::Function::entry_point_offset() - kHeapObjectTag));
  __ b(&done);
  __ BindUncheckedEntryPoint();
  __ mov(
      R3,
      Operand(target::Function::entry_point_offset(CodeEntryKind::kUnchecked) -
              kHeapObjectTag));
  __ Bind(&done);
}

// Generate inline cache check for 'num_args'.
//  R0: receiver (if instance call)
//  R9: ICData
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
    GenerateUsageCounterIncrement(assembler, /* scratch */ R8);
  }

  ASSERT(exactness == kIgnoreExactness);  // Unimplemented.
  __ CheckCodePointer();
  ASSERT(num_args == 1 || num_args == 2);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == num_args.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ ldr(R8, FieldAddress(R9, target::ICData::state_bits_offset()));
    ASSERT(target::ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ and_(R8, R8, Operand(target::ICData::NumArgsTestedMask()));
    __ CompareImmediate(R8, num_args);
    __ b(&ok, EQ);
    __ Stop("Incorrect stub for IC data");
    __ Bind(&ok);
  }
#endif  // DEBUG

#if !defined(PRODUCT)
  Label stepping, done_stepping;
  if (optimized == kUnoptimized) {
    __ Comment("Check single stepping");
    __ LoadIsolate(R8);
    __ ldrb(R8, Address(R8, target::Isolate::single_step_offset()));
    __ CompareImmediate(R8, 0);
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
  // R9: IC data object (preserved).
  __ ldr(R8, FieldAddress(R9, target::ICData::entries_offset()));
  // R8: ic_data_array with check entries: classes and target functions.
  const int kIcDataOffset = target::Array::data_offset() - kHeapObjectTag;
  // R8: points at the IC data array.

  if (type == kInstanceCall) {
    __ LoadTaggedClassIdMayBeSmi(R0, R0);
    __ ldr(R4, FieldAddress(
                   R9, target::CallSiteData::arguments_descriptor_offset()));
    if (num_args == 2) {
      __ ldr(R1, FieldAddress(R4, target::ArgumentsDescriptor::count_offset()));
      __ sub(R1, R1, Operand(target::ToRawSmi(2)));
      __ ldr(R1, Address(SP, R1, LSL, 1));  // R1 (argument_count - 2) is Smi.
      __ LoadTaggedClassIdMayBeSmi(R1, R1);
    }
  } else {
    // Load arguments descriptor into R4.
    __ ldr(R4, FieldAddress(
                   R9, target::CallSiteData::arguments_descriptor_offset()));

    // Get the receiver's class ID (first read number of arguments from
    // arguments descriptor array and then access the receiver from the stack).
    __ ldr(R1, FieldAddress(R4, target::ArgumentsDescriptor::count_offset()));
    __ sub(R1, R1, Operand(target::ToRawSmi(1)));
    // R1: argument_count - 1 (smi).

    __ ldr(R0, Address(SP, R1, LSL, 1));  // R1 (argument_count - 1) is Smi.
    __ LoadTaggedClassIdMayBeSmi(R0, R0);

    if (num_args == 2) {
      __ sub(R1, R1, Operand(target::ToRawSmi(1)));
      __ ldr(R1, Address(SP, R1, LSL, 1));  // R1 (argument_count - 2) is Smi.
      __ LoadTaggedClassIdMayBeSmi(R1, R1);
    }
  }
  // R0: first argument class ID as Smi.
  // R1: second argument class ID as Smi.
  // R4: args descriptor

  // Loop that checks if there is an IC data match.
  Label loop, found, miss;
  __ Comment("ICData loop");

  // We unroll the generic one that is generated once more than the others.
  const bool optimize = kind == Token::kILLEGAL;

  __ Bind(&loop);
  for (int unroll = optimize ? 4 : 2; unroll >= 0; unroll--) {
    Label update;

    __ ldr(R2, Address(R8, kIcDataOffset));
    __ cmp(R0, Operand(R2));  // Class id match?
    if (num_args == 2) {
      __ b(&update, NE);  // Continue.
      __ ldr(R2, Address(R8, kIcDataOffset + target::kWordSize));
      __ cmp(R1, Operand(R2));  // Class id match?
    }
    __ b(&found, EQ);  // Break.

    __ Bind(&update);

    const intptr_t entry_size = target::ICData::TestEntryLengthFor(
                                    num_args, exactness == kCheckExactness) *
                                target::kWordSize;
    __ AddImmediate(R8, entry_size);  // Next entry.

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
  __ ldr(R1, FieldAddress(R4, target::ArgumentsDescriptor::count_offset()));
  __ sub(R1, R1, Operand(target::ToRawSmi(1)));
  // R1: argument_count - 1 (smi).
  __ add(R1, SP, Operand(R1, LSL, 1));  // R1 is Smi.
  // R1: address of receiver.
  // Create a stub frame as we are pushing some objects on the stack before
  // calling into the runtime.
  __ EnterStubFrame();
  __ LoadImmediate(R0, 0);
  // Preserve IC data object and arguments descriptor array and
  // setup space on stack for result (target code object).
  RegList regs = (1 << R0) | (1 << R4) | (1 << R9);
  if (save_entry_point) {
    __ SmiTag(R3);
    regs |= 1 << R3;
  }
  __ PushList(regs);
  // Push call arguments.
  for (intptr_t i = 0; i < num_args; i++) {
    __ LoadFromOffset(TMP, R1, -i * target::kWordSize);
    __ Push(TMP);
  }
  // Pass IC data object.
  __ Push(R9);
  __ CallRuntime(handle_ic_miss, num_args + 1);
  // Remove the call arguments pushed earlier, including the IC data object.
  __ Drop(num_args + 1);
  // Pop returned function object into R0.
  // Restore arguments descriptor array and IC data array.
  __ PopList(regs);
  if (save_entry_point) {
    __ SmiUntag(R3);
  }
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  Label call_target_function;
  if (!FLAG_lazy_dispatchers) {
    GenerateDispatcherCode(assembler, &call_target_function);
  } else {
    __ b(&call_target_function);
  }

  __ Bind(&found);
  // R8: pointer to an IC data check group.
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(num_args) * target::kWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(num_args) * target::kWordSize;
  __ LoadFromOffset(R0, R8, kIcDataOffset + target_offset);

  if (FLAG_optimization_counter_threshold >= 0) {
    __ Comment("Update caller's counter");
    __ LoadFromOffset(R1, R8, kIcDataOffset + count_offset);
    // Ignore overflow.
    __ adds(R1, R1, Operand(target::ToRawSmi(1)));
    __ StoreIntoSmiField(Address(R8, kIcDataOffset + count_offset), R1);
  }

  __ Comment("Call target");
  __ Bind(&call_target_function);
  // R0: target function.
  __ ldr(CODE_REG, FieldAddress(R0, target::Function::code_offset()));

  if (save_entry_point) {
    __ Branch(Address(R0, R3));
  } else {
    __ Branch(FieldAddress(R0, target::Function::entry_point_offset()));
  }

#if !defined(PRODUCT)
  if (optimized == kUnoptimized) {
    __ Bind(&stepping);
    __ EnterStubFrame();
    if (type == kInstanceCall) {
      __ Push(R0);  // Preserve receiver.
    }
    RegList regs = 1 << R9;
    if (save_entry_point) {
      regs |= 1 << R3;
      __ SmiTag(R3);  // Entry-point is not Smi.
    }
    __ PushList(regs);  // Preserve IC data and entry-point.
    __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
    __ PopList(regs);  // Restore IC data and entry-point
    if (save_entry_point) {
      __ SmiUntag(R3);
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

//  R0: receiver
//  R9: ICData
//  LR: return address
void StubCodeCompiler::GenerateOneArgCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

//  R0: receiver
//  R9: ICData
//  LR: return address
void StubCodeCompiler::GenerateOneArgCheckInlineCacheWithExactnessCheckStub(
    Assembler* assembler) {
  __ Stop("Unimplemented");
}

//  R0: receiver
//  R9: ICData
//  LR: return address
void StubCodeCompiler::GenerateTwoArgsCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

//  R0: receiver
//  R9: ICData
//  LR: return address
void StubCodeCompiler::GenerateSmiAddInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kADD,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

//  R0: receiver
//  R9: ICData
//  LR: return address
void StubCodeCompiler::GenerateSmiLessInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kLT,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

//  R0: receiver
//  R9: ICData
//  LR: return address
void StubCodeCompiler::GenerateSmiEqualInlineCacheStub(Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kEQ,
      kUnoptimized, kInstanceCall, kIgnoreExactness);
}

//  R0: receiver
//  R9: ICData
//  R8: Function
//  LR: return address
void StubCodeCompiler::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kInlineCacheMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kIgnoreExactness);
}

//  R0: receiver
//  R9: ICData
//  R8: Function
//  LR: return address
void StubCodeCompiler::
    GenerateOneArgOptimizedCheckInlineCacheWithExactnessCheckStub(
        Assembler* assembler) {
  __ Stop("Unimplemented");
}

//  R0: receiver
//  R9: ICData
//  R8: Function
//  LR: return address
void StubCodeCompiler::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kInlineCacheMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kOptimized, kInstanceCall, kIgnoreExactness);
}

//  R9: ICData
//  LR: return address
void StubCodeCompiler::GenerateZeroArgsUnoptimizedStaticCallStub(
    Assembler* assembler) {
  GenerateRecordEntryPoint(assembler);
  GenerateUsageCounterIncrement(assembler, /* scratch */ R8);
#if defined(DEBUG)
  {
    Label ok;
    // Check that the IC data array has NumArgsTested() == 0.
    // 'NumArgsTested' is stored in the least significant bits of 'state_bits'.
    __ ldr(R8, FieldAddress(R9, target::ICData::state_bits_offset()));
    ASSERT(target::ICData::NumArgsTestedShift() == 0);  // No shift needed.
    __ and_(R8, R8, Operand(target::ICData::NumArgsTestedMask()));
    __ CompareImmediate(R8, 0);
    __ b(&ok, EQ);
    __ Stop("Incorrect IC data for unoptimized static call");
    __ Bind(&ok);
  }
#endif  // DEBUG

#if !defined(PRODUCT)
  // Check single stepping.
  Label stepping, done_stepping;
  __ LoadIsolate(R8);
  __ ldrb(R8, Address(R8, target::Isolate::single_step_offset()));
  __ CompareImmediate(R8, 0);
  __ b(&stepping, NE);
  __ Bind(&done_stepping);
#endif

  // R9: IC data object (preserved).
  __ ldr(R8, FieldAddress(R9, target::ICData::entries_offset()));
  // R8: ic_data_array with entries: target functions and count.
  __ AddImmediate(R8, target::Array::data_offset() - kHeapObjectTag);
  // R8: points directly to the first ic data array element.
  const intptr_t target_offset =
      target::ICData::TargetIndexFor(0) * target::kWordSize;
  const intptr_t count_offset =
      target::ICData::CountIndexFor(0) * target::kWordSize;

  if (FLAG_optimization_counter_threshold >= 0) {
    // Increment count for this call, ignore overflow.
    __ LoadFromOffset(R1, R8, count_offset);
    __ adds(R1, R1, Operand(target::ToRawSmi(1)));
    __ StoreIntoSmiField(Address(R8, count_offset), R1);
  }

  // Load arguments descriptor into R4.
  __ ldr(R4,
         FieldAddress(R9, target::CallSiteData::arguments_descriptor_offset()));

  // Get function and call it, if possible.
  __ LoadFromOffset(R0, R8, target_offset);
  __ ldr(CODE_REG, FieldAddress(R0, target::Function::code_offset()));

  __ Branch(Address(R0, R3));

#if !defined(PRODUCT)
  __ Bind(&stepping);
  __ EnterStubFrame();
  __ SmiTag(R3);                       // Entry-point is not Smi.
  __ PushList((1 << R9) | (1 << R3));  // Preserve IC data and entry-point.
  __ CallRuntime(kSingleStepHandlerRuntimeEntry, 0);
  __ PopList((1 << R9) | (1 << R3));
  __ SmiUntag(R3);
  __ RestoreCodePointer();
  __ LeaveStubFrame();
  __ b(&done_stepping);
#endif
}

//  R9: ICData
//  LR: return address
void StubCodeCompiler::GenerateOneArgUnoptimizedStaticCallStub(
    Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, /* scratch */ R8);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 1, kStaticCallMissHandlerOneArgRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kStaticCall, kIgnoreExactness);
}

//  R9: ICData
//  LR: return address
void StubCodeCompiler::GenerateTwoArgsUnoptimizedStaticCallStub(
    Assembler* assembler) {
  GenerateUsageCounterIncrement(assembler, /* scratch */ R8);
  GenerateNArgsCheckInlineCacheStub(
      assembler, 2, kStaticCallMissHandlerTwoArgsRuntimeEntry, Token::kILLEGAL,
      kUnoptimized, kStaticCall, kIgnoreExactness);
}

// Stub for compiling a function and jumping to the compiled code.
// R4: Arguments descriptor.
// R0: Function.
void StubCodeCompiler::GenerateLazyCompileStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushList((1 << R0) | (1 << R4));  // Preserve arg desc, pass function.
  __ CallRuntime(kCompileFunctionRuntimeEntry, 1);
  __ PopList((1 << R0) | (1 << R4));
  __ LeaveStubFrame();

  __ ldr(CODE_REG, FieldAddress(R0, target::Function::code_offset()));
  __ Branch(FieldAddress(R0, target::Function::entry_point_offset()));
}

// R9: Contains an ICData.
void StubCodeCompiler::GenerateICCallBreakpointStub(Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ Push(R0);          // Preserve receiver.
  __ Push(R9);          // Preserve IC data.
  __ PushImmediate(0);  // Space for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ Pop(CODE_REG);  // Original stub.
  __ Pop(R9);        // Restore IC data.
  __ Pop(R0);        // Restore receiver.
  __ LeaveStubFrame();
  __ Branch(FieldAddress(CODE_REG, target::Code::entry_point_offset()));
#endif  // defined(PRODUCT)
}

void StubCodeCompiler::GenerateUnoptStaticCallBreakpointStub(
    Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ Push(R9);          // Preserve IC data.
  __ PushImmediate(0);  // Space for result.
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ Pop(CODE_REG);  // Original stub.
  __ Pop(R9);        // Restore IC data.
  __ LeaveStubFrame();
  __ Branch(FieldAddress(CODE_REG, target::Code::entry_point_offset()));
#endif  // defined(PRODUCT)
}

void StubCodeCompiler::GenerateRuntimeCallBreakpointStub(Assembler* assembler) {
#if defined(PRODUCT)
  __ Stop("No debugging in PRODUCT mode");
#else
  __ EnterStubFrame();
  __ LoadImmediate(R0, 0);
  // Make room for result.
  __ PushList((1 << R0));
  __ CallRuntime(kBreakpointRuntimeHandlerRuntimeEntry, 0);
  __ PopList((1 << CODE_REG));
  __ LeaveStubFrame();
  __ Branch(FieldAddress(CODE_REG, target::Code::entry_point_offset()));
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
  __ ldrb(R1, Address(R1, target::Isolate::single_step_offset()));
  __ CompareImmediate(R1, 0);
  __ b(&stepping, NE);
  __ Bind(&done_stepping);
  __ Ret();

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
// All TypeTestABI registers are preserved but kSubtypeTestCacheReg, which must
// be saved by the caller if the original value is needed after the call.
//
// Result in SubtypeTestCacheABI::kResultReg: null -> not found, otherwise
// result (true or false).
static void GenerateSubtypeNTestCacheStub(Assembler* assembler, int n) {
  ASSERT(n == 1 || n == 3 || n == 5 || n == 7);

  // Safe as the original value of TypeTestABI::kSubtypeTestCacheReg is only
  // used to initialize this register.
  const Register kCacheArrayReg = TypeTestABI::kSubtypeTestCacheReg;
  const Register kScratchReg = TypeTestABI::kScratchReg;

  // Registers that are only used for n >= 3 and must be preserved if used.
  Register kInstanceInstantiatorTypeArgumentsReg = kNoRegister;
  // Registers that are only used for n >= 7 and must be preserved if used.
  Register kInstanceParentFunctionTypeArgumentsReg = kNoRegister;
  // There is no register for InstanceDelayedFunctionTypeArguments, it is
  // instead placed on the stack and pulled into TMP for comparison against
  // the corresponding slot in the current cache entry.

  // NOTFP must be preserved for bare payloads, otherwise CODE_REG.
  const bool use_bare_payloads =
      FLAG_precompiled_mode && FLAG_use_bare_instructions;
  // For this, we choose the register that need not be preserved of the pair.
  const Register kNullReg = use_bare_payloads ? CODE_REG : NOTFP;
  __ LoadObject(kNullReg, NullObject());

  // Free up registers to be used if performing a 3, 5, or 7 value test.
  RegList pushed_registers = 0;
  if (n >= 3) {
    kInstanceInstantiatorTypeArgumentsReg = PP;
    pushed_registers |= 1 << kInstanceInstantiatorTypeArgumentsReg;
  }
  if (n >= 7) {
    // For this, we choose the register that must be preserved of the pair.
    kInstanceParentFunctionTypeArgumentsReg =
        use_bare_payloads ? NOTFP : CODE_REG;
    pushed_registers |= 1 << kInstanceParentFunctionTypeArgumentsReg;
  }
  if (pushed_registers != 0) {
    __ PushList(pushed_registers);
  }

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
                           TypeTestABI::kInstanceReg);
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
          kInstanceInstantiatorTypeArgumentsReg,
          FieldAddress(TypeTestABI::kInstanceReg,
                       target::Closure::instantiator_type_arguments_offset()));
      if (n >= 7) {
        __ ldr(kInstanceParentFunctionTypeArgumentsReg,
               FieldAddress(TypeTestABI::kInstanceReg,
                            target::Closure::function_type_arguments_offset()));
        __ ldr(kScratchReg,
               FieldAddress(TypeTestABI::kInstanceReg,
                            target::Closure::delayed_type_arguments_offset()));
        __ PushRegister(kScratchReg);
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
      __ mov(kInstanceInstantiatorTypeArgumentsReg, Operand(kNullReg));
      __ ldr(
          kScratchReg,
          FieldAddress(kScratchReg,
                       target::Class::
                           host_type_arguments_field_offset_in_words_offset()));
      __ CompareImmediate(kScratchReg, target::Class::kNoTypeArguments);
      __ b(&has_no_type_arguments, EQ);
      __ add(kScratchReg, TypeTestABI::kInstanceReg,
             Operand(kScratchReg, LSL, 2));
      __ ldr(kInstanceInstantiatorTypeArgumentsReg,
             FieldAddress(kScratchReg, 0));
      __ Bind(&has_no_type_arguments);

      if (n >= 7) {
        __ mov(kInstanceParentFunctionTypeArgumentsReg, Operand(kNullReg));
        __ PushRegister(kNullReg);
      }
    }
    __ SmiTag(STCInternalRegs::kInstanceCidOrFunctionReg);
  }

  const intptr_t kNoDepth = -1;
  const intptr_t kInstanceDelayedFunctionTypeArgumentsDepth =
      n >= 7 ? 0 : kNoDepth;

  Label found, not_found, next_iteration;

  // Loop header.
  __ Bind(&loop);
  __ ldr(kScratchReg,
         Address(kCacheArrayReg,
                 target::kWordSize *
                     target::SubtypeTestCache::kInstanceClassIdOrFunction));
  __ cmp(kScratchReg, Operand(kNullReg));
  __ b(&not_found, EQ);
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
    __ cmp(kScratchReg, Operand(kInstanceInstantiatorTypeArgumentsReg));
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
        __ cmp(kScratchReg, Operand(kInstanceParentFunctionTypeArgumentsReg));
        __ b(&next_iteration, NE);

        __ ldr(kScratchReg,
               Address(kCacheArrayReg,
                       target::kWordSize *
                           target::SubtypeTestCache::
                               kInstanceDelayedFunctionTypeArguments));
        __ CompareToStack(kScratchReg,
                          kInstanceDelayedFunctionTypeArgumentsDepth);
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
  if (n >= 7) {
    __ Drop(1);  // delayed function type args.
  }
  if (pushed_registers != 0) {
    __ PopList(pushed_registers);
  }
  __ Ret();

  __ Bind(&not_found);
  __ mov(TypeTestABI::kSubtypeTestCacheResultReg, Operand(kNullReg));
  if (n >= 7) {
    __ Drop(1);  // delayed function type args.
  }
  if (pushed_registers != 0) {
    __ PopList(pushed_registers);
  }
  __ Ret();
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

// See comment on[GenerateSubtypeNTestCacheStub].
void StubCodeCompiler::GenerateSubtype7TestCacheStub(Assembler* assembler) {
  GenerateSubtypeNTestCacheStub(assembler, 7);
}

// Return the current stack pointer address, used to do stack alignment checks.
void StubCodeCompiler::GenerateGetCStackPointerStub(Assembler* assembler) {
  __ mov(R0, Operand(SP));
  __ Ret();
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
  COMPILE_ASSERT(kExceptionObjectReg == R0);
  COMPILE_ASSERT(kStackTraceObjectReg == R1);
  COMPILE_ASSERT(IsAbiPreservedRegister(R4));
  COMPILE_ASSERT(IsAbiPreservedRegister(THR));
  __ mov(IP, Operand(R1));   // Copy Stack pointer into IP.
  // TransitionGeneratedToNative might clobber LR if it takes the slow path.
  __ mov(R4, Operand(R0));   // Program counter.
  __ mov(THR, Operand(R3));  // Thread.
  __ mov(FP, Operand(R2));   // Frame_pointer.
  __ mov(SP, Operand(IP));   // Set Stack pointer.
#if defined(USING_SHADOW_CALL_STACK)
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
  __ TransitionNativeToGenerated(tmp1, tmp2,
                                 /*leave_safepoint=*/true);
  __ Bind(&exit_through_non_ffi);

  // Set the tag.
  __ LoadImmediate(R2, VMTag::kDartTagId);
  __ StoreToOffset(R2, THR, target::Thread::vm_tag_offset());
  // Clear top exit frame.
  __ LoadImmediate(R2, 0);
  __ StoreToOffset(R2, THR, target::Thread::top_exit_frame_info_offset());
  // Restore the pool pointer.
  __ RestoreCodePointer();
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ SetupGlobalPoolAndDispatchTable();
    __ set_constant_pool_allowed(true);
  } else {
    __ LoadPoolPointer();
  }
  __ bx(R4);  // Jump to continuation point.
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

  READS_RETURN_ADDRESS_FROM_LR(
      __ bx(LR));  // Jump to the exception handler code.
}

// Deoptimize a frame on the call stack before rewinding.
// The arguments are stored in the Thread object.
// No result.
void StubCodeCompiler::GenerateDeoptForRewindStub(Assembler* assembler) {
  // Push zap value instead of CODE_REG.
  __ LoadImmediate(IP, kZapCodeReg);
  __ Push(IP);

  // Load the deopt pc into LR.
  WRITES_RETURN_ADDRESS_TO_LR(
      __ LoadFromOffset(LR, THR, target::Thread::resume_pc_offset()));
  GenerateDeoptimizationSequence(assembler, kEagerDeopt);

  // After we have deoptimized, jump to the correct frame.
  __ EnterStubFrame();
  __ CallRuntime(kRewindPostDeoptRuntimeEntry, 0);
  __ LeaveStubFrame();
  __ bkpt(0);
}

// Calls to the runtime to optimize the given function.
// R8: function to be reoptimized.
// R4: argument descriptor (preserved).
void StubCodeCompiler::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ ldr(CODE_REG, Address(THR, target::Thread::optimize_stub_offset()));
  __ EnterStubFrame();
  __ Push(R4);
  __ LoadImmediate(IP, 0);
  __ Push(IP);  // Setup space on stack for return value.
  __ Push(R8);
  __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry, 1);
  __ Pop(R0);  // Discard argument.
  __ Pop(R0);  // Get Function object
  __ Pop(R4);  // Restore argument descriptor.
  __ LeaveStubFrame();
  __ ldr(CODE_REG, FieldAddress(R0, target::Function::code_offset()));
  __ Branch(FieldAddress(R0, target::Function::entry_point_offset()));
  __ bkpt(0);
}

// Does identical check (object references are equal or not equal) with special
// checks for boxed numbers.
// LR: return address.
// Return Zero condition flag set if equal.
// Note: A Mint cannot contain a value that would fit in Smi.
static void GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                 const Register left,
                                                 const Register right,
                                                 const Register temp) {
  Label reference_compare, done, check_mint;
  // If any of the arguments is Smi do reference compare.
  __ tst(left, Operand(kSmiTagMask));
  __ b(&reference_compare, EQ);
  __ tst(right, Operand(kSmiTagMask));
  __ b(&reference_compare, EQ);

  // Value compare for two doubles.
  __ CompareClassId(left, kDoubleCid, temp);
  __ b(&check_mint, NE);
  __ CompareClassId(right, kDoubleCid, temp);
  __ b(&done, NE);

  // Double values bitwise compare.
  __ ldr(temp, FieldAddress(left, target::Double::value_offset() +
                                      0 * target::kWordSize));
  __ ldr(IP, FieldAddress(right, target::Double::value_offset() +
                                     0 * target::kWordSize));
  __ cmp(temp, Operand(IP));
  __ b(&done, NE);
  __ ldr(temp, FieldAddress(left, target::Double::value_offset() +
                                      1 * target::kWordSize));
  __ ldr(IP, FieldAddress(right, target::Double::value_offset() +
                                     1 * target::kWordSize));
  __ cmp(temp, Operand(IP));
  __ b(&done);

  __ Bind(&check_mint);
  __ CompareClassId(left, kMintCid, temp);
  __ b(&reference_compare, NE);
  __ CompareClassId(right, kMintCid, temp);
  __ b(&done, NE);
  __ ldr(temp, FieldAddress(
                   left, target::Mint::value_offset() + 0 * target::kWordSize));
  __ ldr(IP, FieldAddress(
                 right, target::Mint::value_offset() + 0 * target::kWordSize));
  __ cmp(temp, Operand(IP));
  __ b(&done, NE);
  __ ldr(temp, FieldAddress(
                   left, target::Mint::value_offset() + 1 * target::kWordSize));
  __ ldr(IP, FieldAddress(
                 right, target::Mint::value_offset() + 1 * target::kWordSize));
  __ cmp(temp, Operand(IP));
  __ b(&done);

  __ Bind(&reference_compare);
  __ cmp(left, Operand(right));
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
  __ ldrb(R1, Address(R1, target::Isolate::single_step_offset()));
  __ CompareImmediate(R1, 0);
  __ b(&stepping, NE);
  __ Bind(&done_stepping);
#endif

  const Register temp = R2;
  const Register left = R1;
  const Register right = R0;
  __ ldr(left, Address(SP, 1 * target::kWordSize));
  __ ldr(right, Address(SP, 0 * target::kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp);
  __ Ret();

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
  const Register temp = R2;
  const Register left = R1;
  const Register right = R0;
  __ ldr(left, Address(SP, 1 * target::kWordSize));
  __ ldr(right, Address(SP, 0 * target::kWordSize));
  GenerateIdenticalWithNumberCheckStub(assembler, left, right, temp);
  __ Ret();
}

// Called from megamorphic calls.
//  R0: receiver
//  R9: MegamorphicCache (preserved)
// Passed to target:
//  R0: function
//  R4: arguments descriptor
//  CODE_REG: target Code
void StubCodeCompiler::GenerateMegamorphicCallStub(Assembler* assembler) {
  __ LoadTaggedClassIdMayBeSmi(R8, R0);
  // R8: receiver cid as Smi.
  __ ldr(R2, FieldAddress(R9, target::MegamorphicCache::buckets_offset()));
  __ ldr(R1, FieldAddress(R9, target::MegamorphicCache::mask_offset()));
  // R2: cache buckets array.
  // R1: mask as a smi.

  // Compute the table index.
  ASSERT(target::MegamorphicCache::kSpreadFactor == 7);
  // Use reverse subtract to multiply with 7 == 8 - 1.
  __ rsb(R3, R8, Operand(R8, LSL, 3));
  // R3: probe.
  Label loop;
  __ Bind(&loop);
  __ and_(R3, R3, Operand(R1));

  const intptr_t base = target::Array::data_offset();
  // R3 is smi tagged, but table entries are two words, so LSL 2.
  Label probe_failed;
  __ add(IP, R2, Operand(R3, LSL, 2));
  __ ldr(R6, FieldAddress(IP, base));
  __ cmp(R6, Operand(R8));
  __ b(&probe_failed, NE);

  Label load_target;
  __ Bind(&load_target);
  // Call the target found in the cache.  For a class id match, this is a
  // proper target for the given name and arguments descriptor.  If the
  // illegal class id was found, the target is a cache miss handler that can
  // be invoked as a normal Dart function.
  const auto target_address = FieldAddress(IP, base + target::kWordSize);
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ ldr(
        ARGS_DESC_REG,
        FieldAddress(R9, target::CallSiteData::arguments_descriptor_offset()));
    __ Branch(target_address);
  } else {
    __ ldr(R0, target_address);
    __ ldr(CODE_REG, FieldAddress(R0, target::Function::code_offset()));
    __ ldr(
        ARGS_DESC_REG,
        FieldAddress(R9, target::CallSiteData::arguments_descriptor_offset()));
    __ Branch(FieldAddress(R0, target::Function::entry_point_offset()));
  }

  // Probe failed, check if it is a miss.
  __ Bind(&probe_failed);
  ASSERT(kIllegalCid == 0);
  __ tst(R6, Operand(R6));
  Label miss;
  __ b(&miss, EQ);  // branch if miss.

  // Try next entry in the table.
  __ AddImmediate(R3, target::ToRawSmi(1));
  __ b(&loop);

  __ Bind(&miss);
  GenerateSwitchableCallMissStub(assembler);
}

void StubCodeCompiler::GenerateICCallThroughCodeStub(Assembler* assembler) {
  Label loop, found, miss;
  __ ldr(R8, FieldAddress(R9, target::ICData::entries_offset()));
  __ ldr(R4,
         FieldAddress(R9, target::CallSiteData::arguments_descriptor_offset()));
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
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    __ ldr(CODE_REG, Address(R8, code_offset));
  }
  __ Branch(Address(R8, entry_offset));

  __ Bind(&miss);
  __ LoadIsolate(R2);
  __ ldr(CODE_REG, Address(R2, target::Isolate::ic_miss_code_offset()));
  __ Branch(FieldAddress(CODE_REG, target::Code::entry_point_offset()));
}

// Implement the monomorphic entry check for call-sites where the receiver
// might be a Smi.
//
//   R0: receiver
//   R9: MonomorphicSmiableCall object
//
//   R2, R3: clobbered
void StubCodeCompiler::GenerateMonomorphicSmiableCheckStub(
    Assembler* assembler) {
  __ LoadClassIdMayBeSmi(IP, R0);

  // expected_cid_ should come right after target_
  ASSERT(target::MonomorphicSmiableCall::expected_cid_offset() ==
         target::MonomorphicSmiableCall::target_offset() + target::kWordSize);
  // entrypoint_ should come right after expected_cid_
  ASSERT(target::MonomorphicSmiableCall::entrypoint_offset() ==
         target::MonomorphicSmiableCall::expected_cid_offset() +
             target::kWordSize);

  if (FLAG_use_bare_instructions) {
    // Simultaneously load the expected cid into R2 and the entrypoint into R3.
    __ ldrd(
        R2, R3, R9,
        target::MonomorphicSmiableCall::expected_cid_offset() - kHeapObjectTag);
    __ cmp(R2, Operand(IP));
    __ Branch(Address(THR, target::Thread::switchable_call_miss_entry_offset()),
              NE);
    __ bx(R3);
  } else {
    // Simultaneously load the target into R2 and the expected cid into R3.
    __ ldrd(R2, R3, R9,
            target::MonomorphicSmiableCall::target_offset() - kHeapObjectTag);
    __ mov(CODE_REG, Operand(R2));
    __ cmp(R3, Operand(IP));
    __ Branch(Address(THR, target::Thread::switchable_call_miss_entry_offset()),
              NE);
    __ LoadField(IP, FieldAddress(R2, target::Code::entry_point_offset()));
    __ bx(IP);
  }
}

static void CallSwitchableCallMissRuntimeEntry(Assembler* assembler,
                                               Register receiver_reg) {
  __ LoadImmediate(IP, 0);
  __ Push(IP);            // Result slot
  __ Push(IP);            // Arg0: stub out
  __ Push(receiver_reg);  // Arg1: Receiver
  __ CallRuntime(kSwitchableCallMissRuntimeEntry, 2);
  __ Pop(R0);        // Get the receiver
  __ Pop(CODE_REG);  // result = stub
  __ Pop(R9);        // result = IC
}

// Called from switchable IC calls.
//  R0: receiver
void StubCodeCompiler::GenerateSwitchableCallMissStub(Assembler* assembler) {
  __ ldr(CODE_REG,
         Address(THR, target::Thread::switchable_call_miss_stub_offset()));
  __ EnterStubFrame();
  CallSwitchableCallMissRuntimeEntry(assembler, /*receiver_reg=*/R0);
  __ LeaveStubFrame();

  __ Branch(FieldAddress(
      CODE_REG, target::Code::entry_point_offset(CodeEntryKind::kNormal)));
}

// Called from switchable IC calls.
//  R0: receiver
//  R9: SingleTargetCache
// Passed to target:
//  CODE_REG: target Code object
void StubCodeCompiler::GenerateSingleTargetCallStub(Assembler* assembler) {
  Label miss;
  __ LoadClassIdMayBeSmi(R1, R0);
  __ ldrh(R2,
          FieldAddress(R9, target::SingleTargetCache::lower_limit_offset()));
  __ ldrh(R3,
          FieldAddress(R9, target::SingleTargetCache::upper_limit_offset()));

  __ cmp(R1, Operand(R2));
  __ b(&miss, LT);
  __ cmp(R1, Operand(R3));
  __ b(&miss, GT);

  __ ldr(CODE_REG,
         FieldAddress(R9, target::SingleTargetCache::target_offset()));
  __ Branch(FieldAddress(R9, target::SingleTargetCache::entry_point_offset()));

  __ Bind(&miss);
  __ EnterStubFrame();
  CallSwitchableCallMissRuntimeEntry(assembler, /*receiver_reg=*/R0);
  __ LeaveStubFrame();

  __ Branch(FieldAddress(
      CODE_REG, target::Code::entry_point_offset(CodeEntryKind::kMonomorphic)));
}

void StubCodeCompiler::GenerateFrameAwaitingMaterializationStub(
    Assembler* assembler) {
  __ bkpt(0);
}

void StubCodeCompiler::GenerateAsynchronousGapMarkerStub(Assembler* assembler) {
  __ bkpt(0);
}

void StubCodeCompiler::GenerateNotLoadedStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ CallRuntime(kNotLoadedRuntimeEntry, 0);
  __ bkpt(0);
}

// Instantiate type arguments from instantiator and function type args.
// R3 uninstantiated type arguments.
// R2 instantiator type arguments.
// R1: function type arguments.
// Returns instantiated type arguments in R0.
void StubCodeCompiler::GenerateInstantiateTypeArgumentsStub(
    Assembler* assembler) {
  // Lookup cache before calling runtime.
  __ ldr(R0, compiler::FieldAddress(
                 InstantiationABI::kUninstantiatedTypeArgumentsReg,
                 target::TypeArguments::instantiations_offset()));
  __ AddImmediate(R0, compiler::target::Array::data_offset() - kHeapObjectTag);
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  compiler::Label loop, next, found, call_runtime;
  __ Bind(&loop);

  // Use load-acquire to test for sentinel, if we found non-sentinel it is safe
  // to access the other entries. If we found a sentinel we go to runtime.
  __ LoadAcquire(R4, R0,
                 TypeArguments::Instantiation::kInstantiatorTypeArgsIndex *
                     target::kWordSize);
  __ CompareImmediate(R4, Smi::RawValue(TypeArguments::kNoInstantiator));
  __ b(&call_runtime, EQ);

  __ cmp(R4,
         compiler::Operand(InstantiationABI::kInstantiatorTypeArgumentsReg));
  __ b(&next, NE);
  __ ldr(IP, compiler::Address(
                 R0, TypeArguments::Instantiation::kFunctionTypeArgsIndex *
                         target::kWordSize));
  __ cmp(IP, compiler::Operand(InstantiationABI::kFunctionTypeArgumentsReg));
  __ b(&found, EQ);
  __ Bind(&next);
  __ AddImmediate(
      R0, TypeArguments::Instantiation::kSizeInWords * target::kWordSize);
  __ b(&loop);

  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ Bind(&call_runtime);
  __ EnterStubFrame();
  __ PushObject(Object::null_object());  // Make room for the result.
  static_assert((InstantiationABI::kUninstantiatedTypeArgumentsReg >
                 InstantiationABI::kInstantiatorTypeArgumentsReg) &&
                    (InstantiationABI::kInstantiatorTypeArgumentsReg >
                     InstantiationABI::kFunctionTypeArgumentsReg),
                "Should be ordered to push arguments with one instruction");
  __ PushList((1 << InstantiationABI::kUninstantiatedTypeArgumentsReg) |
              (1 << InstantiationABI::kInstantiatorTypeArgumentsReg) |
              (1 << InstantiationABI::kFunctionTypeArgumentsReg));
  __ CallRuntime(kInstantiateTypeArgumentsRuntimeEntry, 3);
  __ Drop(3);  // Drop 2 type vectors, and uninstantiated type.
  __ Pop(InstantiationABI::kResultTypeArgumentsReg);
  __ LeaveStubFrame();
  __ Ret();

  __ Bind(&found);
  __ ldr(InstantiationABI::kResultTypeArgumentsReg,
         compiler::Address(
             R0, TypeArguments::Instantiation::kInstantiatedTypeArgsIndex *
                     target::kWordSize));
  __ Ret();
}

void StubCodeCompiler::
    GenerateInstantiateTypeArgumentsMayShareInstantiatorTAStub(
        Assembler* assembler) {
  // Return the instantiator type arguments if its nullability is compatible for
  // sharing, otherwise proceed to instantiation cache lookup.
  compiler::Label cache_lookup;
  __ ldr(R0, compiler::FieldAddress(
                 InstantiationABI::kUninstantiatedTypeArgumentsReg,
                 target::TypeArguments::nullability_offset()));
  __ ldr(R4,
         compiler::FieldAddress(InstantiationABI::kInstantiatorTypeArgumentsReg,
                                target::TypeArguments::nullability_offset()));
  __ and_(R4, R4, Operand(R0));
  __ cmp(R4, Operand(R0));
  __ b(&cache_lookup, NE);
  __ mov(InstantiationABI::kResultTypeArgumentsReg,
         Operand(InstantiationABI::kInstantiatorTypeArgumentsReg));
  __ Ret();

  __ Bind(&cache_lookup);
  GenerateInstantiateTypeArgumentsStub(assembler);
}

void StubCodeCompiler::GenerateInstantiateTypeArgumentsMayShareFunctionTAStub(
    Assembler* assembler) {
  // Return the function type arguments if its nullability is compatible for
  // sharing, otherwise proceed to instantiation cache lookup.
  compiler::Label cache_lookup;
  __ ldr(R0, compiler::FieldAddress(
                 InstantiationABI::kUninstantiatedTypeArgumentsReg,
                 target::TypeArguments::nullability_offset()));
  __ ldr(R4,
         compiler::FieldAddress(InstantiationABI::kFunctionTypeArgumentsReg,
                                target::TypeArguments::nullability_offset()));
  __ and_(R4, R4, Operand(R0));
  __ cmp(R4, Operand(R0));
  __ b(&cache_lookup, NE);
  __ mov(InstantiationABI::kResultTypeArgumentsReg,
         Operand(InstantiationABI::kFunctionTypeArgumentsReg));
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
  NOT_IN_PRODUCT(__ LoadAllocationStatsAddress(R2, cid));
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(R2, &call_runtime));
  __ mov(R2, Operand(AllocateTypedDataArrayABI::kLengthReg));
  /* Check that length is a positive Smi. */
  /* R2: requested array length argument. */
  __ tst(R2, Operand(kSmiTagMask));
  __ b(&call_runtime, NE);
  __ CompareImmediate(R2, 0);
  __ b(&call_runtime, LT);
  __ SmiUntag(R2);
  /* Check for maximum allowed length. */
  /* R2: untagged array length. */
  __ CompareImmediate(R2, max_len);
  __ b(&call_runtime, GT);
  __ mov(R2, Operand(R2, LSL, scale_shift));
  const intptr_t fixed_size_plus_alignment_padding =
      target::TypedData::InstanceSize() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ AddImmediate(R2, fixed_size_plus_alignment_padding);
  __ bic(R2, R2, Operand(target::ObjectAlignment::kObjectAlignment - 1));
  __ ldr(R0, Address(THR, target::Thread::top_offset()));

  /* R2: allocation size. */
  __ adds(R1, R0, Operand(R2));
  __ b(&call_runtime, CS); /* Fail on unsigned overflow. */

  /* Check if the allocation fits into the remaining space. */
  /* R0: potential new object start. */
  /* R1: potential next object start. */
  /* R2: allocation size. */
  __ ldr(IP, Address(THR, target::Thread::end_offset()));
  __ cmp(R1, Operand(IP));
  __ b(&call_runtime, CS);

  __ str(R1, Address(THR, target::Thread::top_offset()));
  __ AddImmediate(R0, kHeapObjectTag);
  /* Initialize the tags. */
  /* R0: new object start as a tagged pointer. */
  /* R1: new object end address. */
  /* R2: allocation size. */
  {
    __ CompareImmediate(R2, target::ObjectLayout::kSizeTagMaxSizeTag);
    __ mov(R3,
           Operand(R2, LSL,
                   target::ObjectLayout::kTagBitsSizeTagPos -
                       target::ObjectAlignment::kObjectAlignmentLog2),
           LS);
    __ mov(R3, Operand(0), HI);

    /* Get the class index and insert it into the tags. */
    uword tags = target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
    __ LoadImmediate(TMP, tags);
    __ orr(R3, R3, Operand(TMP));
    __ str(R3, FieldAddress(R0, target::Object::tags_offset())); /* Tags. */
  }
  /* Set the length field. */
  /* R0: new object start as a tagged pointer. */
  /* R1: new object end address. */
  /* R2: allocation size. */
  __ mov(R3,
         Operand(AllocateTypedDataArrayABI::kLengthReg)); /* Array length. */
  __ StoreIntoObjectNoBarrier(
      R0, FieldAddress(R0, target::TypedDataBase::length_offset()), R3);
  /* Initialize all array elements to 0. */
  /* R0: new object start as a tagged pointer. */
  /* R1: new object end address. */
  /* R2: allocation size. */
  /* R3: iterator which initially points to the start of the variable */
  /* R8, R9: zero. */
  /* data area to be initialized. */
  __ LoadImmediate(R8, 0);
  __ mov(R9, Operand(R8));
  __ AddImmediate(R3, R0, target::TypedData::InstanceSize() - 1);
  __ StoreInternalPointer(
      R0, FieldAddress(R0, target::TypedDataBase::data_field_offset()), R3);
  Label init_loop;
  __ Bind(&init_loop);
  __ AddImmediate(R3, 2 * target::kWordSize);
  __ cmp(R3, Operand(R1));
  __ strd(R8, R9, R3, -2 * target::kWordSize, LS);
  __ b(&init_loop, CC);
  __ str(R8, Address(R3, -2 * target::kWordSize), HI);

  __ Ret();

  __ Bind(&call_runtime);
  __ EnterStubFrame();
  __ PushObject(Object::null_object());            // Make room for the result.
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

#endif  // defined(TARGET_ARCH_ARM)
