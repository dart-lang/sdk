// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/compiler/backend/flow_graph_compiler.h"

#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/parallel_move_resolver.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
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
      assembler_->generate_invoke_write_barrier_wrapper_ =
          [&](Condition condition, Register reg) {
            const intptr_t offset_into_target =
                Thread::WriteBarrierWrappersOffsetForRegister(reg);
            assembler_->GenerateUnRelocatedPcRelativeCall(condition,
                                                          offset_into_target);
            AddPcRelativeCallStubTarget(stub);
          };
    }

    const auto& array_stub =
        Code::ZoneHandle(object_store->array_write_barrier_stub());
    if (CanPcRelativeCall(stub)) {
      assembler_->generate_invoke_array_write_barrier_ =
          [&](Condition condition) {
            assembler_->GenerateUnRelocatedPcRelativeCall(condition);
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
  }
}

bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return TargetCPUFeatures::neon_supported() && FLAG_enable_simd_inline;
}

bool FlowGraphCompiler::CanConvertInt64ToDouble() {
  // ARM does not have a short instruction sequence for converting int64 to
  // double.
  return false;
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
    __ bkpt(0);
  }

  ASSERT(deopt_env() != nullptr);
  __ Call(compiler::Address(
      THR, compiler::target::Thread::deoptimize_entry_offset()));
  set_pc_offset(assembler->CodeSize());
#undef __
}

#define __ assembler->
// Static methods of FlowGraphCompiler that take an assembler.

void FlowGraphCompiler::GenerateIndirectTTSCall(compiler::Assembler* assembler,
                                                Register reg_to_call,
                                                intptr_t sub_type_cache_index) {
  __ LoadField(
      TTSInternalRegs::kScratchReg,
      compiler::FieldAddress(
          reg_to_call,
          compiler::target::AbstractType::type_test_stub_entry_point_offset()));
  __ LoadWordFromPoolIndex(TypeTestABI::kSubtypeTestCacheReg,
                           sub_type_cache_index);
  __ blx(TTSInternalRegs::kScratchReg);
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
  __ b(&fall_through, EQ);
  BranchLabels labels = {is_true, is_false, &fall_through};
  Condition true_condition =
      EmitBoolTest(bool_register, labels, /*invert=*/false);
  ASSERT(true_condition != kInvalidCondition);
  __ b(is_true, true_condition);
  __ b(is_false);
  __ Bind(&fall_through);
}

