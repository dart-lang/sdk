// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

#include "vm/compiler/backend/flow_graph_compiler.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/parallel_move_resolver.h"
#include "vm/deopt_instructions.h"
#include "vm/object.h"
#include "vm/stub_code.h"

namespace dart {

DEFINE_FLAG(bool, trap_on_deoptimization, false, "Trap on deoptimization.");

#define __ assembler()->

void FlowGraphCompiler::ArchSpecificInitialization() {}

FlowGraphCompiler::~FlowGraphCompiler() {
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->jump_label()->IsLinked());
  }
}

bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return false;
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

  EmitMaterializations(deopt_env_, builder);
  builder->MarkFrameStart();

  Zone* zone = compiler->zone();

  builder->AddPp(current->function(), slot_ix++);
  builder->AddPcMarker(Function::ZoneHandle(zone), slot_ix++);
  builder->AddCallerFp(slot_ix++);
  builder->AddReturnAddress(current->function(), deopt_id(), slot_ix++);

  slot_ix = builder->EmitMaterializationArguments(slot_ix);

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
    builder->AddReturnAddress(current->function(),
                              DeoptId::ToDeoptAfter(current->GetDeoptId()),
                              slot_ix++);

    for (intptr_t i = previous->fixed_parameter_count() - 1; i >= 0; i--) {
      builder->AddCopy(previous->ValueAt(i), previous->LocationAt(i),
                       slot_ix++);
    }

    for (intptr_t i = current->Length() - 1;
         i >= current->fixed_parameter_count(); i--) {
      builder->AddCopy(current->ValueAt(i), current->LocationAt(i), slot_ix++);
    }

    previous = current;
    current = current->outer();
  }
  ASSERT(previous != nullptr);

  builder->AddCallerPp(slot_ix++);
  builder->AddPcMarker(previous->function(), slot_ix++);
  builder->AddCallerFp(slot_ix++);
  builder->AddCallerPc(slot_ix++);

  for (intptr_t i = previous->fixed_parameter_count() - 1; i >= 0; i--) {
    builder->AddCopy(previous->ValueAt(i), previous->LocationAt(i), slot_ix++);
  }

  return builder->CreateDeoptInfo(deopt_table);
}

void CompilerDeoptInfoWithStub::GenerateCode(FlowGraphCompiler* compiler,
                                             intptr_t stub_ix) {
  USE(stub_ix);
  ASSERT(reason() != ICData::kDeoptAtCall);
  compiler::Assembler* assembler = compiler->assembler();
  assembler->Comment("%s", Name());
  assembler->Bind(entry_label());
  if (FLAG_trap_on_deoptimization) {
    assembler->Breakpoint();
  }

  ASSERT(deopt_env() != nullptr);
  assembler->Call(compiler::Address(THR, Thread::deoptimize_entry_offset()));
  set_pc_offset(assembler->CodeSize());
}

void FlowGraphCompiler::GenerateIndirectTTSCall(compiler::Assembler* assembler,
                                                Register reg_to_call,
                                                intptr_t sub_type_cache_index) {
  assembler->LoadField(
      TTSInternalRegs::kScratchReg,
      compiler::FieldAddress(
          reg_to_call,
          compiler::target::AbstractType::type_test_stub_entry_point_offset()));
  assembler->LoadWordFromPoolIndex(TypeTestABI::kSubtypeTestCacheReg,
                                   sub_type_cache_index);
  assembler->Call(TTSInternalRegs::kScratchReg);
}

// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           compiler::Label* is_true,
                                           compiler::Label* is_false) {
  compiler::Label fall_through;
  __ beq(bool_register, NULL_REG, &fall_through,
         compiler::Assembler::kNearJump);
  BranchLabels labels = {is_true, is_false, &fall_through};
  const Condition true_condition =
      EmitBoolTest(bool_register, labels, /*invert=*/false);
  ASSERT(true_condition != kInvalidCondition);
  __ BranchIf(true_condition, is_true);
  __ j(is_false);
  __ Bind(&fall_through);
}

