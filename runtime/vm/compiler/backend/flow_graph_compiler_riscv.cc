// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_RISCV.
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

#include "vm/compiler/backend/flow_graph_compiler.h"

#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/locations.h"
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
  // Note: Unlike the other architectures, we are not using PC-relative calls
  // in AOT to call the write barrier stubs. We are making use of TMP as an
  // alternate link register to avoid spilling RA inline and don't want to
  // introduce another relocation type.
}

FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->jump_label()->IsLinked());
  }
}

bool FlowGraphCompiler::SupportsUnboxedDoubles() {
  return true;
}

bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  // TODO(riscv): Dynamically test for the vector extension and otherwise
  // allocate SIMD values to register-pairs or quads?
  return false;
}

bool FlowGraphCompiler::CanConvertInt64ToDouble() {
#if XLEN == 32
  return false;
#else
  return true;
#endif
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
  if (deopt_env_ == NULL) {
    ++builder->current_info_number_;
    return TypedData::null();
  }

  intptr_t stack_height = compiler->StackSize();
  AllocateIncomingParametersRecursive(deopt_env_, &stack_height);

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
  while (current != NULL) {
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
  ASSERT(previous != NULL);

  // Add slots for the outermost environment.
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
    __ trap();
  }

  ASSERT(deopt_env() != NULL);
  __ Call(compiler::Address(THR, Thread::deoptimize_entry_offset()));
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
  __ jalr(TTSInternalRegs::kScratchReg);
}

#undef __
#define __ assembler()->
// Instance methods of FlowGraphCompiler.

// Fall through if bool_register contains null.
void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           compiler::Label* is_true,
                                           compiler::Label* is_false) {
  compiler::Label fall_through;
  __ beq(bool_register, NULL_REG, &fall_through,
         compiler::Assembler::kNearJump);
  BranchLabels labels = {is_true, is_false, &fall_through};
  Condition true_condition =
      EmitBoolTest(bool_register, labels, /*invert=*/false);
  ASSERT(true_condition != kInvalidCondition);
  __ BranchIf(true_condition, is_true);
  __ j(is_false);
  __ Bind(&fall_through);
}

void FlowGraphCompiler::EmitInstructionEpilogue(Instruction* instr) {
  if (is_optimizing()) {
    return;
  }
  Definition* defn = instr->AsDefinition();
  if ((defn != NULL) && defn->HasTemp()) {
    const Location value = defn->locs()->out(0);
    if (value.IsRegister()) {
      __ PushRegister(value.reg());
    } else if (value.IsFpuRegister()) {
      ASSERT(instr->representation() == kUnboxedDouble);
      // In unoptimized code at instruction epilogue the only
      // live register is an output register.
      instr->locs()->live_registers()->Clear();
      __ MoveUnboxedDouble(BoxDoubleStubABI::kValueReg, value.fpu_reg());
      GenerateNonLazyDeoptableStubCall(
          InstructionSource(),  // No token position.
          StubCode::BoxDouble(), UntaggedPcDescriptors::kOther, instr->locs());
      __ PushRegister(BoxDoubleStubABI::kResultReg);
    } else {
      UNREACHABLE();
    }
  }
}

void FlowGraphCompiler::GenerateMethodExtractorIntrinsic(
    const Function& extracted_method,
    intptr_t type_arguments_field_offset) {
  // No frame has been setup here.
  ASSERT(!__ constant_pool_allowed());
  ASSERT(extracted_method.IsZoneHandle());

  const Code& build_method_extractor =
      Code::ZoneHandle(extracted_method.IsGeneric()
                           ? isolate_group()
                                 ->object_store()
                                 ->build_generic_method_extractor_code()
                           : isolate_group()
                                 ->object_store()
                                 ->build_nongeneric_method_extractor_code());

  const intptr_t stub_index = __ object_pool_builder().AddObject(
      build_method_extractor, ObjectPool::Patchability::kNotPatchable);
  const intptr_t function_index = __ object_pool_builder().AddObject(
      extracted_method, ObjectPool::Patchability::kNotPatchable);

  // We use a custom pool register to preserve caller PP.
  Register kPoolReg = A1;

  // T1 = extracted function
  // T4 = offset of type argument vector (or 0 if class is not generic)
  intptr_t pp_offset = 0;
  if (FLAG_precompiled_mode) {
    // PP is not tagged on riscv.
    kPoolReg = PP;
    pp_offset = kHeapObjectTag;
  } else {
    __ LoadFieldFromOffset(kPoolReg, CODE_REG, Code::object_pool_offset());
  }
  __ LoadImmediate(T4, type_arguments_field_offset);
  __ LoadFieldFromOffset(
      T1, kPoolReg, ObjectPool::element_offset(function_index) + pp_offset);
  __ LoadFieldFromOffset(CODE_REG, kPoolReg,
                         ObjectPool::element_offset(stub_index) + pp_offset);
  __ LoadFieldFromOffset(TMP, CODE_REG,
                         Code::entry_point_offset(Code::EntryKind::kUnchecked));
  __ jr(TMP);
}

