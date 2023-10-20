// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/compiler/backend/flow_graph_compiler.h"

#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/parallel_move_resolver.h"
#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/deopt_instructions.h"
#include "vm/dispatch_table.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, trap_on_deoptimization, false, "Trap on deoptimization.");
DECLARE_FLAG(bool, enable_simd_inline);

void FlowGraphCompiler::ArchSpecificInitialization() {
  if (FLAG_precompiled_mode) {
    auto object_store = isolate_group()->object_store();

    const auto& stub =
        Code::ZoneHandle(object_store->write_barrier_wrappers_stub());
    if (CanPcRelativeCall(stub)) {
      assembler_->generate_invoke_write_barrier_wrapper_ = [&](Register reg) {
        const intptr_t offset_into_target =
            Thread::WriteBarrierWrappersOffsetForRegister(reg);
        assembler_->GenerateUnRelocatedPcRelativeCall(offset_into_target);
        AddPcRelativeCallStubTarget(stub);
      };
    }

    const auto& array_stub =
        Code::ZoneHandle(object_store->array_write_barrier_stub());
    if (CanPcRelativeCall(stub)) {
      assembler_->generate_invoke_array_write_barrier_ = [&]() {
        assembler_->GenerateUnRelocatedPcRelativeCall();
        AddPcRelativeCallStubTarget(array_stub);
      };
    }
  }
}

FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->jump_label()->IsLinked());
    ASSERT(!block_info_[i]->jump_label()->HasNear());
  }
}

bool FlowGraphCompiler::SupportsUnboxedDoubles() {
  return true;
}

bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return FLAG_enable_simd_inline;
}

bool FlowGraphCompiler::CanConvertInt64ToDouble() {
  return true;
}

void FlowGraphCompiler::EnterIntrinsicMode() {
  ASSERT(!intrinsic_mode());
  intrinsic_mode_ = true;
  ASSERT(!assembler()->constant_pool_allowed());
}

void FlowGraphCompiler::ExitIntrinsicMode() {
  ASSERT(intrinsic_mode());
  intrinsic_mode_ = false;
}

TypedDataPtr CompilerDeoptInfo::CreateDeoptInfo(FlowGraphCompiler* compiler,
                                                DeoptInfoBuilder* builder,
                                                const Array& deopt_table) {
  if (deopt_env_ == nullptr) {
    ++builder->current_info_number_;
    return TypedData::null();
  }

  AllocateOutgoingArguments(deopt_env_);

  intptr_t slot_ix = 0;
  Environment* current = deopt_env_;

  // Emit all kMaterializeObject instructions describing objects to be
  // materialized on the deoptimization as a prefix to the deoptimization info.
  EmitMaterializations(deopt_env_, builder);

  // The real frame starts here.
  builder->MarkFrameStart();

  Zone* zone = compiler->zone();

  builder->AddPp(current->function(), slot_ix++);
  builder->AddPcMarker(Function::ZoneHandle(zone), slot_ix++);
  builder->AddCallerFp(slot_ix++);
  builder->AddReturnAddress(current->function(), deopt_id(), slot_ix++);

  // Emit all values that are needed for materialization as a part of the
  // expression stack for the bottom-most frame. This guarantees that GC
  // will be able to find them during materialization.
  slot_ix = builder->EmitMaterializationArguments(slot_ix);

  // For the innermost environment, set outgoing arguments and the locals.
  for (intptr_t i = current->Length() - 1;
       i >= current->fixed_parameter_count(); i--) {
    builder->AddCopy(current->ValueAt(i), current->LocationAt(i), slot_ix++);
  }

  Environment* previous = current;
  current = current->outer();
  while (current != nullptr) {
    builder->AddPp(current->function(), slot_ix++);
    builder->AddPcMarker(previous->function(), slot_ix++);
    builder->AddCallerFp(slot_ix++);

    // For any outer environment the deopt id is that of the call instruction
    // which is recorded in the outer environment.
    builder->AddReturnAddress(current->function(),
                              DeoptId::ToDeoptAfter(current->GetDeoptId()),
                              slot_ix++);

    // The values of outgoing arguments can be changed from the inlined call so
    // we must read them from the previous environment.
    for (intptr_t i = previous->fixed_parameter_count() - 1; i >= 0; i--) {
      builder->AddCopy(previous->ValueAt(i), previous->LocationAt(i),
                       slot_ix++);
    }

    // Set the locals, note that outgoing arguments are not in the environment.
    for (intptr_t i = current->Length() - 1;
         i >= current->fixed_parameter_count(); i--) {
      builder->AddCopy(current->ValueAt(i), current->LocationAt(i), slot_ix++);
    }

    // Iterate on the outer environment.
    previous = current;
    current = current->outer();
  }
  // The previous pointer is now the outermost environment.
  ASSERT(previous != nullptr);

  // Set slots for the outermost environment.
  builder->AddCallerPp(slot_ix++);
  builder->AddPcMarker(previous->function(), slot_ix++);
  builder->AddCallerFp(slot_ix++);
  builder->AddCallerPc(slot_ix++);

  // For the outermost environment, set the incoming arguments.
  for (intptr_t i = previous->fixed_parameter_count() - 1; i >= 0; i--) {
    builder->AddCopy(previous->ValueAt(i), previous->LocationAt(i), slot_ix++);
  }

  return builder->CreateDeoptInfo(deopt_table);
}