void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  if (CanOptimizeFunction() && function.IsOptimizable() &&
      (!is_optimizing() || may_reoptimize())) {
    __ Comment("Invocation Count Check");
    const Register function_reg = A0;
    const Register usage_reg = A1;
    __ LoadFieldFromOffset(function_reg, CODE_REG,
                           compiler::target::Code::owner_offset());
    __ LoadFieldFromOffset(usage_reg, function_reg,
                           compiler::target::Function::usage_counter_offset(),
                           compiler::kFourBytes);
    if (!is_optimizing()) {
      __ AddImmediate(usage_reg, usage_reg, 1);
      __ StoreFieldToOffset(usage_reg, function_reg,
                            compiler::target::Function::usage_counter_offset(),
                            compiler::kFourBytes);
    }
    __ CompareImmediate(usage_reg, GetOptimizationThreshold());
    compiler::Label dont_optimize;
    __ BranchIf(LT, &dont_optimize, compiler::Assembler::kNearJump);
    __ Load(TMP, compiler::Address(
                     THR, compiler::target::Thread::optimize_entry_offset()));
    __ Jump(TMP);
    __ Bind(&dont_optimize);
  }

  if (flow_graph().graph_entry()->NeedsFrame()) {
    __ Comment("Enter frame");
    if (flow_graph().IsCompiledForOsr()) {
      const intptr_t extra_slots = ExtraStackSlotsOnOsrEntry();
      ASSERT(extra_slots >= 0);
      __ EnterOsrFrame(extra_slots * kWordSize);
    } else {
      ASSERT(StackSize() >= 0);
      __ EnterDartFrame(StackSize() * kWordSize);
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

  if (!is_optimizing()) {
    const int num_locals = parsed_function().num_stack_locals();

    intptr_t args_desc_slot = -1;
    if (parsed_function().has_arg_desc_var()) {
      args_desc_slot = compiler::target::frame_layout.FrameSlotForVariable(
          parsed_function().arg_desc_var());
    }

    __ Comment("Initialize spill slots");
    const intptr_t fp_to_sp_delta =
        num_locals + compiler::target::frame_layout.dart_fixed_frame_size;
    for (intptr_t i = 0; i < num_locals; ++i) {
      const intptr_t slot_index =
          compiler::target::frame_layout.FrameSlotForVariableIndex(-i);
      Register value_reg =
          slot_index == args_desc_slot ? ARGS_DESC_REG : NULL_REG;
      __ StoreToOffset(value_reg, SP,
                       (slot_index + fp_to_sp_delta) * kWordSize);
    }
  } else if (parsed_function().suspend_state_var() != nullptr &&
             !flow_graph().IsCompiledForOsr()) {
    const intptr_t slot_index =
        compiler::target::frame_layout.FrameSlotForVariable(
            parsed_function().suspend_state_var());
    const intptr_t fp_to_sp_delta =
        StackSize() + compiler::target::frame_layout.dart_fixed_frame_size;
    __ StoreToOffset(NULL_REG, SP, (slot_index + fp_to_sp_delta) * kWordSize);
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
    __ JumpAndLink(stub, compiler::ObjectPoolBuilderEntry::kNotPatchable,
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
    __ Load(TMP, compiler::FieldAddress(
                     CODE_REG, compiler::target::Code::entry_point_offset()));
    __ Jump(TMP);
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::EmitTailCallToStub(const Code& stub) {
  ASSERT(!stub.IsNull());
  if (CanPcRelativeCall(stub)) {
    if (flow_graph().graph_entry()->NeedsFrame()) {
      if (FLAG_target_thread_sanitizer && !is_optimizing()) {
        __ TsanFuncExit();
      }
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
      if (FLAG_target_thread_sanitizer && !is_optimizing()) {
        __ TsanFuncExit();
      }
      __ LeaveDartFrame();
    }
    __ Load(TMP, compiler::FieldAddress(
                     CODE_REG, compiler::target::Code::entry_point_offset()));
    __ Jump(TMP);
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         const InstructionSource& source,
                                         const Code& stub,
                                         UntaggedPcDescriptors::Kind kind,
                                         LocationSummary* locs,
                                         Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  __ JumpAndLinkPatchable(stub, entry_kind);
  EmitCallsiteMetadata(source, deopt_id, kind, locs,
                       pending_deoptimization_env_);
}

void FlowGraphCompiler::GeneratePatchableCall(
    const InstructionSource& source,
    const Code& stub,
    UntaggedPcDescriptors::Kind kind,
    LocationSummary* locs,
    ObjectPool::SnapshotBehavior snapshot_behavior) {
  __ JumpAndLinkPatchable(stub, CodeEntryKind::kNormal, snapshot_behavior);
  EmitCallsiteMetadata(source, DeoptId::kNone, kind, locs,
                       pending_deoptimization_env_);
}

void FlowGraphCompiler::GenerateStaticDartCall(
    intptr_t deopt_id,
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
    const auto& stub = StubCode::CallStaticFunction();
    __ JumpAndLinkWithEquivalence(stub, target, entry_kind);
    EmitCallsiteMetadata(source, deopt_id, kind, locs,
                         pending_deoptimization_env_);
    AddStaticCallTarget(target, entry_kind);
  }
}

void FlowGraphCompiler::EmitEdgeCounter(intptr_t edge_id) {
  ASSERT(!edge_counters_array_.IsNull());
  ASSERT(assembler_->constant_pool_allowed());
  __ Comment("Edge counter");
  __ LoadObject(A0, edge_counters_array_);
  __ LoadFieldFromOffset(TMP, A0, Array::element_offset(edge_id));
  __ AddImmediate(TMP, TMP, Smi::RawValue(1));
  __ StoreFieldToOffset(TMP, A0, Array::element_offset(edge_id));
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

  __ LoadObject(A6, parsed_function().function());
  __ LoadFromOffset(A0, SP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize);
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

  __ LoadFromOffset(A0, SP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize);
  __ LoadUniqueObject(CODE_REG, stub);
  __ LoadUniqueObject(IC_DATA_REG, ic_data);
  const intptr_t entry_point_offset =
      entry_kind == Code::EntryKind::kNormal
          ? Code::entry_point_offset(Code::EntryKind::kMonomorphic)
          : Code::entry_point_offset(Code::EntryKind::kMonomorphicUnchecked);
  __ Load(RA, compiler::FieldAddress(CODE_REG, entry_point_offset));
  __ Call(RA);
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

  __ LoadFromOffset(A0, SP,
                    (args_desc.Count() - 1) * compiler::target::kWordSize);
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
  USE(entry_kind);
  ASSERT(CanCallDart());
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
  __ LoadImmediate(ARGS_DESC_REG, 0);
  __ LoadFromOffset(A0, SP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize);
  const auto snapshot_behavior =
      compiler::ObjectPoolBuilderEntry::kResetToSwitchableCallMissEntryPoint;
  __ LoadUniqueObject(RA, initial_stub, snapshot_behavior);
  __ LoadUniqueObject(IC_DATA_REG, data);
  __ Call(RA);

  EmitCallsiteMetadata(source, DeoptId::kNone, UntaggedPcDescriptors::kOther,
                       locs, pending_deoptimization_env_);
  EmitDropArguments(ic_data.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitUnoptimizedStaticCall(intptr_t size_with_type_args,
                                                  intptr_t deopt_id,
                                                  const InstructionSource& source,
                                                  LocationSummary* locs,
                                                  const ICData& ic_data,
                                                  Code::EntryKind entry_kind) {
  ASSERT(CanCallDart());
  const Code& stub =
      StubCode::UnoptimizedStaticCallEntry(ic_data.NumArgsTested());
  __ LoadObject(IC_DATA_REG, ic_data);
  GenerateDartCall(deopt_id, source, stub,
                   UntaggedPcDescriptors::kUnoptStaticCall, locs, entry_kind);
  EmitDropArguments(size_with_type_args);
}

void FlowGraphCompiler::EmitOptimizedStaticCall(const Function& function,
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
  } else if (!FLAG_precompiled_mode) {
    __ LoadImmediate(ARGS_DESC_REG, 0);
  }
  GenerateStaticDartCall(deopt_id, source, UntaggedPcDescriptors::kOther, locs,
                         function, entry_kind);
  EmitDropArguments(size_with_type_args);
}

void FlowGraphCompiler::EmitDispatchTableCall(int32_t selector_offset,
                                              const Array& arguments_descriptor) {
  const auto cid_reg = DispatchTableNullErrorABI::kClassIdReg;
  ASSERT(CanCallDart());
  ASSERT(cid_reg != ARGS_DESC_REG);
  if (!arguments_descriptor.IsNull()) {
    __ LoadObject(ARGS_DESC_REG, arguments_descriptor);
  }
  const uintptr_t offset = selector_offset - DispatchTable::kOriginElement;
  ASSERT(cid_reg != TMP);
  __ AddShifted(TMP, DISPATCH_TABLE_REG, cid_reg,
                compiler::target::kWordSizeLog2);
  __ LoadFromOffset(TMP, TMP, offset << compiler::target::kWordSizeLog2);
  __ Call(TMP);
}

Condition FlowGraphCompiler::EmitEqualityRegRegCompare(
    Register left,
    Register right,
    bool needs_number_check,
    const InstructionSource& source,
    intptr_t deopt_id) {
  if (needs_number_check) {
    __ PushRegisterPair(right, left);
    if (is_optimizing()) {
      __ JumpAndLink(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ JumpAndLinkPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(UntaggedPcDescriptors::kRuntimeCall, deopt_id, source);
    __ PopRegisterPair(right, left);
    // Loong64 has no condition flags; the identical stub returns zero in TMP
    // for equal and non-zero for non-equal.
    ASSERT(left != TMP);
    ASSERT(right != TMP);
    __ CompareImmediate(TMP, 0);
  } else {
    __ CompareObjectRegisters(left, right);
  }
  return EQ;
}

Condition FlowGraphCompiler::EmitEqualityRegConstCompare(
    Register reg,
    const Object& obj,
    bool needs_number_check,
    const InstructionSource& source,
    intptr_t deopt_id) {
  if (needs_number_check) {
    ASSERT(!obj.IsMint() && !obj.IsDouble());
    __ LoadObject(TMP, obj);
    __ PushRegisterPair(TMP, reg);
    if (is_optimizing()) {
      __ JumpAndLink(StubCode::OptimizedIdenticalWithNumberCheck());
      AddCurrentDescriptor(UntaggedPcDescriptors::kOther, deopt_id, source);
    } else {
      __ JumpAndLinkPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
      AddCurrentDescriptor(UntaggedPcDescriptors::kRuntimeCall, deopt_id,
                           source);
    }
    __ PopRegisterPair(ZR, reg);
    ASSERT(reg != TMP);
    __ CompareImmediate(TMP, 0);
  } else {
    __ CompareObject(reg, obj);
  }
  return EQ;
}

Condition FlowGraphCompiler::EmitBoolTest(Register value,
                                          BranchLabels labels,
                                          bool invert) {
  USE(labels);
  __ TestImmediate(value, compiler::target::ObjectAlignment::kBoolValueMask);
  return invert ? NE : EQ;
}

void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
#if defined(DEBUG)
  locs->CheckWritableInputs();
  ClobberDeadTempRegisters(locs);
#endif
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
      __ LoadImmediate(tmp.reg(), 0xf7);
    }
  }
}
#endif

Register FlowGraphCompiler::EmitTestCidRegister() {
  return A1;
}

void FlowGraphCompiler::EmitTestAndCallLoadReceiver(
    intptr_t count_without_type_args,
    const Array& arguments_descriptor) {
  __ Comment("EmitTestAndCall");
  __ LoadFromOffset(A0, SP, (count_without_type_args - 1) * kWordSize);
  __ LoadObject(ARGS_DESC_REG, arguments_descriptor);
}

void FlowGraphCompiler::EmitTestAndCallSmiBranch(compiler::Label* label,
                                                 bool if_smi) {
  if (if_smi) {
    __ BranchIfSmi(A0, label);
  } else {
    __ BranchIfNotSmi(A0, label);
  }
}

void FlowGraphCompiler::EmitTestAndCallLoadCid(Register class_id_reg) {
  ASSERT(class_id_reg != A0);
  __ LoadClassId(class_id_reg, A0);
}

void FlowGraphCompiler::EmitMove(Location destination,
                                 Location source,
                                 TemporaryRegisterAllocator* allocator) {
  USE(allocator);
  if (destination.Equals(source)) return;

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ MoveRegister(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      __ StoreToOffset(source.reg(), destination.base_reg(),
                       destination.ToStackSlotOffset());
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      __ LoadFromOffset(destination.reg(), source.base_reg(),
                        source.ToStackSlotOffset());
    } else if (destination.IsFpuRegister()) {
      __ LoadDFromOffset(destination.fpu_reg(), source.base_reg(),
                         source.ToStackSlotOffset());
    } else {
      ASSERT(destination.IsStackSlot());
      __ LoadFromOffset(TMP, source.base_reg(), source.ToStackSlotOffset());
      __ StoreToOffset(TMP, destination.base_reg(),
                       destination.ToStackSlotOffset());
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      __ MoveUnboxedSimd128(destination.fpu_reg(), source.fpu_reg());
    } else if (destination.IsStackSlot() || destination.IsDoubleStackSlot()) {
      __ StoreDToOffset(source.fpu_reg(), destination.base_reg(),
                        destination.ToStackSlotOffset());
    } else {
      ASSERT(destination.IsQuadStackSlot());
      __ StoreQToOffset(source.fpu_reg(), destination.base_reg(),
                        destination.ToStackSlotOffset());
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      __ LoadDFromOffset(destination.fpu_reg(), source.base_reg(),
                         source.ToStackSlotOffset());
    } else {
      ASSERT(destination.IsDoubleStackSlot() || destination.IsStackSlot());
      __ LoadDFromOffset(FTMP, source.base_reg(), source.ToStackSlotOffset());
      __ StoreDToOffset(FTMP, destination.base_reg(),
                        destination.ToStackSlotOffset());
    }
  } else if (source.IsQuadStackSlot()) {
    if (destination.IsFpuRegister()) {
      __ LoadQFromOffset(destination.fpu_reg(), source.base_reg(),
                         source.ToStackSlotOffset());
    } else {
      ASSERT(destination.IsQuadStackSlot());
      __ LoadQFromOffset(FTMP, source.base_reg(), source.ToStackSlotOffset());
      __ StoreQToOffset(FTMP, destination.base_reg(),
                        destination.ToStackSlotOffset());
    }
  } else if (source.IsPairLocation()) {
    UNREACHABLE();
  } else {
    ASSERT(source.IsConstant());
    source.constant_instruction()->EmitMoveToLocation(this, destination, TMP,
                                                      source.pair_index());
  }
}

static void EmitNativeStoreBySize(FlowGraphCompiler* compiler,
                                  Register src,
                                  Register base,
                                  intptr_t offset,
                                  intptr_t bytes);

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
    const Register src_reg = src.reg_at(0);

    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const Register dst_reg = dst.reg_at(0);
      ASSERT(destination.container_type().SizeInBytes() <=
             compiler::target::kWordSize);
      if (!sign_or_zero_extend) {
        if (src_size <= 4) {
          __ slli_d(dst_reg, src_reg, 32);
          __ srai_d(dst_reg, dst_reg, 32);
        } else {
          __ MoveRegister(dst_reg, src_reg);
        }
      } else {
        switch (src_type.AsPrimitive().representation()) {
          case compiler::ffi::kInt8:
            __ slli_d(dst_reg, src_reg, XLEN - 8);
            __ srai_d(dst_reg, dst_reg, XLEN - 8);
            return;
          case compiler::ffi::kInt16:
            __ slli_d(dst_reg, src_reg, XLEN - 16);
            __ srai_d(dst_reg, dst_reg, XLEN - 16);
            return;
          case compiler::ffi::kUint8:
            __ andi(dst_reg, src_reg, 0xFF);
            return;
          case compiler::ffi::kUint16:
            __ slli_d(dst_reg, src_reg, 16);
            __ srli_d(dst_reg, dst_reg, 16);
            return;
          case compiler::ffi::kUint32:
          case compiler::ffi::kInt32:
            __ slli_d(dst_reg, src_reg, 32);
            __ srai_d(dst_reg, dst_reg, 32);
            return;
          case compiler::ffi::kInt24:
          case compiler::ffi::kInt40:
          case compiler::ffi::kInt48:
          case compiler::ffi::kInt56:
            __ slli_d(dst_reg, src_reg, XLEN - src_size * kBitsPerByte);
            __ srai_d(dst_reg, dst_reg, XLEN - src_size * kBitsPerByte);
            return;
          case compiler::ffi::kUint24:
          case compiler::ffi::kUint40:
          case compiler::ffi::kUint48:
          case compiler::ffi::kUint56:
            __ slli_d(dst_reg, src_reg, XLEN - src_size * kBitsPerByte);
            __ srli_d(dst_reg, dst_reg, XLEN - src_size * kBitsPerByte);
            return;
          default:
            UNREACHABLE();
        }
      }
    } else if (destination.IsFpuRegisters()) {
      const auto& dst = destination.AsFpuRegisters();
      ASSERT(src_size == dst_size);
      ASSERT(src.num_regs() == 1);
      switch (src_size) {
        case 4:
          __ movgr2fr_w(dst.fpu_reg(), src.reg_at(0));
          return;
        case 8:
          __ movgr2fr_d(dst.fpu_reg(), src.reg_at(0));
          return;
        default:
          UNREACHABLE();
      }
    } else {
      ASSERT(destination.IsStack());
      const auto& dst = destination.AsStack();
      ASSERT(!sign_or_zero_extend);
      EmitNativeStoreBySize(this, src.reg_at(0), dst.base_register(),
                            dst.offset_in_bytes(),
                            destination.container_type().SizeInBytes());
    }
  } else if (source.IsFpuRegisters()) {
    const auto& src = source.AsFpuRegisters();
    ASSERT(src_type.Equals(dst_type));

    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(src_size == dst_size);
      ASSERT(dst.num_regs() == 1);
      switch (src_size) {
        case 4:
          __ movfr2gr_s(dst.reg_at(0), src.fpu_reg());
          return;
        case 8:
          __ movfr2gr_d(dst.reg_at(0), src.fpu_reg());
          return;
        default:
          UNREACHABLE();
      }
    } else if (destination.IsFpuRegisters()) {
      const auto& dst = destination.AsFpuRegisters();
      if (src_size == 4) {
        __ fmov_s(dst.fpu_reg(), src.fpu_reg());
      } else if (src_size == 16) {
        __ MoveUnboxedSimd128(dst.fpu_reg(), src.fpu_reg());
      } else {
        ASSERT(src_size == 8);
        __ fmov_d(dst.fpu_reg(), src.fpu_reg());
      }
    } else {
      ASSERT(destination.IsStack());
      ASSERT(src_type.IsFloat());
      const auto& dst = destination.AsStack();
      switch (dst_size) {
        case 16:
          __ StoreQToOffset(src.fpu_reg(), dst.base_register(),
                            dst.offset_in_bytes());
          return;
        case 8:
          __ StoreDToOffset(src.fpu_reg(), dst.base_register(),
                            dst.offset_in_bytes());
          return;
        case 4:
          __ StoreSToOffset(src.fpu_reg(), dst.base_register(),
                            dst.offset_in_bytes());
          return;
        default:
          UNREACHABLE();
      }
    }
  } else {
    ASSERT(source.IsStack());
    const auto& src = source.AsStack();
    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      EmitNativeLoad(dst.reg_at(0), src.base_register(), src.offset_in_bytes(),
                     src_type.AsPrimitive().representation());
    } else if (destination.IsFpuRegisters()) {
      ASSERT(src_type.Equals(dst_type));
      ASSERT(src_type.IsFloat());
      const auto& dst = destination.AsFpuRegisters();
      switch (src_size) {
        case 16:
          __ LoadQFromOffset(dst.fpu_reg(), src.base_register(),
                             src.offset_in_bytes());
          return;
        case 8:
          __ LoadDFromOffset(dst.fpu_reg(), src.base_register(),
                             src.offset_in_bytes());
          return;
        case 4:
          __ LoadSFromOffset(dst.fpu_reg(), src.base_register(),
                             src.offset_in_bytes());
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

#undef __
#define __ compiler->assembler()->

static void EmitNativeStoreBySize(FlowGraphCompiler* compiler,
                                  Register src,
                                  Register base,
                                  intptr_t offset,
                                  intptr_t bytes) {
  switch (bytes) {
    case 8:
      __ StoreToOffset(src, base, offset, compiler::kEightBytes);
      return;
    case 4:
      __ StoreToOffset(src, base, offset, compiler::kFourBytes);
      return;
    case 2:
      __ StoreToOffset(src, base, offset, compiler::kTwoBytes);
      return;
    case 1:
      __ StoreToOffset(src, base, offset, compiler::kByte);
      return;
    default:
      break;
  }

  Register tmp = kNoRegister;
  if (src != T1 && base != T1) tmp = T1;
  if (src != T3 && base != T3) tmp = T3;
  if (src != CALLEE_SAVED_TEMP && base != CALLEE_SAVED_TEMP) {
    tmp = CALLEE_SAVED_TEMP;
  }
  if (src != TMP && base != TMP) tmp = TMP;
  ASSERT(tmp != kNoRegister);
  if (base == SP) offset += compiler::target::kWordSize;
  __ PushRegister(tmp);

  switch (bytes) {
    case 3:
      __ StoreToOffset(src, base, offset, compiler::kTwoBytes);
      __ srli_d(tmp, src, 16);
      __ StoreToOffset(tmp, base, offset + 2, compiler::kByte);
      break;
    case 5:
      __ StoreToOffset(src, base, offset, compiler::kFourBytes);
      __ srli_d(tmp, src, 32);
      __ StoreToOffset(tmp, base, offset + 4, compiler::kByte);
      break;
    case 6:
      __ StoreToOffset(src, base, offset, compiler::kFourBytes);
      __ srli_d(tmp, src, 32);
      __ StoreToOffset(tmp, base, offset + 4, compiler::kTwoBytes);
      break;
    case 7:
      __ StoreToOffset(src, base, offset, compiler::kFourBytes);
      __ srli_d(tmp, src, 32);
      __ StoreToOffset(tmp, base, offset + 4, compiler::kTwoBytes);
      __ srli_d(tmp, tmp, 16);
      __ StoreToOffset(tmp, base, offset + 6, compiler::kByte);
      break;
    default:
      UNREACHABLE();
  }

  __ PopRegister(tmp);
}

#undef __
#define __ assembler()->

void FlowGraphCompiler::EmitNativeLoad(Register dst,
                                       Register base,
                                       intptr_t offset,
                                       compiler::ffi::PrimitiveType type) {
  switch (type) {
    case compiler::ffi::kInt8:
      __ Load(dst, compiler::Address(base, offset), compiler::kByte);
      return;
    case compiler::ffi::kUint8:
      __ Load(dst, compiler::Address(base, offset), compiler::kUnsignedByte);
      return;
    case compiler::ffi::kInt16:
      __ Load(dst, compiler::Address(base, offset), compiler::kTwoBytes);
      return;
    case compiler::ffi::kUint16:
      __ Load(dst, compiler::Address(base, offset),
              compiler::kUnsignedTwoBytes);
      return;
    case compiler::ffi::kInt32:
      __ Load(dst, compiler::Address(base, offset), compiler::kFourBytes);
      return;
    case compiler::ffi::kUint32:
    case compiler::ffi::kFloat:
      __ Load(dst, compiler::Address(base, offset),
              compiler::kUnsignedFourBytes);
      return;
    case compiler::ffi::kInt64:
    case compiler::ffi::kUint64:
    case compiler::ffi::kDouble:
      __ Load(dst, compiler::Address(base, offset), compiler::kEightBytes);
      return;
    default:
      break;
  }

  Register tmp = kNoRegister;
  if (dst != T1 && base != T1) tmp = T1;
  if (dst != T3 && base != T3) tmp = T3;
  if (dst != CALLEE_SAVED_TEMP && base != CALLEE_SAVED_TEMP) {
    tmp = CALLEE_SAVED_TEMP;
  }
  if (dst != TMP && base != TMP) tmp = TMP;
  ASSERT(tmp != kNoRegister);
  if (base == SP) offset += compiler::target::kWordSize;
  __ PushRegister(tmp);

  switch (type) {
    case compiler::ffi::kInt24:
      __ Load(dst, compiler::Address(base, offset), compiler::kUnsignedTwoBytes);
      __ Load(tmp, compiler::Address(base, offset + 2), compiler::kByte);
      __ slli_d(tmp, tmp, 16);
      __ or_(dst, dst, tmp);
      break;
    case compiler::ffi::kUint24:
      __ Load(dst, compiler::Address(base, offset), compiler::kUnsignedTwoBytes);
      __ Load(tmp, compiler::Address(base, offset + 2),
              compiler::kUnsignedByte);
      __ slli_d(tmp, tmp, 16);
      __ or_(dst, dst, tmp);
      break;
    case compiler::ffi::kInt40:
      __ Load(dst, compiler::Address(base, offset),
              compiler::kUnsignedFourBytes);
      __ Load(tmp, compiler::Address(base, offset + 4), compiler::kByte);
      __ slli_d(tmp, tmp, 32);
      __ or_(dst, dst, tmp);
      break;
    case compiler::ffi::kUint40:
      __ Load(dst, compiler::Address(base, offset),
              compiler::kUnsignedFourBytes);
      __ Load(tmp, compiler::Address(base, offset + 4),
              compiler::kUnsignedByte);
      __ slli_d(tmp, tmp, 32);
      __ or_(dst, dst, tmp);
      break;
    case compiler::ffi::kInt48:
      __ Load(dst, compiler::Address(base, offset),
              compiler::kUnsignedFourBytes);
      __ Load(tmp, compiler::Address(base, offset + 4), compiler::kTwoBytes);
      __ slli_d(tmp, tmp, 32);
      __ or_(dst, dst, tmp);
      break;
    case compiler::ffi::kUint48:
      __ Load(dst, compiler::Address(base, offset),
              compiler::kUnsignedFourBytes);
      __ Load(tmp, compiler::Address(base, offset + 4),
              compiler::kUnsignedTwoBytes);
      __ slli_d(tmp, tmp, 32);
      __ or_(dst, dst, tmp);
      break;
    case compiler::ffi::kInt56:
      __ Load(dst, compiler::Address(base, offset),
              compiler::kUnsignedFourBytes);
      __ Load(tmp, compiler::Address(base, offset + 4),
              compiler::kUnsignedTwoBytes);
      __ slli_d(tmp, tmp, 32);
      __ or_(dst, dst, tmp);
      __ Load(tmp, compiler::Address(base, offset + 6), compiler::kByte);
      __ slli_d(tmp, tmp, 48);
      __ or_(dst, dst, tmp);
      break;
    case compiler::ffi::kUint56:
      __ Load(dst, compiler::Address(base, offset),
              compiler::kUnsignedFourBytes);
      __ Load(tmp, compiler::Address(base, offset + 4),
              compiler::kUnsignedTwoBytes);
      __ slli_d(tmp, tmp, 32);
      __ or_(dst, dst, tmp);
      __ Load(tmp, compiler::Address(base, offset + 6),
              compiler::kUnsignedByte);
      __ slli_d(tmp, tmp, 48);
      __ or_(dst, dst, tmp);
      break;
    default:
      UNREACHABLE();
  }

  __ PopRegister(tmp);
}

#undef __
#define __ compiler_->assembler()->

void ParallelMoveEmitter::EmitSwap(const MoveOperands& move) {
  const Location source = move.src();
  const Location destination = move.dest();

  if (source.IsRegister() && destination.IsRegister()) {
    ASSERT(source.reg() != TMP);
    ASSERT(destination.reg() != TMP);
    __ MoveRegister(TMP, source.reg());
    __ MoveRegister(source.reg(), destination.reg());
    __ MoveRegister(destination.reg(), TMP);
  } else if (source.IsRegister() && destination.IsStackSlot()) {
    Exchange(source.reg(), destination.base_reg(),
             destination.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), source.base_reg(), source.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(source.base_reg(), source.ToStackSlotOffset(),
             destination.base_reg(), destination.ToStackSlotOffset());
  } else if (source.IsFpuRegister() && destination.IsFpuRegister()) {
    __ AddImmediate(SP, SP, -2 * kFpuRegisterSize);
    __ StoreQ(source.fpu_reg(), compiler::Address(SP));
    __ StoreQ(destination.fpu_reg(), compiler::Address(SP, kFpuRegisterSize));
    __ LoadQ(source.fpu_reg(), compiler::Address(SP, kFpuRegisterSize));
    __ LoadQ(destination.fpu_reg(), compiler::Address(SP));
    __ AddImmediate(SP, SP, 2 * kFpuRegisterSize);
  } else if (source.IsFpuRegister() || destination.IsFpuRegister()) {
    ASSERT(destination.IsStackSlot() || destination.IsDoubleStackSlot() ||
           destination.IsQuadStackSlot() || source.IsStackSlot() ||
           source.IsDoubleStackSlot() || source.IsQuadStackSlot());
    const FpuRegister reg =
        source.IsFpuRegister() ? source.fpu_reg() : destination.fpu_reg();
    const Location stack_slot = source.IsFpuRegister() ? destination : source;
    const intptr_t stack_offset = stack_slot.ToStackSlotOffset();

    ScratchFpuRegisterScope ensure_scratch(this, reg);
    const FpuRegister scratch = ensure_scratch.reg();
    if (stack_slot.IsQuadStackSlot()) {
      __ LoadQFromOffset(scratch, stack_slot.base_reg(), stack_offset);
      __ StoreQToOffset(reg, stack_slot.base_reg(), stack_offset);
      __ MoveUnboxedSimd128(reg, scratch);
    } else {
      __ LoadDFromOffset(scratch, stack_slot.base_reg(), stack_offset);
      __ StoreDToOffset(reg, stack_slot.base_reg(), stack_offset);
      __ fmov_d(reg, scratch);
    }
  } else if (source.IsDoubleStackSlot() && destination.IsDoubleStackSlot()) {
    __ AddImmediate(SP, SP, -static_cast<intptr_t>(sizeof(double)));
    __ LoadDFromOffset(FTMP, source.base_reg(), source.ToStackSlotOffset());
    __ StoreD(FTMP, compiler::Address(SP));
    __ LoadDFromOffset(FTMP, destination.base_reg(),
                       destination.ToStackSlotOffset());
    __ StoreDToOffset(FTMP, source.base_reg(), source.ToStackSlotOffset());
    __ LoadD(FTMP, compiler::Address(SP));
    __ StoreDToOffset(FTMP, destination.base_reg(),
                      destination.ToStackSlotOffset());
    __ AddImmediate(SP, SP, sizeof(double));
  } else if (source.IsQuadStackSlot() && destination.IsQuadStackSlot()) {
    __ AddImmediate(SP, SP, -kFpuRegisterSize);
    __ LoadQFromOffset(FTMP, source.base_reg(), source.ToStackSlotOffset());
    __ StoreQ(FTMP, compiler::Address(SP));
    __ LoadQFromOffset(FTMP, destination.base_reg(),
                       destination.ToStackSlotOffset());
    __ StoreQToOffset(FTMP, source.base_reg(), source.ToStackSlotOffset());
    __ LoadQ(FTMP, compiler::Address(SP));
    __ StoreQToOffset(FTMP, destination.base_reg(),
                      destination.ToStackSlotOffset());
    __ AddImmediate(SP, SP, kFpuRegisterSize);
  } else {
    UNREACHABLE();
  }
}

void ParallelMoveEmitter::MoveMemoryToMemory(const compiler::Address&,
                                             const compiler::Address&) {
  UNREACHABLE();
}

void ParallelMoveEmitter::Exchange(Register, const compiler::Address&) {
  UNREACHABLE();
}

void ParallelMoveEmitter::Exchange(const compiler::Address&,
                                   const compiler::Address&) {
  UNREACHABLE();
}

void ParallelMoveEmitter::Exchange(Register reg,
                                   Register base_reg,
                                   intptr_t stack_offset) {
  __ MoveRegister(TMP, reg);
  __ LoadFromOffset(reg, base_reg, stack_offset);
  __ StoreToOffset(TMP, base_reg, stack_offset);
}

void ParallelMoveEmitter::Exchange(Register base_reg1,
                                   intptr_t stack_offset1,
                                   Register base_reg2,
                                   intptr_t stack_offset2) {
  __ LoadFromOffset(TMP, base_reg1, stack_offset1);
  __ LoadFromOffset(TMP2, base_reg2, stack_offset2);
  __ StoreToOffset(TMP, base_reg2, stack_offset2);
  __ StoreToOffset(TMP2, base_reg1, stack_offset1);
}

void ParallelMoveEmitter::SpillScratch(Register reg) {
  __ PushRegister(reg);
}

void ParallelMoveEmitter::RestoreScratch(Register reg) {
  __ PopRegister(reg);
}

void ParallelMoveEmitter::SpillFpuScratch(FpuRegister reg) {
  __ AddImmediate(SP, SP, -kFpuRegisterSize);
  __ StoreQ(reg, compiler::Address(SP));
}

void ParallelMoveEmitter::RestoreFpuScratch(FpuRegister reg) {
  __ LoadQ(reg, compiler::Address(SP));
  __ AddImmediate(SP, SP, kFpuRegisterSize);
}

#undef __
#define __ assembler_->

namespace compiler {

static const RegisterSet kRuntimeCallSavedRegisters(kDartVolatileCpuRegs,
                                                    kDartVolatileFpuRegs);

LeafRuntimeScope::LeafRuntimeScope(Assembler* assembler,
                                   intptr_t frame_size,
                                   bool preserve_registers)
    : assembler_(assembler), preserve_registers_(preserve_registers) {
  __ AddImmediate(SP, SP, -4 * target::kWordSize);
  __ Store(RA, Address(SP, 3 * target::kWordSize));
  __ Store(FP, Address(SP, 2 * target::kWordSize));
  __ Store(CODE_REG, Address(SP, 1 * target::kWordSize));
  __ Store(PP, Address(SP, 0 * target::kWordSize));
  __ AddImmediate(FP, SP, 4 * target::kWordSize);

  if (preserve_registers) {
    __ PushRegisters(kRuntimeCallSavedRegisters);
  } else {
    COMPILE_ASSERT(!IsAbiPreservedRegister(CODE_REG));
    COMPILE_ASSERT(!IsAbiPreservedRegister(PP));
    COMPILE_ASSERT(IsCalleeSavedRegister(THR));
    COMPILE_ASSERT(IsCalleeSavedRegister(NULL_REG));
    COMPILE_ASSERT(IsCalleeSavedRegister(WRITE_BARRIER_STATE));
    COMPILE_ASSERT(IsCalleeSavedRegister(DISPATCH_TABLE_REG));
  }

  __ ReserveAlignedFrameSpace(frame_size);
}

LeafRuntimeScope::~LeafRuntimeScope() {
  if (preserve_registers_) {
    __ AddImmediate(SP, FP,
                    -(kRuntimeCallSavedRegisters.SpillSize() +
                      4 * target::kWordSize));
    __ PopRegisters(kRuntimeCallSavedRegisters);
  }

  __ AddImmediate(SP, FP, -4 * target::kWordSize);
  __ Load(PP, Address(SP, 0 * target::kWordSize));
  __ Load(CODE_REG, Address(SP, 1 * target::kWordSize));
  __ Load(FP, Address(SP, 2 * target::kWordSize));
  __ Load(RA, Address(SP, 3 * target::kWordSize));
  __ AddImmediate(SP, SP, 4 * target::kWordSize);
}

void LeafRuntimeScope::Call(const RuntimeEntry& entry, intptr_t argument_count) {
  ASSERT(argument_count == entry.argument_count());
  __ Load(TMP2, compiler::Address(THR, entry.OffsetFromThread()));
  __ Store(TMP2, compiler::Address(THR, target::Thread::vm_tag_offset()));
  __ Comment("Leaf runtime call: %s", entry.name());
  __ Call(TMP2);
  __ LoadImmediate(TMP2, VMTag::kDartTagId);
  __ Store(TMP2, compiler::Address(THR, target::Thread::vm_tag_offset()));
}

}  // namespace compiler
#undef __
}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