void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  if (CanOptimizeFunction() && function.IsOptimizable() &&
      (!is_optimizing() || may_reoptimize())) {
    __ Comment("Invocation Count Check");
    const Register function_reg = A0;
    const Register usage_reg = A1;
    __ lx(function_reg, compiler::FieldAddress(CODE_REG, Code::owner_offset()));

    __ LoadFieldFromOffset(usage_reg, function_reg,
                           Function::usage_counter_offset(),
                           compiler::kFourBytes);
    // Reoptimization of an optimized function is triggered by counting in
    // IC stubs, but not at the entry of the function.
    if (!is_optimizing()) {
      __ addi(usage_reg, usage_reg, 1);
      __ StoreFieldToOffset(usage_reg, function_reg,
                            Function::usage_counter_offset(),
                            compiler::kFourBytes);
    }
    __ CompareImmediate(usage_reg, GetOptimizationThreshold());
    compiler::Label dont_optimize;
    __ BranchIf(LT, &dont_optimize, compiler::Assembler::kNearJump);
    __ lx(TMP, compiler::Address(THR, Thread::optimize_entry_offset()));
    __ jr(TMP);
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

  // In unoptimized code, initialize (non-argument) stack allocated slots.
  if (!is_optimizing()) {
    const int num_locals = parsed_function().num_stack_locals();

    intptr_t args_desc_slot = -1;
    if (parsed_function().has_arg_desc_var()) {
      args_desc_slot = compiler::target::frame_layout.FrameSlotForVariable(
          parsed_function().arg_desc_var());
    }

    __ Comment("Initialize spill slots");
    for (intptr_t i = 0; i < num_locals; ++i) {
      const intptr_t slot_index =
          compiler::target::frame_layout.FrameSlotForVariableIndex(-i);
      Register value_reg =
          slot_index == args_desc_slot ? ARGS_DESC_REG : NULL_REG;
      __ StoreToOffset(value_reg, FP, slot_index * kWordSize);
      // TODO(riscv): Using an SP-relative address instead of an FP-relative
      // address would allow for compressed instructions.
    }
  }

  EndCodeSourceRange(PrologueSource());
}