void CompilerDeoptInfoWithStub::GenerateCode(FlowGraphCompiler* compiler,
                                             intptr_t stub_ix) {
  // Calls do not need stubs, they share a deoptimization trampoline.
  ASSERT(reason() != ICData::kDeoptAtCall);
  compiler::Assembler* assembler = compiler->assembler();
#define __ assembler->
  __ Comment("%s", Name());
  __ Bind(entry_label());
  if (FLAG_trap_on_deoptimization) {
    __ int3();
  }

  ASSERT(deopt_env() != nullptr);
  __ call(compiler::Address(THR, Thread::deoptimize_entry_offset()));
  set_pc_offset(assembler->CodeSize());
  __ int3();
#undef __
}

#define __ assembler->
// Static methods of FlowGraphCompiler that take an assembler.

void FlowGraphCompiler::GenerateIndirectTTSCall(compiler::Assembler* assembler,
                                                Register reg_to_call,
                                                intptr_t sub_type_cache_index) {
  __ LoadWordFromPoolIndex(TypeTestABI::kSubtypeTestCacheReg,
                           sub_type_cache_index);
  __ Call(compiler::FieldAddress(
      reg_to_call,
      compiler::target::AbstractType::type_test_stub_entry_point_offset()));
}

#undef __
#define __ assembler()->
// Instance methods of FlowGraphCompiler.

// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           compiler::Label* is_true,
                                           compiler::Label* is_false) {
  compiler::Label fall_through;
  __ CompareObject(bool_register, Object::null_object());
  __ j(EQUAL, &fall_through, compiler::Assembler::kNearJump);
  BranchLabels labels = {is_true, is_false, &fall_through};
  Condition true_condition =
      EmitBoolTest(bool_register, labels, /*invert=*/false);
  ASSERT(true_condition != kInvalidCondition);
  __ j(true_condition, is_true);
  __ jmp(is_false);
  __ Bind(&fall_through);
}

void FlowGraphCompiler::GenerateMethodExtractorIntrinsic(
    const Function& extracted_method,
    intptr_t type_arguments_field_offset) {
  // No frame has been setup here.
  ASSERT(!__ constant_pool_allowed());
  DEBUG_ASSERT(extracted_method.IsNotTemporaryScopedHandle());

  const Code& build_method_extractor =
      Code::ZoneHandle(extracted_method.IsGeneric()
                           ? isolate_group()
                                 ->object_store()
                                 ->build_generic_method_extractor_code()
                           : isolate_group()
                                 ->object_store()
                                 ->build_nongeneric_method_extractor_code());
  ASSERT(!build_method_extractor.IsNull());

  const intptr_t stub_index =
      __ object_pool_builder().FindObject(build_method_extractor);
  const intptr_t function_index =
      __ object_pool_builder().FindObject(extracted_method);

  // We use a custom pool register to preserve caller PP.
  Register kPoolReg = RAX;

  // RBX = extracted function
  // RDX = offset of type argument vector (or 0 if class is not generic)
  if (FLAG_precompiled_mode) {
    kPoolReg = PP;
  } else {
    __ movq(kPoolReg,
            compiler::FieldAddress(CODE_REG, Code::object_pool_offset()));
  }
  __ movq(RDX, compiler::Immediate(type_arguments_field_offset));
  __ movq(RBX, compiler::FieldAddress(
                   kPoolReg, ObjectPool::element_offset(function_index)));
  __ movq(CODE_REG, compiler::FieldAddress(
                        kPoolReg, ObjectPool::element_offset(stub_index)));
  __ jmp(compiler::FieldAddress(
      CODE_REG, Code::entry_point_offset(Code::EntryKind::kUnchecked)));
}

// NOTE: If the entry code shape changes, ReturnAddressLocator in profiler.cc
// needs to be updated to match.
void FlowGraphCompiler::EmitFrameEntry() {
  if (!flow_graph().graph_entry()->NeedsFrame()) {
    if (FLAG_precompiled_mode) {
      assembler()->set_constant_pool_allowed(true);
    }
    return;
  }

  if (flow_graph().IsCompiledForOsr()) {
    const intptr_t extra_slots = ExtraStackSlotsOnOsrEntry();
    ASSERT(extra_slots >= 0);
    __ EnterOsrFrame(extra_slots * kWordSize);
  } else {
    const Function& function = parsed_function().function();
    if (CanOptimizeFunction() && function.IsOptimizable() &&
        (!is_optimizing() || may_reoptimize())) {
      __ Comment("Invocation Count Check");
      const Register function_reg = RDI;
      __ movq(function_reg,
              compiler::FieldAddress(CODE_REG, Code::owner_offset()));

      // Reoptimization of an optimized function is triggered by counting in
      // IC stubs, but not at the entry of the function.
      if (!is_optimizing()) {
        __ incl(compiler::FieldAddress(function_reg,
                                       Function::usage_counter_offset()));
      }
      __ cmpl(compiler::FieldAddress(function_reg,
                                     Function::usage_counter_offset()),
              compiler::Immediate(GetOptimizationThreshold()));
      ASSERT(function_reg == RDI);
      compiler::Label dont_optimize;
      __ j(LESS, &dont_optimize, compiler::Assembler::kNearJump);
      __ jmp(compiler::Address(THR, Thread::optimize_entry_offset()));
      __ Bind(&dont_optimize);
    }
    ASSERT(StackSize() >= 0);
    __ Comment("Enter frame");
    __ EnterDartFrame(StackSize() * kWordSize);
  }
}