void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  if (CanOptimizeFunction() && function.IsOptimizable() &&
      (!is_optimizing() || may_reoptimize())) {
    __ Comment("Invocation Count Check");
    const Register function_reg = R8;
    __ ldr(function_reg, compiler::FieldAddress(
                             CODE_REG, compiler::target::Code::owner_offset()));
    __ ldr(R3, compiler::FieldAddress(
                   function_reg,
                   compiler::target::Function::usage_counter_offset()));
    // Reoptimization of an optimized function is triggered by counting in
    // IC stubs, but not at the entry of the function.
    if (!is_optimizing()) {
      __ add(R3, R3, compiler::Operand(1));
      __ str(R3, compiler::FieldAddress(
                     function_reg,
                     compiler::target::Function::usage_counter_offset()));
    }
    __ CompareImmediate(R3, GetOptimizationThreshold());
    ASSERT(function_reg == R8);
    __ Branch(compiler::Address(
                  THR, compiler::target::Thread::optimize_entry_offset()),
              GE);
  }

  if (flow_graph().graph_entry()->NeedsFrame()) {
    __ Comment("Enter frame");
    if (flow_graph().IsCompiledForOsr()) {
      const intptr_t extra_slots = ExtraStackSlotsOnOsrEntry();
      ASSERT(extra_slots >= 0);
      __ EnterOsrFrame(extra_slots * compiler::target::kWordSize);
    } else {
      ASSERT(StackSize() >= 0);
      __ EnterDartFrame(StackSize() * compiler::target::kWordSize);
    }
  } else if (FLAG_precompiled_mode) {
    assembler()->set_constant_pool_allowed(true);
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
      __ LoadObject(R0, Object::null_object());
    }
    for (intptr_t i = 0; i < num_locals; ++i) {
      const intptr_t slot_index =
          compiler::target::frame_layout.FrameSlotForVariableIndex(-i);
      Register value_reg = slot_index == args_desc_slot ? ARGS_DESC_REG : R0;
      __ StoreToOffset(value_reg, FP, slot_index * compiler::target::kWordSize);
    }
  } else if (parsed_function().suspend_state_var() != nullptr &&
             !flow_graph().IsCompiledForOsr()) {
    // Initialize synthetic :suspend_state variable early
    // as it may be accessed by GC and exception handling before
    // InitSuspendableFunction stub is called.
    const intptr_t slot_index =
        compiler::target::frame_layout.FrameSlotForVariable(
            parsed_function().suspend_state_var());
    __ LoadObject(R0, Object::null_object());
    __ StoreToOffset(R0, FP, slot_index * compiler::target::kWordSize);
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
    __ BranchLink(stub, compiler::ObjectPoolBuilderEntry::kNotPatchable,
                  CodeEntryKind::kNormal, snapshot_behavior);
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
    __ ldr(PC, compiler::FieldAddress(
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
    __ ldr(PC, compiler::FieldAddress(
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
  __ BranchLinkPatchable(stub, CodeEntryKind::kNormal, snapshot_behavior);
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
  __ BranchLinkPatchable(stub, entry_kind);
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
  if (CanPcRelativeCall(target)) {
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeCallTarget(target, entry_kind);
    EmitCallsiteMetadata(source, deopt_id, kind, locs,
                         pending_deoptimization_env_);
  } else {
    ASSERT(is_optimizing());
    // Call sites to the same target can share object pool entries. These
    // call sites are never patched for breakpoints: the function is deoptimized
    // and the unoptimized code with IC calls for static calls is patched
    // instead.
    const auto& stub = StubCode::CallStaticFunction();
    __ BranchLinkWithEquivalence(stub, target, entry_kind);
    EmitCallsiteMetadata(source, deopt_id, kind, locs,
                         pending_deoptimization_env_);
    AddStaticCallTarget(target, entry_kind);
  }
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
  __ LoadObject(R0, edge_counters_array_);
#if defined(DEBUG)
  bool old_use_far_branches = assembler_->use_far_branches();
  assembler_->set_use_far_branches(true);
#endif  // DEBUG
  __ LoadFieldFromOffset(R1, R0,
                         compiler::target::Array::element_offset(edge_id));
  __ add(R1, R1, compiler::Operand(Smi::RawValue(1)));
  __ StoreIntoObjectOffsetNoBarrier(
      R0, compiler::target::Array::element_offset(edge_id), R1);
#if defined(DEBUG)
  assembler_->set_use_far_branches(old_use_far_branches);
#endif  // DEBUG
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

  __ LoadObject(R8, parsed_function().function());
  __ LoadFromOffset(R0, SP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize);
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
  __ LoadFromOffset(R0, SP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize);
  __ LoadUniqueObject(CODE_REG, stub);
  __ LoadUniqueObject(IC_DATA_REG, ic_data);
  const intptr_t entry_point_offset =
      entry_kind == Code::EntryKind::kNormal
          ? Code::entry_point_offset(Code::EntryKind::kMonomorphic)
          : Code::entry_point_offset(Code::EntryKind::kMonomorphicUnchecked);
  __ Call(compiler::FieldAddress(CODE_REG, entry_point_offset));
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
  // Load receiver into R0.
  __ LoadFromOffset(R0, SP,
                    (args_desc.Count() - 1) * compiler::target::kWordSize);
  // Use same code pattern as instance call so it can be parsed by code patcher.
  __ LoadUniqueObject(CODE_REG, StubCode::MegamorphicCall());
  __ LoadUniqueObject(IC_DATA_REG, cache);
  __ Call(compiler::FieldAddress(
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
  __ LoadFromOffset(
      R0, SP,
      (ic_data.SizeWithoutTypeArgs() - 1) * compiler::target::kWordSize);
  // The AOT runtime will replace the slot in the object pool with the
  // entrypoint address - see app_snapshot.cc.
  const auto snapshot_behavior =
      compiler::ObjectPoolBuilderEntry::kResetToSwitchableCallMissEntryPoint;
  CLOBBERS_LR(__ LoadUniqueObject(LR, initial_stub, AL, snapshot_behavior));
  __ LoadUniqueObject(R9, data);
  CLOBBERS_LR(__ blx(LR));

  EmitCallsiteMetadata(source, DeoptId::kNone, UntaggedPcDescriptors::kOther,
                       locs, pending_deoptimization_env_);
  EmitDropArguments(ic_data.SizeWithTypeArgs());
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
  __ LoadObject(R9, ic_data);
  GenerateDartCall(deopt_id, source, stub,
                   UntaggedPcDescriptors::kUnoptStaticCall, locs, entry_kind);
  EmitDropArguments(size_with_type_args);
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
      __ LoadImmediate(ARGS_DESC_REG, 0);  // GC safe smi zero because of stub.
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
  ASSERT(cid_reg != ARGS_DESC_REG);
  if (!arguments_descriptor.IsNull()) {
    __ LoadObject(ARGS_DESC_REG, arguments_descriptor);
  }
  intptr_t offset = (selector_offset - DispatchTable::kOriginElement) *
                    compiler::target::kWordSize;
  CLOBBERS_LR({
    // Would like cid_reg to be available on entry to the target function
    // for checking purposes.
    ASSERT(cid_reg != LR);
    if (offset == 0) {
      __ ldr(LR, compiler::Address(DISPATCH_TABLE_REG, cid_reg, LSL,
                                   compiler::target::kWordSizeLog2));
    } else {
      __ add(LR, DISPATCH_TABLE_REG,
             compiler::Operand(cid_reg, LSL, compiler::target::kWordSizeLog2));
      if (!Utils::MagnitudeIsUint(12, offset)) {
        const intptr_t adjust = offset & -(1 << 12);
        __ AddImmediate(LR, LR, adjust);
        offset -= adjust;
      }
      __ ldr(LR, compiler::Address(LR, offset));
    }
    __ blx(LR);
  });
}

Condition FlowGraphCompiler::EmitEqualityRegConstCompare(
    Register reg,
    const Object& obj,
    bool needs_number_check,
    const InstructionSource& source,
    intptr_t deopt_id) {
  if (needs_number_check) {
    ASSERT(!obj.IsMint() && !obj.IsDouble());
    __ Push(reg);
    __ PushObject(obj);
    if (is_optimizing()) {
      // No breakpoints in optimized code.
      __ BranchLink(StubCode::OptimizedIdenticalWithNumberCheck());
      AddCurrentDescriptor(UntaggedPcDescriptors::kOther, deopt_id, source);
    } else {
      // Patchable to support breakpoints.
      __ BranchLinkPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
      AddCurrentDescriptor(UntaggedPcDescriptors::kRuntimeCall, deopt_id,
                           source);
    }
    // Stub returns result in flags (result of a cmp, we need Z computed).
    __ Drop(1);   // Discard constant.
    __ Pop(reg);  // Restore 'reg'.
  } else {
    __ CompareObject(reg, obj);
  }
  return EQ;
}

Condition FlowGraphCompiler::EmitEqualityRegRegCompare(
    Register left,
    Register right,
    bool needs_number_check,
    const InstructionSource& source,
    intptr_t deopt_id) {
  if (needs_number_check) {
    __ Push(left);
    __ Push(right);
    if (is_optimizing()) {
      __ BranchLink(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ BranchLinkPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(UntaggedPcDescriptors::kRuntimeCall, deopt_id, source);
    // Stub returns result in flags (result of a cmp, we need Z computed).
    __ Pop(right);
    __ Pop(left);
  } else {
    __ cmp(left, compiler::Operand(right));
  }
  return EQ;
}

Condition FlowGraphCompiler::EmitBoolTest(Register value,
                                          BranchLabels labels,
                                          bool invert) {
  __ Comment("BoolTest");
  __ tst(value,
         compiler::Operand(compiler::target::ObjectAlignment::kBoolValueMask));
  return invert ? NE : EQ;
}

// This function must be in sync with FlowGraphCompiler::RecordSafepoint and
// FlowGraphCompiler::SlowPathEnvironmentFor.
void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
#if defined(DEBUG)
  locs->CheckWritableInputs();
  ClobberDeadTempRegisters(locs);
#endif
  // TODO(vegorov): consider saving only caller save (volatile) registers.
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
      __ mov(tmp.reg(), compiler::Operand(0xf7));
    }
  }
}
#endif

Register FlowGraphCompiler::EmitTestCidRegister() {
  return R2;
}

void FlowGraphCompiler::EmitTestAndCallLoadReceiver(
    intptr_t count_without_type_args,
    const Array& arguments_descriptor) {
  __ Comment("EmitTestAndCall");
  // Load receiver into R0.
  __ LoadFromOffset(
      R0, SP, (count_without_type_args - 1) * compiler::target::kWordSize);
  __ LoadObject(ARGS_DESC_REG, arguments_descriptor);
}

void FlowGraphCompiler::EmitTestAndCallSmiBranch(compiler::Label* label,
                                                 bool if_smi) {
  __ tst(R0, compiler::Operand(kSmiTagMask));
  // Jump if receiver is not Smi.
  __ b(label, if_smi ? EQ : NE);
}

void FlowGraphCompiler::EmitTestAndCallLoadCid(Register class_id_reg) {
  ASSERT(class_id_reg != R0);
  __ LoadClassId(class_id_reg, R0);
}

void FlowGraphCompiler::EmitMove(Location destination,
                                 Location source,
                                 TemporaryRegisterAllocator* allocator) {
  if (destination.Equals(source)) return;

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ mov(destination.reg(), compiler::Operand(source.reg()));
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ StoreToOffset(source.reg(), destination.base_reg(), dest_offset);
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      __ LoadFromOffset(destination.reg(), source.base_reg(), source_offset);
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();

      CLOBBERS_LR({
        // LR not used by register allocator.
        COMPILE_ASSERT(((1 << LR) & kDartAvailableCpuRegs) == 0);
        // StoreToOffset uses TMP in the case where dest_offset is too large or
        // small in order to calculate a new base. We fall back to using LR as a
        // temporary as we know we're in a ParallelMove.
        const Register temp_reg = LR;

        __ LoadFromOffset(temp_reg, source.base_reg(), source_offset);
        __ StoreToOffset(temp_reg, destination.base_reg(), dest_offset);
      });
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      if (TargetCPUFeatures::neon_supported()) {
        __ vmovq(destination.fpu_reg(), source.fpu_reg());
      } else {
        // If we're not inlining simd values, then only the even numbered D
        // register will have anything in them.
        __ vmovd(EvenDRegisterOf(destination.fpu_reg()),
                 EvenDRegisterOf(source.fpu_reg()));
      }
    } else if (destination.IsStackSlot()) {
      // 32-bit float
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      const SRegister src = EvenSRegisterOf(EvenDRegisterOf(source.fpu_reg()));
      __ StoreSToOffset(src, destination.base_reg(), dest_offset);
    } else if (destination.IsDoubleStackSlot()) {
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      DRegister src = EvenDRegisterOf(source.fpu_reg());
      __ StoreDToOffset(src, destination.base_reg(), dest_offset);
    } else {
      ASSERT(destination.IsQuadStackSlot());
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      const DRegister dsrc0 = EvenDRegisterOf(source.fpu_reg());
      __ StoreMultipleDToOffset(dsrc0, 2, destination.base_reg(), dest_offset);
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      const DRegister dst = EvenDRegisterOf(destination.fpu_reg());
      __ LoadDFromOffset(dst, source.base_reg(), source_offset);
    } else if (destination.IsStackSlot()) {
      // 32-bit float
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ LoadSFromOffset(STMP, source.base_reg(), source_offset);
      __ StoreSToOffset(STMP, destination.base_reg(), dest_offset);
    } else {
      ASSERT(destination.IsDoubleStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ LoadDFromOffset(DTMP, source.base_reg(), source_offset);
      __ StoreDToOffset(DTMP, destination.base_reg(), dest_offset);
    }
  } else if (source.IsQuadStackSlot()) {
    if (destination.IsFpuRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      const DRegister dst0 = EvenDRegisterOf(destination.fpu_reg());
      __ LoadMultipleDFromOffset(dst0, 2, source.base_reg(), source_offset);
    } else {
      ASSERT(destination.IsQuadStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      const DRegister dtmp0 = DTMP;
      __ LoadMultipleDFromOffset(dtmp0, 2, source.base_reg(), source_offset);
      __ StoreMultipleDToOffset(dtmp0, 2, destination.base_reg(), dest_offset);
    }
  } else if (source.IsPairLocation()) {
    ASSERT(destination.IsPairLocation());
    for (intptr_t i : {0, 1}) {
      EmitMove(destination.Component(i), source.Component(i), allocator);
    }
  } else {
    ASSERT(source.IsConstant());
    if (destination.IsFpuRegister() || destination.IsDoubleStackSlot() ||
        destination.IsStackSlot()) {
      Register tmp = allocator->AllocateTemporary();
      source.constant_instruction()->EmitMoveToLocation(this, destination, tmp,
                                                        source.pair_index());
      allocator->ReleaseTemporary();
    } else {
      source.constant_instruction()->EmitMoveToLocation(
          this, destination, kNoRegister, source.pair_index());
    }
  }
}

static compiler::OperandSize BytesToOperandSize(intptr_t bytes) {
  switch (bytes) {
    case 4:
      return compiler::OperandSize::kFourBytes;
    case 2:
      return compiler::OperandSize::kTwoBytes;
    case 1:
      return compiler::OperandSize::kByte;
    default:
      UNIMPLEMENTED();
  }
}

void FlowGraphCompiler::EmitNativeMoveArchitecture(
    const compiler::ffi::NativeLocation& destination,
    const compiler::ffi::NativeLocation& source) {
  const auto& src_payload_type = source.payload_type();
  const auto& dst_payload_type = destination.payload_type();
  const auto& src_container_type = source.container_type();
  const auto& dst_container_type = destination.container_type();
  ASSERT(src_container_type.IsFloat() == dst_container_type.IsFloat());
  ASSERT(src_container_type.IsInt() == dst_container_type.IsInt());
  ASSERT(src_payload_type.IsSigned() == dst_payload_type.IsSigned());
  ASSERT(src_payload_type.IsPrimitive());
  ASSERT(dst_payload_type.IsPrimitive());
  const intptr_t src_size = src_payload_type.SizeInBytes();
  const intptr_t dst_size = dst_payload_type.SizeInBytes();
  const bool sign_or_zero_extend = dst_size > src_size;

  if (source.IsRegisters()) {
    const auto& src = source.AsRegisters();
    ASSERT(src.num_regs() == 1);
    ASSERT(src_size <= 4);
    const auto src_reg = src.reg_at(0);

    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const auto dst_reg = dst.reg_at(0);
      ASSERT(destination.container_type().SizeInBytes() <= 4);
      if (!sign_or_zero_extend) {
        __ MoveRegister(dst_reg, src_reg);
      } else {
        if (src_payload_type.IsSigned()) {
          __ sbfx(dst_reg, src_reg, 0, src_size * kBitsPerByte);
        } else {
          __ ubfx(dst_reg, src_reg, 0, src_size * kBitsPerByte);
        }
      }

    } else if (destination.IsFpuRegisters()) {
      // Fpu Registers should only contain doubles and registers only ints.
      // The bit casts are done with a BitCastInstr.
      // TODO(dartbug.com/40371): Remove BitCastInstr and implement here.
      UNIMPLEMENTED();

    } else {
      ASSERT(destination.IsStack());
      const auto& dst = destination.AsStack();
      ASSERT(!sign_or_zero_extend);
      auto const op_size =
          BytesToOperandSize(destination.container_type().SizeInBytes());
      __ StoreToOffset(src.reg_at(0), dst.base_register(),
                       dst.offset_in_bytes(), op_size);
    }

  } else if (source.IsFpuRegisters()) {
    const auto& src = source.AsFpuRegisters();
    // We have not implemented conversions here, use IL convert instructions.
    ASSERT(src_payload_type.Equals(dst_payload_type));

    if (destination.IsRegisters()) {
      // Fpu Registers should only contain doubles and registers only ints.
      // The bit casts are done with a BitCastInstr.
      // TODO(dartbug.com/40371): Remove BitCastInstr and implement here.
      UNIMPLEMENTED();

    } else if (destination.IsFpuRegisters()) {
      const auto& dst = destination.AsFpuRegisters();
      switch (dst_size) {
        case 16:
          __ vmovq(dst.fpu_reg(), src.fpu_reg());
          return;
        case 8:
          __ vmovd(dst.fpu_as_d_reg(), src.fpu_as_d_reg());
          return;
        case 4:
          __ vmovs(dst.fpu_as_s_reg(), src.fpu_as_s_reg());
          return;
        default:
          UNREACHABLE();
      }

    } else {
      ASSERT(destination.IsStack());
      ASSERT(src_payload_type.IsFloat());
      const auto& dst = destination.AsStack();
      switch (dst_size) {
        case 8:
          __ StoreDToOffset(src.fpu_as_d_reg(), dst.base_register(),
                            dst.offset_in_bytes());
          return;
        case 4:
          __ StoreSToOffset(src.fpu_as_s_reg(), dst.base_register(),
                            dst.offset_in_bytes());
          return;
        default:
          // TODO(dartbug.com/37470): Case 16 for simd packed data.
          UNREACHABLE();
      }
    }

  } else {
    ASSERT(source.IsStack());
    const auto& src = source.AsStack();
    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const auto dst_reg = dst.reg_at(0);
      EmitNativeLoad(dst_reg, src.base_register(), src.offset_in_bytes(),
                     src_payload_type.AsPrimitive().representation());
    } else if (destination.IsFpuRegisters()) {
      ASSERT(src_payload_type.Equals(dst_payload_type));
      ASSERT(src_payload_type.IsFloat());
      const auto& dst = destination.AsFpuRegisters();
      switch (src_size) {
        case 8:
          __ LoadDFromOffset(dst.fpu_as_d_reg(), src.base_register(),
                             src.offset_in_bytes());
          return;
        case 4:
          __ LoadSFromOffset(dst.fpu_as_s_reg(), src.base_register(),
                             src.offset_in_bytes());
          return;
        default:
          UNIMPLEMENTED();
      }

    } else {
      ASSERT(destination.IsStack());
      UNREACHABLE();
    }
  }
}

void FlowGraphCompiler::EmitNativeLoad(Register dst,
                                       Register base,
                                       intptr_t offset,
                                       compiler::ffi::PrimitiveType type) {
  switch (type) {
    case compiler::ffi::kInt8:
      __ LoadFromOffset(dst, base, offset, compiler::kByte);
      break;
    case compiler::ffi::kUint8:
      __ LoadFromOffset(dst, base, offset, compiler::kUnsignedByte);
      break;
    case compiler::ffi::kInt16:
      __ LoadFromOffset(dst, base, offset, compiler::kTwoBytes);
      break;
    case compiler::ffi::kUint16:
      __ LoadFromOffset(dst, base, offset, compiler::kUnsignedTwoBytes);
      break;
    case compiler::ffi::kInt32:
      __ LoadFromOffset(dst, base, offset, compiler::kFourBytes);
      break;
    case compiler::ffi::kUint32:
    case compiler::ffi::kFloat:
    case compiler::ffi::kHalfDouble:
      __ LoadFromOffset(dst, base, offset, compiler::kUnsignedFourBytes);
      break;

    case compiler::ffi::kInt24:
      __ LoadFromOffset(dst, base, offset, compiler::kUnsignedTwoBytes);
      __ LoadFromOffset(TMP, base, offset + 2, compiler::kByte);
      __ orr(dst, dst, compiler::Operand(TMP, LSL, 16));
      break;
    case compiler::ffi::kUint24:
      __ LoadFromOffset(dst, base, offset, compiler::kUnsignedTwoBytes);
      __ LoadFromOffset(TMP, base, offset + 2, compiler::kUnsignedByte);
      __ orr(dst, dst, compiler::Operand(TMP, LSL, 16));
      break;
    default:
      UNREACHABLE();
  }
}

void FlowGraphCompiler::LoadBSSEntry(BSS::Relocation relocation,
                                     Register dst,
                                     Register tmp) {
  compiler::Label skip_reloc;
  __ b(&skip_reloc);
  InsertBSSRelocation(relocation);
  __ Bind(&skip_reloc);

  // For historical reasons, the PC on ARM points 8 bytes (two instructions)
  // past the current instruction.
  __ sub(tmp, PC,
         compiler::Operand(Instr::kPCReadOffset + compiler::target::kWordSize));

  // tmp holds the address of the relocation.
  __ ldr(dst, compiler::Address(tmp));

  // dst holds the relocation itself: tmp - bss_start.
  // tmp = tmp + (bss_start - tmp) = bss_start
  __ add(tmp, tmp, compiler::Operand(dst));

  // tmp holds the start of the BSS section.
  // Load the "get-thread" routine: *bss_start.
  __ ldr(dst, compiler::Address(tmp));
}

#undef __
#define __ compiler_->assembler()->

void ParallelMoveEmitter::EmitSwap(const MoveOperands& move) {
  const Location source = move.src();
  const Location destination = move.dest();

  if (source.IsRegister() && destination.IsRegister()) {
    ASSERT(source.reg() != IP);
    ASSERT(destination.reg() != IP);
    __ mov(IP, compiler::Operand(source.reg()));
    __ mov(source.reg(), compiler::Operand(destination.reg()));
    __ mov(destination.reg(), compiler::Operand(IP));
  } else if (source.IsRegister() && destination.IsStackSlot()) {
    Exchange(source.reg(), destination.base_reg(),
             destination.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), source.base_reg(), source.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(source.base_reg(), source.ToStackSlotOffset(),
             destination.base_reg(), destination.ToStackSlotOffset());
  } else if (source.IsFpuRegister() && destination.IsFpuRegister()) {
    if (TargetCPUFeatures::neon_supported()) {
      const QRegister dst = destination.fpu_reg();
      const QRegister src = source.fpu_reg();
      ASSERT(dst != QTMP && src != QTMP);
      __ vmovq(QTMP, src);
      __ vmovq(src, dst);
      __ vmovq(dst, QTMP);
    } else {
      const DRegister dst = EvenDRegisterOf(destination.fpu_reg());
      const DRegister src = EvenDRegisterOf(source.fpu_reg());
      ASSERT(dst != DTMP && src != DTMP);
      __ vmovd(DTMP, src);
      __ vmovd(src, dst);
      __ vmovd(dst, DTMP);
    }
  } else if (source.IsFpuRegister() || destination.IsFpuRegister()) {
    ASSERT(destination.IsDoubleStackSlot() || destination.IsQuadStackSlot() ||
           source.IsDoubleStackSlot() || source.IsQuadStackSlot());
    bool double_width =
        destination.IsDoubleStackSlot() || source.IsDoubleStackSlot();
    QRegister qreg =
        source.IsFpuRegister() ? source.fpu_reg() : destination.fpu_reg();
    DRegister reg = EvenDRegisterOf(qreg);
    Register base_reg =
        source.IsFpuRegister() ? destination.base_reg() : source.base_reg();
    const intptr_t slot_offset = source.IsFpuRegister()
                                     ? destination.ToStackSlotOffset()
                                     : source.ToStackSlotOffset();

    if (double_width) {
      __ LoadDFromOffset(DTMP, base_reg, slot_offset);
      __ StoreDToOffset(reg, base_reg, slot_offset);
      __ vmovd(reg, DTMP);
    } else {
      __ LoadMultipleDFromOffset(DTMP, 2, base_reg, slot_offset);
      __ StoreMultipleDToOffset(reg, 2, base_reg, slot_offset);
      __ vmovq(qreg, QTMP);
    }
  } else if (source.IsDoubleStackSlot() && destination.IsDoubleStackSlot()) {
    const intptr_t source_offset = source.ToStackSlotOffset();
    const intptr_t dest_offset = destination.ToStackSlotOffset();

    ScratchFpuRegisterScope ensure_scratch(this, kNoQRegister);
    DRegister scratch = EvenDRegisterOf(ensure_scratch.reg());
    __ LoadDFromOffset(DTMP, source.base_reg(), source_offset);
    __ LoadDFromOffset(scratch, destination.base_reg(), dest_offset);
    __ StoreDToOffset(DTMP, destination.base_reg(), dest_offset);
    __ StoreDToOffset(scratch, destination.base_reg(), source_offset);
  } else if (source.IsQuadStackSlot() && destination.IsQuadStackSlot()) {
    const intptr_t source_offset = source.ToStackSlotOffset();
    const intptr_t dest_offset = destination.ToStackSlotOffset();

    ScratchFpuRegisterScope ensure_scratch(this, kNoQRegister);
    DRegister scratch = EvenDRegisterOf(ensure_scratch.reg());
    __ LoadMultipleDFromOffset(DTMP, 2, source.base_reg(), source_offset);
    __ LoadMultipleDFromOffset(scratch, 2, destination.base_reg(), dest_offset);
    __ StoreMultipleDToOffset(DTMP, 2, destination.base_reg(), dest_offset);
    __ StoreMultipleDToOffset(scratch, 2, destination.base_reg(),
                              source_offset);
  } else {
    UNREACHABLE();
  }
}

void ParallelMoveEmitter::MoveMemoryToMemory(const compiler::Address& dst,
                                             const compiler::Address& src) {
  UNREACHABLE();
}

// Do not call or implement this function. Instead, use the form below that
// uses an offset from the frame pointer instead of an Address.
void ParallelMoveEmitter::Exchange(Register reg, const compiler::Address& mem) {
  UNREACHABLE();
}

// Do not call or implement this function. Instead, use the form below that
// uses offsets from the frame pointer instead of Addresses.
void ParallelMoveEmitter::Exchange(const compiler::Address& mem1,
                                   const compiler::Address& mem2) {
  UNREACHABLE();
}

void ParallelMoveEmitter::Exchange(Register reg,
                                   Register base_reg,
                                   intptr_t stack_offset) {
  ScratchRegisterScope tmp(this, reg);
  __ mov(tmp.reg(), compiler::Operand(reg));
  __ LoadFromOffset(reg, base_reg, stack_offset);
  __ StoreToOffset(tmp.reg(), base_reg, stack_offset);
}

void ParallelMoveEmitter::Exchange(Register base_reg1,
                                   intptr_t stack_offset1,
                                   Register base_reg2,
                                   intptr_t stack_offset2) {
  ScratchRegisterScope tmp1(this, kNoRegister);
  ScratchRegisterScope tmp2(this, tmp1.reg());
  __ LoadFromOffset(tmp1.reg(), base_reg1, stack_offset1);
  __ LoadFromOffset(tmp2.reg(), base_reg2, stack_offset2);
  __ StoreToOffset(tmp1.reg(), base_reg2, stack_offset2);
  __ StoreToOffset(tmp2.reg(), base_reg1, stack_offset1);
}

void ParallelMoveEmitter::SpillScratch(Register reg) {
  __ Push(reg);
}

void ParallelMoveEmitter::RestoreScratch(Register reg) {
  __ Pop(reg);
}

void ParallelMoveEmitter::SpillFpuScratch(FpuRegister reg) {
  __ PushQuad(reg);
}

void ParallelMoveEmitter::RestoreFpuScratch(FpuRegister reg) {
  __ PopQuad(reg);
}

#undef __

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM)