void FlowGraphCompiler::EmitCallToStub(const Code& stub) {
  ASSERT(!stub.IsNull());
  if (CanPcRelativeCall(stub)) {
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeCallStubTarget(stub);
  } else {
    __ JumpAndLink(stub);
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::EmitTailCallToStub(const Code& stub) {
  ASSERT(!stub.IsNull());
  if (CanPcRelativeCall(stub)) {
    __ LeaveDartFrame();
    __ GenerateUnRelocatedPcRelativeTailCall();
    AddPcRelativeTailCallStubTarget(stub);
#if defined(DEBUG)
    __ Breakpoint();
#endif
  } else {
    __ LoadObject(CODE_REG, stub);
    __ LeaveDartFrame();
    __ lx(TMP, compiler::FieldAddress(
                   CODE_REG, compiler::target::Code::entry_point_offset()));
    __ jr(TMP);
    AddStubCallTarget(stub);
  }
}

void FlowGraphCompiler::GeneratePatchableCall(const InstructionSource& source,
                                              const Code& stub,
                                              UntaggedPcDescriptors::Kind kind,
                                              LocationSummary* locs) {
  __ JumpAndLinkPatchable(stub);
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
  __ JumpAndLinkPatchable(stub, entry_kind);
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
    // Call sites to the same target can share object pool entries. These
    // call sites are never patched for breakpoints: the function is deoptimized
    // and the unoptimized code with IC calls for static calls is patched
    // instead.
    ASSERT(is_optimizing());
    const auto& stub = StubCode::CallStaticFunction();
    __ JumpAndLinkWithEquivalence(stub, target, entry_kind);
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
  __ LoadObject(A0, edge_counters_array_);
  __ LoadFieldFromOffset(TMP, A0, Array::element_offset(edge_id));
  __ addi(TMP, TMP, Smi::RawValue(1));
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
  // Each ICData propagated from unoptimized to optimized code contains the
  // function that corresponds to the Dart function of that IC call. Due
  // to inlining in optimized code, that function may not correspond to the
  // top-level function (parsed_function().function()) which could be
  // reoptimized and which counter needs to be incremented.
  // Pass the function explicitly, it is used in IC stub.

  __ LoadObject(A6, parsed_function().function());
  __ LoadFromOffset(A0, SP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize);
  __ LoadUniqueObject(IC_DATA_REG, ic_data);
  GenerateDartCall(deopt_id, source, stub, UntaggedPcDescriptors::kIcCall, locs,
                   entry_kind);
  __ Drop(ic_data.SizeWithTypeArgs());
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
  __ LoadUniqueObject(IC_DATA_REG, ic_data);
  __ LoadUniqueObject(CODE_REG, stub);
  const intptr_t entry_point_offset =
      entry_kind == Code::EntryKind::kNormal
          ? Code::entry_point_offset(Code::EntryKind::kMonomorphic)
          : Code::entry_point_offset(Code::EntryKind::kMonomorphicUnchecked);
  __ lx(RA, compiler::FieldAddress(CODE_REG, entry_point_offset));
  __ jalr(RA);
  EmitCallsiteMetadata(source, deopt_id, UntaggedPcDescriptors::kIcCall, locs,
                       pending_deoptimization_env_);
  __ Drop(ic_data.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const String& name,
    const Array& arguments_descriptor,
    intptr_t deopt_id,
    const InstructionSource& source,
    LocationSummary* locs) {
  ASSERT(CanCallDart());
  ASSERT(!arguments_descriptor.IsNull() && (arguments_descriptor.Length() > 0));
  const ArgumentsDescriptor args_desc(arguments_descriptor);
  const MegamorphicCache& cache = MegamorphicCache::ZoneHandle(
      zone(),
      MegamorphicCacheTable::Lookup(thread(), name, arguments_descriptor));

  __ Comment("MegamorphicCall");
  // Load receiver into A0.
  __ LoadFromOffset(A0, SP,
                    (args_desc.Count() - 1) * compiler::target::kWordSize);
  // Use same code pattern as instance call so it can be parsed by code patcher.
  if (FLAG_precompiled_mode) {
    UNIMPLEMENTED();
  } else {
    __ LoadUniqueObject(IC_DATA_REG, cache);
    __ LoadUniqueObject(CODE_REG, StubCode::MegamorphicCall());
    __ Call(compiler::FieldAddress(
        CODE_REG, Code::entry_point_offset(Code::EntryKind::kMonomorphic)));
  }

  RecordSafepoint(locs);
  AddCurrentDescriptor(UntaggedPcDescriptors::kOther, DeoptId::kNone, source);
  if (!FLAG_precompiled_mode) {
    const intptr_t deopt_id_after = DeoptId::ToDeoptAfter(deopt_id);
    if (is_optimizing()) {
      AddDeoptIndexAtCall(deopt_id_after, pending_deoptimization_env_);
    } else {
      // Add deoptimization continuation point after the call and before the
      // arguments are removed.
      AddCurrentDescriptor(UntaggedPcDescriptors::kDeopt, deopt_id_after,
                           source);
    }
  }
  RecordCatchEntryMoves(pending_deoptimization_env_);
  __ Drop(args_desc.SizeWithTypeArgs());
}

void FlowGraphCompiler::EmitInstanceCallAOT(const ICData& ic_data,
                                            intptr_t deopt_id,
                                            const InstructionSource& source,
                                            LocationSummary* locs,
                                            Code::EntryKind entry_kind,
                                            bool receiver_can_be_smi) {
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
  // Clear argument descriptor to keep gc happy when it gets pushed on to
  // the stack.
  __ LoadImmediate(ARGS_DESC_REG, 0);
  __ LoadFromOffset(A0, SP, (ic_data.SizeWithoutTypeArgs() - 1) * kWordSize);
  if (FLAG_precompiled_mode) {
    // The AOT runtime will replace the slot in the object pool with the
    // entrypoint address - see app_snapshot.cc.
    __ LoadUniqueObject(RA, initial_stub);
  } else {
    __ LoadUniqueObject(CODE_REG, initial_stub);
    const intptr_t entry_point_offset =
        entry_kind == Code::EntryKind::kNormal
            ? compiler::target::Code::entry_point_offset(
                  Code::EntryKind::kMonomorphic)
            : compiler::target::Code::entry_point_offset(
                  Code::EntryKind::kMonomorphicUnchecked);
    __ lx(RA, compiler::FieldAddress(CODE_REG, entry_point_offset));
  }
  __ LoadUniqueObject(IC_DATA_REG, data);
  __ jalr(RA);

  EmitCallsiteMetadata(source, DeoptId::kNone, UntaggedPcDescriptors::kOther,
                       locs, pending_deoptimization_env_);
  __ Drop(ic_data.SizeWithTypeArgs());
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
  __ LoadObject(IC_DATA_REG, ic_data);
  GenerateDartCall(deopt_id, source, stub,
                   UntaggedPcDescriptors::kUnoptStaticCall, locs, entry_kind);
  __ Drop(size_with_type_args);
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
  if (function.HasOptionalParameters() || function.IsGeneric()) {
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
  __ Drop(size_with_type_args);
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
  const intptr_t offset = selector_offset - DispatchTable::OriginElement();
  // Would like cid_reg to be available on entry to the target function
  // for checking purposes.
  ASSERT(cid_reg != TMP);
  intx_t imm = offset << compiler::target::kWordSizeLog2;
  intx_t lo = imm << (XLEN - 12) >> (XLEN - 12);
  intx_t hi = (imm - lo) << (XLEN - 32) >> (XLEN - 32);
  __ slli(TMP, cid_reg, compiler::target::kWordSizeLog2);
  if (hi != 0) {
    __ lui(TMP2, hi);
    __ add(TMP, TMP, TMP2);
  }
  __ add(TMP, TMP, DISPATCH_TABLE_REG);
  __ lx(TMP, compiler::Address(TMP, lo));
  __ jalr(TMP);
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
      __ JumpAndLinkPatchable(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ JumpAndLinkPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(UntaggedPcDescriptors::kRuntimeCall, deopt_id, source);
    __ PopRegisterPair(ZR, reg);
    // RISC-V has no condition flags, so the result is instead returned as
    // TMP zero if equal, non-zero if non-equal.
    ASSERT(reg != TMP);
    __ CompareImmediate(TMP, 0);
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
    __ PushRegisterPair(right, left);
    if (is_optimizing()) {
      __ JumpAndLinkPatchable(StubCode::OptimizedIdenticalWithNumberCheck());
    } else {
      __ JumpAndLinkPatchable(StubCode::UnoptimizedIdenticalWithNumberCheck());
    }
    AddCurrentDescriptor(UntaggedPcDescriptors::kRuntimeCall, deopt_id, source);
    __ PopRegisterPair(right, left);
    // RISC-V has no condition flags, so the result is instead returned as
    // TMP zero if equal, non-zero if non-equal.
    ASSERT(left != TMP);
    ASSERT(right != TMP);
    __ CompareImmediate(TMP, 0);
  } else {
    __ CompareObjectRegisters(left, right);
  }
  return EQ;
}

Condition FlowGraphCompiler::EmitBoolTest(Register value,
                                          BranchLabels labels,
                                          bool invert) {
  __ Comment("BoolTest");
  __ TestImmediate(value, compiler::target::ObjectAlignment::kBoolValueMask);
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
      __ li(tmp.reg(), 0xf7);
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
  // Load receiver into A0.
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

#undef __
#define __ assembler->

int FlowGraphCompiler::EmitTestAndCallCheckCid(compiler::Assembler* assembler,
                                               compiler::Label* label,
                                               Register class_id_reg,
                                               const CidRangeValue& range,
                                               int bias,
                                               bool jump_on_miss) {
  const intptr_t cid_start = range.cid_start;
  if (range.IsSingleCid()) {
    __ AddImmediate(class_id_reg, class_id_reg, bias - cid_start);
    if (jump_on_miss) {
      __ bnez(class_id_reg, label);
    } else {
      __ beqz(class_id_reg, label);
    }
    bias = cid_start;
  } else {
    __ AddImmediate(class_id_reg, class_id_reg, bias - cid_start);
    bias = cid_start;
    __ CompareImmediate(class_id_reg, range.Extent());
    __ BranchIf(jump_on_miss ? UNSIGNED_GREATER : UNSIGNED_LESS_EQUAL, label);
  }
  return bias;
}

#undef __
#define __ assembler()->

void FlowGraphCompiler::EmitMove(Location destination,
                                 Location source,
                                 TemporaryRegisterAllocator* allocator) {
  if (destination.Equals(source)) return;

  if (source.IsRegister()) {
    if (destination.IsRegister()) {
      __ mv(destination.reg(), source.reg());
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ StoreToOffset(source.reg(), destination.base_reg(), dest_offset);
    }
  } else if (source.IsStackSlot()) {
    if (destination.IsRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      __ LoadFromOffset(destination.reg(), source.base_reg(), source_offset);
    } else if (destination.IsFpuRegister()) {
      const intptr_t src_offset = source.ToStackSlotOffset();
      FRegister dst = destination.fpu_reg();
      __ fld(dst, compiler::Address(source.base_reg(), src_offset));
    } else {
      ASSERT(destination.IsStackSlot());
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      Register tmp = allocator->AllocateTemporary();
      __ LoadFromOffset(tmp, source.base_reg(), source_offset);
      __ StoreToOffset(tmp, destination.base_reg(), dest_offset);
      allocator->ReleaseTemporary();
    }
  } else if (source.IsFpuRegister()) {
    if (destination.IsFpuRegister()) {
      __ fmvd(destination.fpu_reg(), source.fpu_reg());
    } else {
      if (destination.IsStackSlot() /*32-bit float*/ ||
          destination.IsDoubleStackSlot()) {
        const intptr_t dest_offset = destination.ToStackSlotOffset();
        FRegister src = source.fpu_reg();
        __ fsd(src, compiler::Address(destination.base_reg(), dest_offset));
      } else {
        ASSERT(destination.IsQuadStackSlot());
        UNIMPLEMENTED();
      }
    }
  } else if (source.IsDoubleStackSlot()) {
    if (destination.IsFpuRegister()) {
      const intptr_t source_offset = source.ToStackSlotOffset();
      const FRegister dst = destination.fpu_reg();
      __ fld(dst, compiler::Address(source.base_reg(), source_offset));
    } else {
      ASSERT(destination.IsDoubleStackSlot() ||
             destination.IsStackSlot() /*32-bit float*/);
      const intptr_t source_offset = source.ToStackSlotOffset();
      const intptr_t dest_offset = destination.ToStackSlotOffset();
      __ fld(FTMP, compiler::Address(source.base_reg(), source_offset));
      __ fsd(FTMP, compiler::Address(destination.base_reg(), dest_offset));
    }
  } else if (source.IsQuadStackSlot()) {
    UNIMPLEMENTED();
  } else if (source.IsPairLocation()) {
#if XLEN == 32
    ASSERT(destination.IsPairLocation());
    for (intptr_t i : {0, 1}) {
      EmitMove(destination.Component(i), source.Component(i), allocator);
    }
#else
    UNREACHABLE();
#endif
  } else {
    ASSERT(source.IsConstant());
    if (destination.IsStackSlot()) {
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
    case 8:
      return compiler::OperandSize::kEightBytes;
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

// See FfiCallInstr::MakeLocationSummary.
static Register WithIntermediateMarshalling(Register r) {
  if (r == A2) return T2;  // A2=CODE_REG
  if (r == A3) return T3;  // A3=TMP
  if (r == A4) return T4;  // A4=TMP2
  if (r == A5) return T5;  // A5=PP
  return r;
}

void FlowGraphCompiler::EmitNativeMoveArchitecture(
    const compiler::ffi::NativeLocation& destination,
    const compiler::ffi::NativeLocation& source) {
  const auto& src_type = source.payload_type();
  const auto& dst_type = destination.payload_type();
  ASSERT(src_type.IsFloat() == dst_type.IsFloat());
  ASSERT(src_type.IsInt() == dst_type.IsInt());
  ASSERT(src_type.IsSigned() == dst_type.IsSigned());
  ASSERT(src_type.IsPrimitive());
  ASSERT(dst_type.IsPrimitive());
  const intptr_t src_size = src_type.SizeInBytes();
  const intptr_t dst_size = dst_type.SizeInBytes();
  const bool sign_or_zero_extend = dst_size > src_size;

  if (source.IsRegisters()) {
    const auto& src = source.AsRegisters();
    ASSERT(src.num_regs() == 1);
    const auto src_reg = WithIntermediateMarshalling(src.reg_at(0));

    if (destination.IsRegisters()) {
      const auto& dst = destination.AsRegisters();
      ASSERT(dst.num_regs() == 1);
      const auto dst_reg = WithIntermediateMarshalling(dst.reg_at(0));
      if (!sign_or_zero_extend) {
        __ mv(dst_reg, src_reg);
      } else {
        switch (src_type.AsPrimitive().representation()) {
          // Calling convention: scalars are extended according to the sign of
          // their type to 32-bits, then sign-extended to XLEN bits.
          case compiler::ffi::kInt8:
            __ slli(dst_reg, src_reg, XLEN - 8);
            __ srai(dst_reg, dst_reg, XLEN - 8);
            return;
          case compiler::ffi::kInt16:
            __ slli(dst_reg, src_reg, XLEN - 16);
            __ srai(dst_reg, dst_reg, XLEN - 16);
            return;
          case compiler::ffi::kUint8:
            __ andi(dst_reg, src_reg, 0xFF);
            return;
          case compiler::ffi::kUint16:
            __ slli(dst_reg, src_reg, 16);
#if XLEN == 32
            __ srli(dst_reg, dst_reg, 16);
#else
            __ srliw(dst_reg, dst_reg, 16);
#endif
            return;
#if XLEN >= 64
          case compiler::ffi::kUint32:
          case compiler::ffi::kInt32:
            // Note even uint32 is sign-extended to XLEN.
            __ addiw(dst_reg, src_reg, 0);
            return;
#endif
          default:
            UNREACHABLE();
        }
      }

    } else if (destination.IsFpuRegisters()) {
      // Fpu Registers should only contain doubles and registers only ints.
      UNIMPLEMENTED();

    } else {
      ASSERT(destination.IsStack());
      const auto& dst = destination.AsStack();
      ASSERT(!sign_or_zero_extend);
      auto const op_size = BytesToOperandSize(dst_size);
      __ StoreToOffset(src.reg_at(0), dst.base_register(),
                       dst.offset_in_bytes(), op_size);
    }
  } else if (source.IsFpuRegisters()) {
    const auto& src = source.AsFpuRegisters();
    // We have not implemented conversions here, use IL convert instructions.
    ASSERT(src_type.Equals(dst_type));

    if (destination.IsRegisters()) {
      // Fpu Registers should only contain doubles and registers only ints.
      UNIMPLEMENTED();

    } else if (destination.IsFpuRegisters()) {
      const auto& dst = destination.AsFpuRegisters();
      __ fmvd(dst.fpu_reg(), src.fpu_reg());

    } else {
      ASSERT(destination.IsStack());
      ASSERT(src_type.IsFloat());
      const auto& dst = destination.AsStack();
      switch (dst_size) {
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
      const auto dst_reg = WithIntermediateMarshalling(dst.reg_at(0));
      ASSERT(!sign_or_zero_extend);
      __ LoadFromOffset(dst_reg, src.base_register(), src.offset_in_bytes(),
                        BytesToOperandSize(dst_size));
    } else if (destination.IsFpuRegisters()) {
      ASSERT(src_type.Equals(dst_type));
      ASSERT(src_type.IsFloat());
      const auto& dst = destination.AsFpuRegisters();
      switch (src_size) {
        case 8:
          __ LoadDFromOffset(dst.fpu_reg(), src.base_register(),
                             src.offset_in_bytes());
          return;
        case 4:
          __ LoadSFromOffset(dst.fpu_reg(), src.base_register(),
                             src.offset_in_bytes());
          return;
        default:
          UNIMPLEMENTED();
      }
    } else if (destination.IsStack()) {
      const auto& dst = destination.AsStack();
      // TMP=A3, here not remapped to T3.
      __ LoadFromOffset(TMP, src.base_register(), src.offset_in_bytes(),
                        BytesToOperandSize(src_size));
      __ StoreToOffset(TMP, dst.base_register(), dst.offset_in_bytes(),
                       BytesToOperandSize(dst_size));
    } else {
      UNREACHABLE();
    }
  }
}

void FlowGraphCompiler::LoadBSSEntry(BSS::Relocation relocation,
                                     Register dst,
                                     Register tmp) {
  UNIMPLEMENTED();
}

#undef __
#define __ compiler_->assembler()->

void ParallelMoveResolver::EmitSwap(int index) {
  MoveOperands* move = moves_[index];
  const Location source = move->src();
  const Location destination = move->dest();

  if (source.IsRegister() && destination.IsRegister()) {
    ASSERT(source.reg() != TMP);
    ASSERT(destination.reg() != TMP);
    __ mv(TMP, source.reg());
    __ mv(source.reg(), destination.reg());
    __ mv(destination.reg(), TMP);
  } else if (source.IsRegister() && destination.IsStackSlot()) {
    Exchange(source.reg(), destination.base_reg(),
             destination.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsRegister()) {
    Exchange(destination.reg(), source.base_reg(), source.ToStackSlotOffset());
  } else if (source.IsStackSlot() && destination.IsStackSlot()) {
    Exchange(source.base_reg(), source.ToStackSlotOffset(),
             destination.base_reg(), destination.ToStackSlotOffset());
  } else if (source.IsFpuRegister() && destination.IsFpuRegister()) {
    const FRegister dst = destination.fpu_reg();
    const FRegister src = source.fpu_reg();
    __ fmvd(FTMP, src);
    __ fmvd(src, dst);
    __ fmvd(dst, FTMP);
  } else if (source.IsFpuRegister() || destination.IsFpuRegister()) {
    UNIMPLEMENTED();
  } else if (source.IsDoubleStackSlot() && destination.IsDoubleStackSlot()) {
    const intptr_t source_offset = source.ToStackSlotOffset();
    const intptr_t dest_offset = destination.ToStackSlotOffset();

    ScratchFpuRegisterScope ensure_scratch(this, kNoFpuRegister);
    FRegister scratch = ensure_scratch.reg();
    __ LoadDFromOffset(FTMP, source.base_reg(), source_offset);
    __ LoadDFromOffset(scratch, destination.base_reg(), dest_offset);
    __ StoreDToOffset(FTMP, destination.base_reg(), dest_offset);
    __ StoreDToOffset(scratch, source.base_reg(), source_offset);
  } else if (source.IsQuadStackSlot() && destination.IsQuadStackSlot()) {
    UNIMPLEMENTED();
  } else {
    UNREACHABLE();
  }

  // The swap of source and destination has executed a move from source to
  // destination.
  move->Eliminate();

  // Any unperformed (including pending) move with a source of either
  // this move's source or destination needs to have their source
  // changed to reflect the state of affairs after the swap.
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& other_move = *moves_[i];
    if (other_move.Blocks(source)) {
      moves_[i]->set_src(destination);
    } else if (other_move.Blocks(destination)) {
      moves_[i]->set_src(source);
    }
  }
}

void ParallelMoveResolver::MoveMemoryToMemory(const compiler::Address& dst,
                                              const compiler::Address& src) {
  UNREACHABLE();
}

// Do not call or implement this function. Instead, use the form below that
// uses an offset from the frame pointer instead of an Address.
void ParallelMoveResolver::Exchange(Register reg,
                                    const compiler::Address& mem) {
  UNREACHABLE();
}

// Do not call or implement this function. Instead, use the form below that
// uses offsets from the frame pointer instead of Addresses.
void ParallelMoveResolver::Exchange(const compiler::Address& mem1,
                                    const compiler::Address& mem2) {
  UNREACHABLE();
}

void ParallelMoveResolver::Exchange(Register reg,
                                    Register base_reg,
                                    intptr_t stack_offset) {
  ScratchRegisterScope tmp(this, reg);
  __ mv(tmp.reg(), reg);
  __ LoadFromOffset(reg, base_reg, stack_offset);
  __ StoreToOffset(tmp.reg(), base_reg, stack_offset);
}

void ParallelMoveResolver::Exchange(Register base_reg1,
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

void ParallelMoveResolver::SpillScratch(Register reg) {
  __ PushRegister(reg);
}

void ParallelMoveResolver::RestoreScratch(Register reg) {
  __ PopRegister(reg);
}

void ParallelMoveResolver::SpillFpuScratch(FpuRegister reg) {
  __ subi(SP, SP, sizeof(double));
  __ fsd(reg, compiler::Address(SP, 0));
}

void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  __ fld(reg, compiler::Address(SP, 0));
  __ addi(SP, SP, sizeof(double));
}

#undef __

}  // namespace dart

#endif  // defined(TARGET_ARCH_RISCV)