const InstructionSource& PrologueSource() {
  static InstructionSource prologue_source(TokenPosition::kDartCodePrologue,
                                           /*inlining_id=*/0);
  return prologue_source;
}

void FlowGraphCompiler::EmitPrologue() {
  BeginCodeSourceRange(PrologueSource());

  EmitFrameEntry();
  ASSERT(assembler()->constant_pool_allowed());

  // In unoptimized code, initialize (non-argument) stack allocated slots.
  if (!is_optimizing()) {
    const int num_locals = parsed_function().num_stack_locals();

    intptr_t args_desc_slot = -1;
    if (parsed_function().has_arg_desc_var()) {
      args_desc_slot = compiler::target::frame_layout.FrameSlotForVariable(
          parsed_function().arg_desc_var());
    }

    __ Comment("Initialize spill slots");
    if (num_locals > 1 || (num_locals == 1 && args_desc_slot == -1)) {
      __ LoadObject(RAX, Object::null_object());
    }
    for (intptr_t i = 0; i < num_locals; ++i) {
      const intptr_t slot_index =
          compiler::target::frame_layout.FrameSlotForVariableIndex(-i);
      Register value_reg = slot_index == args_desc_slot ? ARGS_DESC_REG : RAX;
      __ movq(compiler::Address(RBP, slot_index * kWordSize), value_reg);
    }
  } else if (parsed_function().suspend_state_var() != nullptr &&
             !flow_graph().IsCompiledForOsr()) {
    // Initialize synthetic :suspend_state variable early
    // as it may be accessed by GC and exception handling before
    // InitSuspendableFunction stub is called.
    const intptr_t slot_index =
        compiler::target::frame_layout.FrameSlotForVariable(
            parsed_function().suspend_state_var());
    __ LoadObject(RAX, Object::null_object());
    __ movq(compiler::Address(RBP, slot_index * kWordSize), RAX);
  }

  EndCodeSourceRange(PrologueSource());
}

void FlowGraphCompiler::EmitCallToStub(
    const Code& stub,
    ObjectPool::SnapshotBehavior snapshot_behavior) {
  ASSERT(!stub.IsNull());
  if (CanPcRelativeCall(stub)) {
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeCallStubTarget(stub);
  } else {
    __ Call(stub, snapshot_behavior);
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::EmitJumpToStub(const Code& stub) {
  ASSERT(!stub.IsNull());
  if (CanPcRelativeCall(stub)) {
    __ GenerateUnRelocatedPcRelativeTailCall();
    AddPcRelativeTailCallStubTarget(stub);
  } else {
    __ LoadObject(CODE_REG, stub);
    __ jmp(compiler::FieldAddress(
        CODE_REG, compiler::target::Code::entry_point_offset()));
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::EmitTailCallToStub(const Code& stub) {
  ASSERT(!stub.IsNull());
  if (CanPcRelativeCall(stub)) {
    if (flow_graph().graph_entry()->NeedsFrame()) {
      __ LeaveDartFrame();
    }
    __ GenerateUnRelocatedPcRelativeTailCall();
    AddPcRelativeTailCallStubTarget(stub);
#if defined(DEBUG)
    __ Breakpoint();
#endif
  } else {
    __ LoadObject(CODE_REG, stub);
    if (flow_graph().graph_entry()->NeedsFrame()) {
      __ LeaveDartFrame();
    }
    __ jmp(compiler::FieldAddress(
        CODE_REG, compiler::target::Code::entry_point_offset()));
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::GeneratePatchableCall(
    const InstructionSource& source,
    const Code& stub,
    UntaggedPcDescriptors::Kind kind,
    LocationSummary* locs,
    ObjectPool::SnapshotBehavior snapshot_behavior) {
  __ CallPatchable(stub, CodeEntryKind::kNormal, snapshot_behavior);
  EmitCallsiteMetadata(source, DeoptId::kNone, kind, locs,
                       pending_deoptimization_env_);
}

void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         const InstructionSource& source,
                                         const Code& stub,
                                         UntaggedPcDescriptors::Kind kind,
                                         LocationSummary* locs,
                                         Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  __ CallPatchable(stub, entry_kind);
  EmitCallsiteMetadata(source, deopt_id, kind, locs,
                       pending_deoptimization_env_);
}

void FlowGraphCompiler::GenerateStaticDartCall(intptr_t deopt_id,
                                               const InstructionSource& source,
                                               UntaggedPcDescriptors::Kind kind,
                                               LocationSummary* locs,
                                               const Function& target,
                                               Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  ASSERT(is_optimizing());
  if (CanPcRelativeCall(target)) {
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeCallTarget(target, entry_kind);
    EmitCallsiteMetadata(source, deopt_id, kind, locs,
                         pending_deoptimization_env_);
  } else {
    // Call sites to the same target can share object pool entries. These
    // call sites are never patched for breakpoints: the function is deoptimized
    // and the unoptimized code with IC calls for static calls is patched
    // instead.
    const auto& stub_entry = StubCode::CallStaticFunction();
    __ CallWithEquivalence(stub_entry, target, entry_kind);
    EmitCallsiteMetadata(source, deopt_id, kind, locs,
                         pending_deoptimization_env_);
    AddStaticCallTarget(target, entry_kind);
  }
}

void FlowGraphCompiler::EmitUnoptimizedStaticCall(
    intptr_t size_with_type_args,
    intptr_t deopt_id,
    const InstructionSource& source,
    LocationSummary* locs,
    const ICData& ic_data,
    Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  const Code& stub =
      StubCode::UnoptimizedStaticCallEntry(ic_data.NumArgsTested());
  __ LoadObject(RBX, ic_data);
  GenerateDartCall(deopt_id, source, stub,
                   UntaggedPcDescriptors::kUnoptStaticCall, locs, entry_kind);
  EmitDropArguments(size_with_type_args);
}

void FlowGraphCompiler::EmitEdgeCounter(intptr_t edge_id) {
  // We do not check for overflow when incrementing the edge counter.  The
  // function should normally be optimized long before the counter can
  // overflow; and though we do not reset the counters when we optimize or
  // deoptimize, there is a bound on the number of
  // optimization/deoptimization cycles we will attempt.
  ASSERT(!edge_counters_array_.IsNull());
  ASSERT(assembler_->constant_pool_allowed());
  __ Comment("Edge counter");
  __ LoadObject(RAX, edge_counters_array_);
  __ IncrementCompressedSmiField(
      compiler::FieldAddress(RAX, Array::element_offset(edge_id)), 1);
}

void FlowGraphCompiler::EmitOptimizedInstanceCall(
    const Code& stub,
    const ICData& ic_data,
    intptr_t deopt_id,
    const InstructionSource& source,
    LocationSummary* locs,
    Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  ASSERT(Array::Handle(zone(), ic_data.arguments_descriptor()).Length() > 0);
  // Each ICData propagated from unoptimized to optimized code contains the
  // function that corresponds to the Dart function of that IC call. Due
  // to inlining in optimized code, that function may not correspond to the
  // top-level function (parsed_function().function()) which could be
  // reoptimized and which counter needs to be incremented.
  // Pass the function explicitly, it is used in IC stub.
  __ LoadObject(RDI, parsed_function().function());
  // Load receiver into RDX.
  __ movq(RDX, compiler::Address(
                   RSP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize));
  __ LoadUniqueObject(IC_DATA_REG, ic_data);
  GenerateDartCall(deopt_id, source, stub, UntaggedPcDescriptors::kIcCall, locs,
                   entry_kind);
  EmitDropArguments(ic_data.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitInstanceCallJIT(const Code& stub,
                                            const ICData& ic_data,
                                            intptr_t deopt_id,
                                            const InstructionSource& source,
                                            LocationSummary* locs,
                                            Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  ASSERT(entry_kind == Code::EntryKind::kNormal ||
         entry_kind == Code::EntryKind::kUnchecked);
  ASSERT(Array::Handle(zone(), ic_data.arguments_descriptor()).Length() > 0);
  // Load receiver into RDX.
  __ movq(RDX, compiler::Address(
                   RSP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize));
  __ LoadUniqueObject(IC_DATA_REG, ic_data);
  __ LoadUniqueObject(CODE_REG, stub);
  const intptr_t entry_point_offset =
      entry_kind == Code::EntryKind::kNormal
          ? Code::entry_point_offset(Code::EntryKind::kMonomorphic)
          : Code::entry_point_offset(Code::EntryKind::kMonomorphicUnchecked);
  __ call(compiler::FieldAddress(CODE_REG, entry_point_offset));
  EmitCallsiteMetadata(source, deopt_id, UntaggedPcDescriptors::kIcCall, locs,
                       pending_deoptimization_env_);
  EmitDropArguments(ic_data.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const String& name,
    const Array& arguments_descriptor,
    intptr_t deopt_id,
    const InstructionSource& source,
    LocationSummary* locs) {
  ASSERT(CanCallDart());
  ASSERT(!arguments_descriptor.IsNull() && (arguments_descriptor.Length() > 0));
  ASSERT(!FLAG_precompiled_mode);
  const ArgumentsDescriptor args_desc(arguments_descriptor);
  const MegamorphicCache& cache = MegamorphicCache::ZoneHandle(
      zone(),
      MegamorphicCacheTable::Lookup(thread(), name, arguments_descriptor));
  __ Comment("MegamorphicCall");
  // Load receiver into RDX.
  __ movq(RDX, compiler::Address(RSP, (args_desc.Count() - 1) * kWordSize));

  // Use same code pattern as instance call so it can be parsed by code patcher.
  __ LoadUniqueObject(IC_DATA_REG, cache);
  __ LoadUniqueObject(CODE_REG, StubCode::MegamorphicCall());
  __ call(compiler::FieldAddress(
      CODE_REG, Code::entry_point_offset(Code::EntryKind::kMonomorphic)));

  RecordSafepoint(locs);
  AddCurrentDescriptor(UntaggedPcDescriptors::kOther, DeoptId::kNone, source);
  const intptr_t deopt_id_after = DeoptId::ToDeoptAfter(deopt_id);
  if (is_optimizing()) {
    AddDeoptIndexAtCall(deopt_id_after, pending_deoptimization_env_);
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(UntaggedPcDescriptors::kDeopt, deopt_id_after, source);
  }
  RecordCatchEntryMoves(pending_deoptimization_env_);
  EmitDropArguments(args_desc.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitInstanceCallAOT(const ICData& ic_data,
                                            intptr_t deopt_id,
                                            const InstructionSource& source,
                                            LocationSummary* locs,
                                            Code::EntryKind entry_kind,
                                            bool receiver_can_be_smi) {
  ASSERT(CanCallDart());
  ASSERT(entry_kind == Code::EntryKind::kNormal ||
         entry_kind == Code::EntryKind::kUnchecked);
  ASSERT(ic_data.NumArgsTested() == 1);
  const Code& initial_stub = StubCode::SwitchableCallMiss();
  const char* switchable_call_mode = "smiable";
  if (!receiver_can_be_smi) {
    switchable_call_mode = "non-smi";
    ic_data.set_receiver_cannot_be_smi(true);
  }
  const UnlinkedCall& data =
      UnlinkedCall::ZoneHandle(zone(), ic_data.AsUnlinkedCall());

  __ Comment("InstanceCallAOT (%s)", switchable_call_mode);
  __ movq(RDX, compiler::Address(
                   RSP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize));
  if (FLAG_precompiled_mode) {
    // The AOT runtime will replace the slot in the object pool with the
    // entrypoint address - see app_snapshot.cc.
    const auto snapshot_behavior =
        compiler::ObjectPoolBuilderEntry::kResetToSwitchableCallMissEntryPoint;
    __ LoadUniqueObject(RCX, initial_stub, snapshot_behavior);
  } else {
    const intptr_t entry_point_offset =
        entry_kind == Code::EntryKind::kNormal
            ? Code::entry_point_offset(Code::EntryKind::kMonomorphic)
            : Code::entry_point_offset(Code::EntryKind::kMonomorphicUnchecked);
    __ LoadUniqueObject(CODE_REG, initial_stub);
    __ movq(RCX, compiler::FieldAddress(CODE_REG, entry_point_offset));
  }
  __ LoadUniqueObject(RBX, data);
  __ call(RCX);

  EmitCallsiteMetadata(source, deopt_id, UntaggedPcDescriptors::kOther, locs,
                       pending_deoptimization_env_);
  EmitDropArguments(ic_data.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitOptimizedStaticCall(
    const Function& function,
    const Array& arguments_descriptor,
    intptr_t size_with_type_args,
    intptr_t deopt_id,
    const InstructionSource& source,
    LocationSummary* locs,
    Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  ASSERT(!function.IsClosureFunction());
  if (function.PrologueNeedsArgumentsDescriptor()) {
    __ LoadObject(ARGS_DESC_REG, arguments_descriptor);
  } else {
    if (!FLAG_precompiled_mode) {
      __ xorl(ARGS_DESC_REG,
              ARGS_DESC_REG);  // GC safe smi zero because of stub.
    }
  }
  // Do not use the code from the function, but let the code be patched so that
  // we can record the outgoing edges to other code.
  GenerateStaticDartCall(deopt_id, source, UntaggedPcDescriptors::kOther, locs,
                         function, entry_kind);
  EmitDropArguments(size_with_type_args);
}

void FlowGraphCompiler::EmitDispatchTableCall(
    int32_t selector_offset,
    const Array& arguments_descriptor) {
  const auto cid_reg = DispatchTableNullErrorABI::kClassIdReg;
  ASSERT(CanCallDart());
  const Register table_reg = RAX;
  ASSERT(cid_reg != table_reg);
  ASSERT(cid_reg != ARGS_DESC_REG);
  if (!arguments_descriptor.IsNull()) {
    __ LoadObject(ARGS_DESC_REG, arguments_descriptor);
  }
  const intptr_t offset = (selector_offset - DispatchTable::kOriginElement) *
                          compiler::target::kWordSize;
  __ LoadDispatchTable(table_reg);
  __ call(compiler::Address(table_reg, cid_reg, TIMES_8, offset));
}

Condition FlowGraphCompiler::EmitEqualityRegConstCompare(
    Register reg,
    const Object& obj,
    bool needs_number_check,
    const InstructionSource& source,
    intptr_t deopt_id) {
  ASSERT(!needs_number_check || (!obj.IsMint() && !obj.IsDouble()));

  if (obj.IsSmi() && (Smi::Cast(obj).Value() == 0)) {
    ASSERT(!needs_number_check);
    __ OBJ(test)(reg, reg);
    return EQUAL;
  }

  if (needs_number_check) {
    __ pushq(reg);
    __ PushObject(obj);
    if (is_optimizing()) {
      // No breakpoints in optimized code.
      __ Call(StubCode::OptimizedIdenticalWithNumberCheck());
      AddCurrentDescriptor(UntaggedPcDescriptors::kOther, deopt_id, source);
    } else {
      // Patchable to support breakpoints.
      __ CallPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
      AddCurrentDescriptor(UntaggedPcDescriptors::kRuntimeCall, deopt_id,
                           source);
    }
    // Stub returns result in flags (result of a cmpq, we need ZF computed).
    __ popq(reg);  // Discard constant.
    __ popq(reg);  // Restore 'reg'.
  } else {
    __ CompareObject(reg, obj);
  }
  return EQUAL;
}

Condition FlowGraphCompiler::EmitEqualityRegRegCompare(
    Register left,
    Register right,
    bool needs_number_check,
    const InstructionSource& source,
    intptr_t deopt_id) {
  if (needs_number_check) {
    __ pushq(left);
    __ pushq(right);
    if (is_optimizing()) {
      __ Call(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ CallPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(UntaggedPcDescriptors::kRuntimeCall, deopt_id, source);
    // Stub returns result in flags (result of a cmpq, we need ZF computed).
    __ popq(right);
    __ popq(left);
  } else {
    __ CompareObjectRegisters(left, right);
  }
  return EQUAL;
}

Condition FlowGraphCompiler::EmitBoolTest(Register value,
                                          BranchLabels labels,
                                          bool invert) {
  __ Comment("BoolTest");
  __ testq(value, compiler::Immediate(
                      compiler::target::ObjectAlignment::kBoolValueMask));
  return invert ? NOT_EQUAL : EQUAL;
}

// This function must be in sync with FlowGraphCompiler::RecordSafepoint and
// FlowGraphCompiler::SlowPathEnvironmentFor.
void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
#if defined(DEBUG)
  locs->CheckWritableInputs();
  ClobberDeadTempRegisters(locs);
#endif

  // TODO(vegorov): avoid saving non-volatile registers.
  __ PushRegisters(*locs->live_registers());
}

void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  __ PopRegisters(*locs->live_registers());
}

#if defined(DEBUG)
void FlowGraphCompiler::ClobberDeadTempRegisters(LocationSummary* locs) {
  // Clobber temporaries that have not been manually preserved.
  for (intptr_t i = 0; i < locs->temp_count(); ++i) {
    Location tmp = locs->temp(i);
    // TODO(zerny): clobber non-live temporary FPU registers.
    if (tmp.IsRegister() &&
        !locs->live_registers()->ContainsRegister(tmp.reg())) {
      __ movq(tmp.reg(), compiler::Immediate(0xf7));
    }
  }
}
#endif

Register FlowGraphCompiler::EmitTestCidRegister() {
  return RDI;
}

void FlowGraphCompiler::EmitTestAndCallLoadReceiver(
    intptr_t count_without_type_args,
    const Array& arguments_descriptor) {
  __ Comment("EmitTestAndCall");
  // Load receiver into RAX.
  __ movq(RAX,
          compiler::Address(RSP, (count_without_type_args - 1) * kWordSize));
  __ LoadObject(ARGS_DESC_REG, arguments_descriptor);
}

void FlowGraphCompiler::EmitTestAndCallSmiBranch(compiler::Label* label,
                                                 bool if_smi) {
  __ testq(RAX, compiler::Immediate(kSmiTagMask));
  // Jump if receiver is (not) Smi.
  __ j(if_smi ? ZERO : NOT_ZERO, label);
}

void FlowGraphCompiler::EmitTestAndCallLoadCid(Register class_id_reg) {
  ASSERT(class_id_reg != RAX);
  __ LoadClassId(class_id_reg, RAX);
}

void FlowGraphCompiler::EmitMove(Location destination,
                                 Location source,
                                 TemporaryRegisterAllocator* tmp) {
  if (destination.Equals(source)) return;

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ movq(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      __ movq(LocationToStackSlotAddress(destination), source.reg());
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      __ movq(destination.reg(), LocationToStackSlotAddress(source));
    } else if (destination.IsFpuRegister()) {
      // 32-bit float
      __ movq(TMP, LocationToStackSlotAddress(source));
      __ movq(destination.fpu_reg(), TMP);
    } else {
      ASSERT(destination.IsStackSlot());
      __ MoveMemoryToMemory(LocationToStackSlotAddress(destination),
                            LocationToStackSlotAddress(source));
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      // Optimization manual recommends using MOVAPS for register
      // to register moves.
      __ movaps(destination.fpu_reg(), source.fpu_reg());
    } else {
      if (destination.IsDoubleStackSlot()) {
        __ movsd(LocationToStackSlotAddress(destination), source.fpu_reg());
      } else {
        ASSERT(destination.IsQuadStackSlot());
        __ movups(LocationToStackSlotAddress(destination), source.fpu_reg());
      }
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      __ movsd(destination.fpu_reg(), LocationToStackSlotAddress(source));
    } else {
      ASSERT(destination.IsDoubleStackSlot() ||
             destination.IsStackSlot() /*32-bit float*/);
      __ movsd(FpuTMP, LocationToStackSlotAddress(source));
      __ movsd(LocationToStackSlotAddress(destination), FpuTMP);
    }
  } else if (source.IsQuadStackSlot()) {
    if (destination.IsFpuRegister()) {
      __ movups(destination.fpu_reg(), LocationToStackSlotAddress(source));
    } else {
      ASSERT(destination.IsQuadStackSlot());
      __ movups(FpuTMP, LocationToStackSlotAddress(source));
      __ movups(LocationToStackSlotAddress(destination), FpuTMP);
    }
  } else {
    ASSERT(!source.IsInvalid());
    ASSERT(source.IsConstant());
    source.constant_instruction()->EmitMoveToLocation(this, destination);
  }
}

void FlowGraphCompiler::EmitNativeMoveArchitecture(
    const compiler::ffi::NativeLocation& destination,
    const compiler::ffi::NativeLocation& source) {
  const auto& src_type = source.payload_type();
  const auto& dst_type = destination.payload_type();
  ASSERT(src_type.IsSigned() == dst_type.IsSigned());
  ASSERT(src_type.IsPrimitive());
  ASSERT(dst_type.IsPrimitive());
  const intptr_t src_size = src_type.SizeInBytes();
  const intptr_t dst_size = dst_type.SizeInBytes();
  const bool sign_or_zero_extend = dst_size > src_size;

  if (source.IsRegisters()) {
    const auto& src = source.AsRegisters();
    ASSERT(src.num_regs() == 1);
    const auto src_reg = src.reg_at(0);

    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const auto dst_reg = dst.reg_at(0);
      if (!sign_or_zero_extend) {
        switch (dst_size) {
          case 8:
            __ movq(dst_reg, src_reg);
            return;
          case 4:
            __ movl(dst_reg, src_reg);
            return;
          default:
            UNIMPLEMENTED();
        }
      } else {
        switch (src_type.AsPrimitive().representation()) {
          case compiler::ffi::kInt8:  // Sign extend operand.
            __ movsxb(dst_reg, src_reg);
            return;
          case compiler::ffi::kInt16:
            __ movsxw(dst_reg, src_reg);
            return;
          case compiler::ffi::kUint8:  // Zero extend operand.
            __ movzxb(dst_reg, src_reg);
            return;
          case compiler::ffi::kUint16:
            __ movzxw(dst_reg, src_reg);
            return;
          default:
            // 32 to 64 bit is covered in IL by Representation conversions.
            UNIMPLEMENTED();
        }
      }

    } else if (destination.IsFpuRegisters()) {
      const auto& dst = destination.AsFpuRegisters();
      ASSERT(src_size == dst_size);
      switch (dst_size) {
        case 8:
          __ movq(dst.fpu_reg(), src_reg);
          return;
        case 4:
          __ movd(dst.fpu_reg(), src_reg);
          return;
        default:
          UNREACHABLE();
      }

    } else {
      ASSERT(destination.IsStack());
      const auto& dst = destination.AsStack();
      const auto dst_addr = NativeLocationToStackSlotAddress(dst);
      ASSERT(!sign_or_zero_extend);
      switch (dst_size) {
        case 8:
          __ movq(dst_addr, src_reg);
          return;
        case 4:
          __ movl(dst_addr, src_reg);
          return;
        case 2:
          __ movw(dst_addr, src_reg);
          return;
        case 1:
          __ movb(dst_addr, ByteRegisterOf(src_reg));
          return;
        default:
          UNREACHABLE();
      }
    }

  } else if (source.IsFpuRegisters()) {
    const auto& src = source.AsFpuRegisters();
    // We have not implemented conversions here, use IL convert instructions.
    ASSERT(src_type.Equals(dst_type));

    if (destination.IsRegisters()) {
      ASSERT(src_size == dst_size);
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const auto dst_reg = dst.reg_at(0);
      switch (dst_size) {
        case 8:
          __ movq(dst_reg, src.fpu_reg());
          return;
        case 4:
          __ movl(dst_reg, src.fpu_reg());
          return;
        default:
          UNREACHABLE();
      }

    } else if (destination.IsFpuRegisters()) {
      const auto& dst = destination.AsFpuRegisters();
      // Optimization manual recommends using MOVAPS for register
      // to register moves.
      __ movaps(dst.fpu_reg(), src.fpu_reg());

    } else {
      ASSERT(destination.IsStack());
      ASSERT(src_type.IsFloat());
      const auto& dst = destination.AsStack();
      const auto dst_addr = NativeLocationToStackSlotAddress(dst);
      switch (dst_size) {
        case 8:
          __ movsd(dst_addr, src.fpu_reg());
          return;
        case 4:
          __ movss(dst_addr, src.fpu_reg());
          return;
        default:
          UNREACHABLE();
      }
    }

  } else {
    ASSERT(source.IsStack());
    const auto& src = source.AsStack();
    const auto src_addr = NativeLocationToStackSlotAddress(src);
    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const auto dst_reg = dst.reg_at(0);
      if (!sign_or_zero_extend) {
        switch (dst_size) {
          case 8:
            __ movq(dst_reg, src_addr);
            return;
          case 4:
            __ movl(dst_reg, src_addr);
            return;
          default:
            UNIMPLEMENTED();
        }
      } else {
        switch (src_type.AsPrimitive().representation()) {
          case compiler::ffi::kInt8:  // Sign extend operand.
            __ movsxb(dst_reg, src_addr);
            return;
          case compiler::ffi::kInt16:
            __ movsxw(dst_reg, src_addr);
            return;
          case compiler::ffi::kUint8:  // Zero extend operand.
            __ movzxb(dst_reg, src_addr);
            return;
          case compiler::ffi::kUint16:
            __ movzxw(dst_reg, src_addr);
            return;
          default:
            // 32 to 64 bit is covered in IL by Representation conversions.
            UNIMPLEMENTED();
        }
      }

    } else if (destination.IsFpuRegisters()) {
      ASSERT(src_type.Equals(dst_type));
      ASSERT(src_type.IsFloat());
      const auto& dst = destination.AsFpuRegisters();
      switch (dst_size) {
        case 8:
          __ movsd(dst.fpu_reg(), src_addr);
          return;
        case 4:
          __ movss(dst.fpu_reg(), src_addr);
          return;
        default:
          UNREACHABLE();
      }

    } else {
      ASSERT(destination.IsStack());
      UNREACHABLE();
    }
  }
}

void FlowGraphCompiler::LoadBSSEntry(BSS::Relocation relocation,
                                     Register dst,
                                     Register tmp) {
  compiler::Label skip_reloc;
  __ jmp(&skip_reloc);
  InsertBSSRelocation(relocation);
  const intptr_t reloc_end = __ CodeSize();
  __ Bind(&skip_reloc);

  const intptr_t kLeaqLength = 7;
  __ leaq(dst, compiler::Address::AddressRIPRelative(
                   -kLeaqLength - compiler::target::kWordSize));
  ASSERT((__ CodeSize() - reloc_end) == kLeaqLength);

  // dst holds the address of the relocation.
  __ movq(tmp, compiler::Address(dst, 0));

  // tmp holds the relocation itself: dst - bss_start.
  // dst = dst + (bss_start - dst) = bss_start
  __ addq(dst, tmp);

  // dst holds the start of the BSS section.
  // Load the routine.
  __ movq(dst, compiler::Address(dst, 0));
}

#undef __
#define __ compiler_->assembler()->

void ParallelMoveEmitter::EmitSwap(const MoveOperands& move) {
  const Location source = move.src();
  const Location destination = move.dest();

  if (source.IsRegister() && destination.IsRegister()) {
    __ xchgq(destination.reg(), source.reg());
  } else if (source.IsRegister() && destination.IsStackSlot()) {
    Exchange(source.reg(), LocationToStackSlotAddress(destination));
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), LocationToStackSlotAddress(source));
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(LocationToStackSlotAddress(destination),
             LocationToStackSlotAddress(source));
  } else if (source.IsFpuRegister() && destination.IsFpuRegister()) {
    __ movaps(FpuTMP, source.fpu_reg());
    __ movaps(source.fpu_reg(), destination.fpu_reg());
    __ movaps(destination.fpu_reg(), FpuTMP);
  } else if (source.IsFpuRegister() || destination.IsFpuRegister()) {
    ASSERT(destination.IsDoubleStackSlot() || destination.IsQuadStackSlot() ||
           source.IsDoubleStackSlot() || source.IsQuadStackSlot());
    bool double_width =
        destination.IsDoubleStackSlot() || source.IsDoubleStackSlot();
    XmmRegister reg =
        source.IsFpuRegister() ? source.fpu_reg() : destination.fpu_reg();
    compiler::Address slot_address =
        source.IsFpuRegister() ? LocationToStackSlotAddress(destination)
                               : LocationToStackSlotAddress(source);

    if (double_width) {
      __ movsd(FpuTMP, slot_address);
      __ movsd(slot_address, reg);
    } else {
      __ movups(FpuTMP, slot_address);
      __ movups(slot_address, reg);
    }
    __ movaps(reg, FpuTMP);
  } else if (source.IsDoubleStackSlot() && destination.IsDoubleStackSlot()) {
    const compiler::Address& source_slot_address =
        LocationToStackSlotAddress(source);
    const compiler::Address& destination_slot_address =
        LocationToStackSlotAddress(destination);

    ScratchFpuRegisterScope ensure_scratch(this, FpuTMP);
    __ movsd(FpuTMP, source_slot_address);
    __ movsd(ensure_scratch.reg(), destination_slot_address);
    __ movsd(destination_slot_address, FpuTMP);
    __ movsd(source_slot_address, ensure_scratch.reg());
  } else if (source.IsQuadStackSlot() && destination.IsQuadStackSlot()) {
    const compiler::Address& source_slot_address =
        LocationToStackSlotAddress(source);
    const compiler::Address& destination_slot_address =
        LocationToStackSlotAddress(destination);

    ScratchFpuRegisterScope ensure_scratch(this, FpuTMP);
    __ movups(FpuTMP, source_slot_address);
    __ movups(ensure_scratch.reg(), destination_slot_address);
    __ movups(destination_slot_address, FpuTMP);
    __ movups(source_slot_address, ensure_scratch.reg());
  } else {
    UNREACHABLE();
  }
}

void ParallelMoveEmitter::MoveMemoryToMemory(const compiler::Address& dst,
                                             const compiler::Address& src) {
  __ MoveMemoryToMemory(dst, src);
}

void ParallelMoveEmitter::Exchange(Register reg, const compiler::Address& mem) {
  __ Exchange(reg, mem);
}

void ParallelMoveEmitter::Exchange(const compiler::Address& mem1,
                                   const compiler::Address& mem2) {
  __ Exchange(mem1, mem2);
}

void ParallelMoveEmitter::Exchange(Register reg,
                                   Register base_reg,
                                   intptr_t stack_offset) {
  UNREACHABLE();
}

void ParallelMoveEmitter::Exchange(Register base_reg1,
                                   intptr_t stack_offset1,
                                   Register base_reg2,
                                   intptr_t stack_offset2) {
  UNREACHABLE();
}

void ParallelMoveEmitter::SpillScratch(Register reg) {
  __ pushq(reg);
}

void ParallelMoveEmitter::RestoreScratch(Register reg) {
  __ popq(reg);
}

void ParallelMoveEmitter::SpillFpuScratch(FpuRegister reg) {
  __ AddImmediate(RSP, compiler::Immediate(-kFpuRegisterSize));
  __ movups(compiler::Address(RSP, 0), reg);
}

void ParallelMoveEmitter::RestoreFpuScratch(FpuRegister reg) {
  __ movups(reg, compiler::Address(RSP, 0));
  __ AddImmediate(RSP, compiler::Immediate(kFpuRegisterSize));
}

#undef __

}  // namespace dart

#endif  // defined(TARGET_ARCH_X64)
