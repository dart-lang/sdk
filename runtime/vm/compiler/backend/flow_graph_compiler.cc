// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/globals.h"  // Needed here to get TARGET_ARCH_XXX.

#include "platform/utils.h"
#include "vm/bit_vector.h"
#include "vm/compiler/backend/code_statistics.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/loops.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/intrinsifier.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/kernel_isolate.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/raw_object.h"
#include "vm/resolver.h"
#include "vm/service_isolate.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#include "vm/type_testing_stubs.h"

namespace dart {

DEFINE_FLAG(bool,
            trace_inlining_intervals,
            false,
            "Inlining interval diagnostics");

DEFINE_FLAG(bool, enable_peephole, true, "Enable peephole optimization");

DEFINE_FLAG(bool,
            enable_simd_inline,
            true,
            "Enable inlining of SIMD related method calls.");
DEFINE_FLAG(int,
            min_optimization_counter_threshold,
            5000,
            "The minimum invocation count for a function.");
DEFINE_FLAG(int,
            optimization_counter_scale,
            2000,
            "The scale of invocation count, by size of the function.");
DEFINE_FLAG(bool, source_lines, false, "Emit source line as assembly comment.");

DECLARE_FLAG(charp, deoptimize_filter);
DECLARE_FLAG(bool, intrinsify);
DECLARE_FLAG(int, regexp_optimization_counter_threshold);
DECLARE_FLAG(int, reoptimization_counter_threshold);
DECLARE_FLAG(int, stacktrace_every);
DECLARE_FLAG(charp, stacktrace_filter);
DECLARE_FLAG(int, gc_every);
DECLARE_FLAG(bool, trace_compiler);

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
compiler::LRState ComputeInnerLRState(const FlowGraph& flow_graph) {
  auto entry = flow_graph.graph_entry();
  const bool frameless = !entry->NeedsFrame();

  bool has_native_entries = false;
  for (intptr_t i = 0; i < entry->SuccessorCount(); i++) {
    if (entry->SuccessorAt(i)->IsNativeEntry()) {
      has_native_entries = true;
      break;
    }
  }

  auto state = compiler::LRState::OnEntry();
  if (has_native_entries) {
    // We will setup three (3) frames on the stack when entering through
    // native entry. Keep in sync with NativeEntry/NativeReturn.
    state = state.EnterFrame().EnterFrame();
  }

  if (!frameless) {
    state = state.EnterFrame();
  }

  return state;
}
#endif

// Assign locations to incoming arguments, i.e., values pushed above spill slots
// with PushArgument.  Recursively allocates from outermost to innermost
// environment.
void CompilerDeoptInfo::AllocateIncomingParametersRecursive(
    Environment* env,
    intptr_t* stack_height) {
  if (env == NULL) return;
  AllocateIncomingParametersRecursive(env->outer(), stack_height);
  for (Environment::ShallowIterator it(env); !it.Done(); it.Advance()) {
    if (it.CurrentLocation().IsInvalid() &&
        it.CurrentValue()->definition()->IsPushArgument()) {
      it.SetCurrentLocation(Location::StackSlot(
          compiler::target::frame_layout.FrameSlotForVariableIndex(
              -*stack_height),
          FPREG));
      (*stack_height)++;
    }
  }
}

void CompilerDeoptInfo::EmitMaterializations(Environment* env,
                                             DeoptInfoBuilder* builder) {
  for (Environment::DeepIterator it(env); !it.Done(); it.Advance()) {
    if (it.CurrentLocation().IsInvalid()) {
      MaterializeObjectInstr* mat =
          it.CurrentValue()->definition()->AsMaterializeObject();
      ASSERT(mat != NULL);
      builder->AddMaterialization(mat);
    }
  }
}

FlowGraphCompiler::FlowGraphCompiler(
    compiler::Assembler* assembler,
    FlowGraph* flow_graph,
    const ParsedFunction& parsed_function,
    bool is_optimizing,
    SpeculativeInliningPolicy* speculative_policy,
    const GrowableArray<const Function*>& inline_id_to_function,
    const GrowableArray<TokenPosition>& inline_id_to_token_pos,
    const GrowableArray<intptr_t>& caller_inline_id,
    ZoneGrowableArray<const ICData*>* deopt_id_to_ic_data,
    CodeStatistics* stats /* = NULL */)
    : thread_(Thread::Current()),
      zone_(Thread::Current()->zone()),
      assembler_(assembler),
      parsed_function_(parsed_function),
      flow_graph_(*flow_graph),
      block_order_(*flow_graph->CodegenBlockOrder(is_optimizing)),
      current_block_(nullptr),
      exception_handlers_list_(nullptr),
      pc_descriptors_list_(nullptr),
      compressed_stackmaps_builder_(nullptr),
      code_source_map_builder_(nullptr),
      catch_entry_moves_maps_builder_(nullptr),
      block_info_(block_order_.length()),
      deopt_infos_(),
      static_calls_target_table_(),
      indirect_gotos_(),
      is_optimizing_(is_optimizing),
      speculative_policy_(speculative_policy),
      may_reoptimize_(false),
      intrinsic_mode_(false),
      stats_(stats),
      double_class_(
          Class::ZoneHandle(isolate()->object_store()->double_class())),
      mint_class_(Class::ZoneHandle(isolate()->object_store()->mint_class())),
      float32x4_class_(
          Class::ZoneHandle(isolate()->object_store()->float32x4_class())),
      float64x2_class_(
          Class::ZoneHandle(isolate()->object_store()->float64x2_class())),
      int32x4_class_(
          Class::ZoneHandle(isolate()->object_store()->int32x4_class())),
      list_class_(Class::ZoneHandle(Library::Handle(Library::CoreLibrary())
                                        .LookupClass(Symbols::List()))),
      parallel_move_resolver_(this),
      pending_deoptimization_env_(NULL),
      deopt_id_to_ic_data_(deopt_id_to_ic_data),
      edge_counters_array_(Array::ZoneHandle()) {
  ASSERT(flow_graph->parsed_function().function().raw() ==
         parsed_function.function().raw());
  if (is_optimizing) {
    // No need to collect extra ICData objects created during compilation.
    deopt_id_to_ic_data_ = nullptr;
  } else {
    const intptr_t len = thread()->compiler_state().deopt_id();
    deopt_id_to_ic_data_->EnsureLength(len, nullptr);
  }
  ASSERT(assembler != NULL);
  ASSERT(!list_class_.IsNull());

#if defined(PRODUCT)
  const bool stack_traces_only = true;
#else
  const bool stack_traces_only = false;
#endif
  // Make sure that the function is at the position for inline_id 0.
  ASSERT(inline_id_to_function.length() >= 1);
  ASSERT(inline_id_to_function[0]->raw() ==
         flow_graph->parsed_function().function().raw());
  code_source_map_builder_ = new (zone_)
      CodeSourceMapBuilder(zone_, stack_traces_only, caller_inline_id,
                           inline_id_to_token_pos, inline_id_to_function);

  ArchSpecificInitialization();
}

bool FlowGraphCompiler::IsUnboxedField(const Field& field) {
  // The `field.is_non_nullable_integer()` is set in the kernel loader and can
  // only be set if we consume a AOT kernel (annotated with inferred types).
  ASSERT(!field.is_non_nullable_integer() || FLAG_precompiled_mode);
  // Unboxed fields in JIT lightweight isolates mode are not supported yet.
  const bool valid_class =
      (FLAG_precompiled_mode || !FLAG_enable_isolate_groups) &&
      ((SupportsUnboxedDoubles() && (field.guarded_cid() == kDoubleCid)) ||
       (SupportsUnboxedSimd128() && (field.guarded_cid() == kFloat32x4Cid)) ||
       (SupportsUnboxedSimd128() && (field.guarded_cid() == kFloat64x2Cid)) ||
       field.is_non_nullable_integer());
  return field.is_unboxing_candidate() && !field.is_nullable() && valid_class;
}

bool FlowGraphCompiler::IsPotentialUnboxedField(const Field& field) {
  if (FLAG_precompiled_mode) {
    // kernel_loader.cc:ReadInferredType sets the guarded cid for fields based
    // on inferred types from TFA (if available). The guarded cid is therefore
    // proven to be correct.
    return IsUnboxedField(field);
  }
  // Unboxed fields in JIT lightweight isolates mode are not supported yet.
  return !FLAG_enable_isolate_groups && field.is_unboxing_candidate() &&
         (FlowGraphCompiler::IsUnboxedField(field) ||
          (field.guarded_cid() == kIllegalCid));
}

void FlowGraphCompiler::InitCompiler() {
  compressed_stackmaps_builder_ =
      new (zone()) CompressedStackMapsBuilder(zone());
  pc_descriptors_list_ = new (zone()) DescriptorList(
      zone(), &code_source_map_builder_->inline_id_to_function());
  exception_handlers_list_ = new (zone()) ExceptionHandlerList();
#if defined(DART_PRECOMPILER)
  catch_entry_moves_maps_builder_ = new (zone()) CatchEntryMovesMapBuilder();
#endif
  block_info_.Clear();
  // Initialize block info and search optimized (non-OSR) code for calls
  // indicating a non-leaf routine and calls without IC data indicating
  // possible reoptimization.

  for (int i = 0; i < block_order_.length(); ++i) {
    block_info_.Add(new (zone()) BlockInfo());
    if (is_optimizing() && !flow_graph().IsCompiledForOsr()) {
      BlockEntryInstr* entry = block_order_[i];
      for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
        Instruction* current = it.Current();
        if (current->IsBranch()) {
          current = current->AsBranch()->comparison();
        }
        // In optimized code, ICData is always set in the instructions.
        const ICData* ic_data = NULL;
        if (current->IsInstanceCall()) {
          ic_data = current->AsInstanceCall()->ic_data();
        }
        if ((ic_data != NULL) && (ic_data->NumberOfUsedChecks() == 0)) {
          may_reoptimize_ = true;
        }
      }
    }
  }

  if (!is_optimizing() && FLAG_reorder_basic_blocks) {
    // Initialize edge counter array.
    const intptr_t num_counters = flow_graph_.preorder().length();
    const Array& edge_counters =
        Array::Handle(Array::New(num_counters, Heap::kOld));
    for (intptr_t i = 0; i < num_counters; ++i) {
      edge_counters.SetAt(i, Object::smi_zero());
    }
    edge_counters_array_ = edge_counters.raw();
  }
}

bool FlowGraphCompiler::CanOptimize() {
  return FLAG_optimization_counter_threshold >= 0;
}

bool FlowGraphCompiler::CanOptimizeFunction() const {
  return CanOptimize() && !parsed_function().function().HasBreakpoint();
}

bool FlowGraphCompiler::CanOSRFunction() const {
  return isolate()->use_osr() && CanOptimizeFunction() && !is_optimizing();
}

void FlowGraphCompiler::InsertBSSRelocation(BSS::Relocation reloc) {
  const intptr_t offset = assembler()->InsertAlignedRelocation(reloc);
  AddDescriptor(PcDescriptorsLayout::kBSSRelocation, /*pc_offset=*/offset,
                /*deopt_id=*/DeoptId::kNone, InstructionSource(),
                /*try_index=*/-1);
}

bool FlowGraphCompiler::ForceSlowPathForStackOverflow() const {
#if !defined(PRODUCT)
  if ((FLAG_stacktrace_every > 0) || (FLAG_deoptimize_every > 0) ||
      (FLAG_gc_every > 0) ||
      (isolate()->reload_every_n_stack_overflow_checks() > 0)) {
    if (!Isolate::IsSystemIsolate(isolate())) {
      return true;
    }
  }
  if (FLAG_stacktrace_filter != NULL &&
      strstr(parsed_function().function().ToFullyQualifiedCString(),
             FLAG_stacktrace_filter) != NULL) {
    return true;
  }
  if (is_optimizing() && FLAG_deoptimize_filter != NULL &&
      strstr(parsed_function().function().ToFullyQualifiedCString(),
             FLAG_deoptimize_filter) != NULL) {
    return true;
  }
#endif  // !defined(PRODUCT)
  return false;
}

bool FlowGraphCompiler::IsEmptyBlock(BlockEntryInstr* block) const {
  // Entry-points cannot be merged because they must have assembly
  // prologue emitted which should not be included in any block they jump to.
  return !block->IsGraphEntry() && !block->IsFunctionEntry() &&
         !block->IsCatchBlockEntry() && !block->IsOsrEntry() &&
         !block->IsIndirectEntry() && !block->HasNonRedundantParallelMove() &&
         block->next()->IsGoto() &&
         !block->next()->AsGoto()->HasNonRedundantParallelMove();
}

void FlowGraphCompiler::CompactBlock(BlockEntryInstr* block) {
  BlockInfo* block_info = block_info_[block->postorder_number()];

  // Break out of cycles in the control flow graph.
  if (block_info->is_marked()) {
    return;
  }
  block_info->mark();

  if (IsEmptyBlock(block)) {
    // For empty blocks, record a corresponding nonempty target as their
    // jump label.
    BlockEntryInstr* target = block->next()->AsGoto()->successor();
    CompactBlock(target);
    block_info->set_jump_label(GetJumpLabel(target));
  }
}

void FlowGraphCompiler::CompactBlocks() {
  // This algorithm does not garbage collect blocks in place, but merely
  // records forwarding label information.  In this way it avoids having to
  // change join and target entries.
  compiler::Label* nonempty_label = NULL;
  for (intptr_t i = block_order().length() - 1; i >= 1; --i) {
    BlockEntryInstr* block = block_order()[i];

    // Unoptimized code must emit all possible deoptimization points.
    if (is_optimizing()) {
      CompactBlock(block);
    }

    // For nonempty blocks, record the next nonempty block in the block
    // order.  Since no code is emitted for empty blocks, control flow is
    // eligible to fall through to the next nonempty one.
    if (!WasCompacted(block)) {
      BlockInfo* block_info = block_info_[block->postorder_number()];
      block_info->set_next_nonempty_label(nonempty_label);
      nonempty_label = GetJumpLabel(block);
    }
  }

  ASSERT(block_order()[0]->IsGraphEntry());
  BlockInfo* block_info = block_info_[block_order()[0]->postorder_number()];
  block_info->set_next_nonempty_label(nonempty_label);
}

#if defined(DART_PRECOMPILER)
static intptr_t LocationToStackIndex(const Location& src) {
  ASSERT(src.HasStackIndex());
  return -compiler::target::frame_layout.VariableIndexForFrameSlot(
      src.stack_index());
}

static CatchEntryMove CatchEntryMoveFor(compiler::Assembler* assembler,
                                        Representation src_type,
                                        const Location& src,
                                        intptr_t dst_index) {
  if (src.IsConstant()) {
    // Skip dead locations.
    if (src.constant().raw() == Symbols::OptimizedOut().raw()) {
      return CatchEntryMove();
    }
    const intptr_t pool_index =
        assembler->object_pool_builder().FindObject(src.constant());
    return CatchEntryMove::FromSlot(CatchEntryMove::SourceKind::kConstant,
                                    pool_index, dst_index);
  }

  if (src.IsPairLocation()) {
    const auto lo_loc = src.AsPairLocation()->At(0);
    const auto hi_loc = src.AsPairLocation()->At(1);
    ASSERT(lo_loc.IsStackSlot() && hi_loc.IsStackSlot());
    return CatchEntryMove::FromSlot(
        CatchEntryMove::SourceKind::kInt64PairSlot,
        CatchEntryMove::EncodePairSource(LocationToStackIndex(lo_loc),
                                         LocationToStackIndex(hi_loc)),
        dst_index);
  }

  CatchEntryMove::SourceKind src_kind;
  switch (src_type) {
    case kTagged:
      src_kind = CatchEntryMove::SourceKind::kTaggedSlot;
      break;
    case kUnboxedInt64:
      src_kind = CatchEntryMove::SourceKind::kInt64Slot;
      break;
    case kUnboxedInt32:
      src_kind = CatchEntryMove::SourceKind::kInt32Slot;
      break;
    case kUnboxedUint32:
      src_kind = CatchEntryMove::SourceKind::kUint32Slot;
      break;
    case kUnboxedDouble:
      src_kind = CatchEntryMove::SourceKind::kDoubleSlot;
      break;
    case kUnboxedFloat32x4:
      src_kind = CatchEntryMove::SourceKind::kFloat32x4Slot;
      break;
    case kUnboxedFloat64x2:
      src_kind = CatchEntryMove::SourceKind::kFloat64x2Slot;
      break;
    case kUnboxedInt32x4:
      src_kind = CatchEntryMove::SourceKind::kInt32x4Slot;
      break;
    default:
      UNREACHABLE();
      break;
  }

  return CatchEntryMove::FromSlot(src_kind, LocationToStackIndex(src),
                                  dst_index);
}
#endif

void FlowGraphCompiler::RecordCatchEntryMoves(Environment* env,
                                              intptr_t try_index) {
#if defined(DART_PRECOMPILER)
  env = env ? env : pending_deoptimization_env_;
  try_index = try_index != kInvalidTryIndex ? try_index : CurrentTryIndex();
  if (is_optimizing() && env != nullptr && (try_index != kInvalidTryIndex)) {
    env = env->Outermost();
    CatchBlockEntryInstr* catch_block =
        flow_graph().graph_entry()->GetCatchEntry(try_index);
    const GrowableArray<Definition*>* idefs =
        catch_block->initial_definitions();
    catch_entry_moves_maps_builder_->NewMapping(assembler()->CodeSize());

    const intptr_t num_direct_parameters = flow_graph().num_direct_parameters();
    const intptr_t ex_idx =
        catch_block->raw_exception_var() != nullptr
            ? flow_graph().EnvIndex(catch_block->raw_exception_var())
            : -1;
    const intptr_t st_idx =
        catch_block->raw_stacktrace_var() != nullptr
            ? flow_graph().EnvIndex(catch_block->raw_stacktrace_var())
            : -1;
    for (intptr_t i = 0; i < flow_graph().variable_count(); ++i) {
      // Don't sync captured parameters. They are not in the environment.
      if (flow_graph().captured_parameters()->Contains(i)) continue;
      // Don't sync exception or stack trace variables.
      if (i == ex_idx || i == st_idx) continue;
      // Don't sync values that have been replaced with constants.
      if ((*idefs)[i]->IsConstant()) continue;

      Location src = env->LocationAt(i);
      // Can only occur if AllocationSinking is enabled - and it is disabled
      // in functions with try.
      ASSERT(!src.IsInvalid());
      const Representation src_type =
          env->ValueAt(i)->definition()->representation();
      intptr_t dest_index = i - num_direct_parameters;
      const auto move =
          CatchEntryMoveFor(assembler(), src_type, src, dest_index);
      if (!move.IsRedundant()) {
        catch_entry_moves_maps_builder_->Append(move);
      }
    }

    catch_entry_moves_maps_builder_->EndMapping();
  }
#endif  // defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME)
}

void FlowGraphCompiler::EmitCallsiteMetadata(const InstructionSource& source,
                                             intptr_t deopt_id,
                                             PcDescriptorsLayout::Kind kind,
                                             LocationSummary* locs,
                                             Environment* env) {
  AddCurrentDescriptor(kind, deopt_id, source);
  RecordSafepoint(locs);
  RecordCatchEntryMoves(env);
  if ((deopt_id != DeoptId::kNone) && !FLAG_precompiled_mode) {
    // Marks either the continuation point in unoptimized code or the
    // deoptimization point in optimized code, after call.
    const intptr_t deopt_id_after = DeoptId::ToDeoptAfter(deopt_id);
    if (is_optimizing()) {
      AddDeoptIndexAtCall(deopt_id_after);
    } else {
      // Add deoptimization continuation point after the call and before the
      // arguments are removed.
      AddCurrentDescriptor(PcDescriptorsLayout::kDeopt, deopt_id_after, source);
    }
  }
}

void FlowGraphCompiler::EmitYieldPositionMetadata(
    const InstructionSource& source,
    intptr_t yield_index) {
  AddDescriptor(PcDescriptorsLayout::kOther, assembler()->CodeSize(),
                DeoptId::kNone, source, CurrentTryIndex(), yield_index);
}

void FlowGraphCompiler::EmitInstructionPrologue(Instruction* instr) {
  if (!is_optimizing()) {
    if (instr->CanBecomeDeoptimizationTarget() && !instr->IsGoto()) {
      // Instructions that can be deoptimization targets need to record kDeopt
      // PcDescriptor corresponding to their deopt id. GotoInstr records its
      // own so that it can control the placement.
      AddCurrentDescriptor(PcDescriptorsLayout::kDeopt, instr->deopt_id(),
                           instr->source());
    }
    AllocateRegistersLocally(instr);
  }
}

void FlowGraphCompiler::EmitSourceLine(Instruction* instr) {
  if (!instr->token_pos().IsReal()) {
    return;
  }
  const InstructionSource& source = instr->source();
  const intptr_t inlining_id = source.inlining_id < 0 ? 0 : source.inlining_id;
  const Function& function =
      *code_source_map_builder_->inline_id_to_function()[inlining_id];
  ASSERT(instr->env() == nullptr ||
         instr->env()->function().raw() == function.raw());
  const auto& script = Script::Handle(zone(), function.script());
  intptr_t line_nr;
  if (script.GetTokenLocation(source.token_pos, &line_nr)) {
    const String& line = String::Handle(zone(), script.GetLine(line_nr));
    assembler()->Comment("Line %" Pd " in '%s':\n           %s", line_nr,
                         function.ToFullyQualifiedCString(), line.ToCString());
  }
}

static bool IsPusher(Instruction* instr) {
  if (auto def = instr->AsDefinition()) {
    return def->HasTemp();
  }
  return false;
}

static bool IsPopper(Instruction* instr) {
  // TODO(ajcbik): even allow deopt targets by making environment aware?
  if (!instr->CanBecomeDeoptimizationTarget()) {
    return !instr->IsPushArgument() && instr->ArgumentCount() == 0 &&
           instr->InputCount() > 0;
  }
  return false;
}

bool FlowGraphCompiler::IsPeephole(Instruction* instr) const {
  if (FLAG_enable_peephole && !is_optimizing()) {
    return IsPusher(instr) && IsPopper(instr->next());
  }
  return false;
}

void FlowGraphCompiler::VisitBlocks() {
  CompactBlocks();
  if (compiler::Assembler::EmittingComments()) {
    // The loop_info fields were cleared, recompute.
    flow_graph().ComputeLoops();
  }

  // In precompiled mode, we require the function entry to come first (after the
  // graph entry), since the polymorphic check is performed in the function
  // entry (see Instructions::EntryPoint).
  if (FLAG_precompiled_mode) {
    ASSERT(block_order()[1] == flow_graph().graph_entry()->normal_entry());
  }

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  const auto inner_lr_state = ComputeInnerLRState(flow_graph());
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)

  for (intptr_t i = 0; i < block_order().length(); ++i) {
    // Compile the block entry.
    BlockEntryInstr* entry = block_order()[i];
    assembler()->Comment("B%" Pd "", entry->block_id());
    set_current_block(entry);

    if (WasCompacted(entry)) {
      continue;
    }

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    // At the start of every non-entry block we expect return address either
    // to be  spilled into the frame or to be in the LR register.
    if (entry->IsFunctionEntry() || entry->IsNativeEntry()) {
      assembler()->set_lr_state(compiler::LRState::OnEntry());
    } else {
      assembler()->set_lr_state(inner_lr_state);
    }
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)

#if defined(DEBUG)
    if (!is_optimizing()) {
      FrameStateClear();
    }
#endif

    if (compiler::Assembler::EmittingComments()) {
      for (LoopInfo* l = entry->loop_info(); l != nullptr; l = l->outer()) {
        assembler()->Comment("  Loop %" Pd "", l->id());
      }
    }

    BeginCodeSourceRange(entry->source());
    ASSERT(pending_deoptimization_env_ == NULL);
    pending_deoptimization_env_ = entry->env();
    set_current_instruction(entry);
    StatsBegin(entry);
    entry->EmitNativeCode(this);
    StatsEnd(entry);
    set_current_instruction(nullptr);
    pending_deoptimization_env_ = NULL;
    EndCodeSourceRange(entry->source());

    if (skip_body_compilation()) {
      ASSERT(entry == flow_graph().graph_entry()->normal_entry());
      break;
    }

    // Compile all successors until an exit, branch, or a block entry.
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      set_current_instruction(instr);
      StatsBegin(instr);

      if (FLAG_code_comments || FLAG_disassemble ||
          FLAG_disassemble_optimized) {
        if (FLAG_source_lines) {
          EmitSourceLine(instr);
        }
        EmitComment(instr);
      }
      if (instr->IsParallelMove()) {
        parallel_move_resolver_.EmitNativeCode(instr->AsParallelMove());
      } else {
        BeginCodeSourceRange(instr->source());
        EmitInstructionPrologue(instr);
        ASSERT(pending_deoptimization_env_ == NULL);
        pending_deoptimization_env_ = instr->env();
        DEBUG_ONLY(current_instruction_ = instr);
        instr->EmitNativeCode(this);
        DEBUG_ONLY(current_instruction_ = nullptr);
        pending_deoptimization_env_ = NULL;
        if (IsPeephole(instr)) {
          ASSERT(top_of_stack_ == nullptr);
          top_of_stack_ = instr->AsDefinition();
        } else {
          EmitInstructionEpilogue(instr);
        }
        EndCodeSourceRange(instr->source());
      }

#if defined(DEBUG)
      if (!is_optimizing()) {
        FrameStateUpdateWith(instr);
      }
#endif
      StatsEnd(instr);
      set_current_instruction(nullptr);

      if (auto indirect_goto = instr->AsIndirectGoto()) {
        indirect_gotos_.Add(indirect_goto);
      }
    }

#if defined(DEBUG)
    ASSERT(is_optimizing() || FrameStateIsSafeToCall());
#endif
  }

  set_current_block(NULL);
}

void FlowGraphCompiler::Bailout(const char* reason) {
  parsed_function_.Bailout("FlowGraphCompiler", reason);
}

intptr_t FlowGraphCompiler::StackSize() const {
  if (is_optimizing_) {
    return flow_graph_.graph_entry()->spill_slot_count();
  } else {
    return parsed_function_.num_stack_locals();
  }
}

intptr_t FlowGraphCompiler::ExtraStackSlotsOnOsrEntry() const {
  ASSERT(flow_graph().IsCompiledForOsr());
  const intptr_t stack_depth =
      flow_graph().graph_entry()->osr_entry()->stack_depth();
  const intptr_t num_stack_locals = flow_graph().num_stack_locals();
  return StackSize() - stack_depth - num_stack_locals;
}

compiler::Label* FlowGraphCompiler::GetJumpLabel(
    BlockEntryInstr* block_entry) const {
  const intptr_t block_index = block_entry->postorder_number();
  return block_info_[block_index]->jump_label();
}

bool FlowGraphCompiler::WasCompacted(BlockEntryInstr* block_entry) const {
  const intptr_t block_index = block_entry->postorder_number();
  return block_info_[block_index]->WasCompacted();
}

compiler::Label* FlowGraphCompiler::NextNonEmptyLabel() const {
  const intptr_t current_index = current_block()->postorder_number();
  return block_info_[current_index]->next_nonempty_label();
}

bool FlowGraphCompiler::CanFallThroughTo(BlockEntryInstr* block_entry) const {
  return NextNonEmptyLabel() == GetJumpLabel(block_entry);
}

BranchLabels FlowGraphCompiler::CreateBranchLabels(BranchInstr* branch) const {
  compiler::Label* true_label = GetJumpLabel(branch->true_successor());
  compiler::Label* false_label = GetJumpLabel(branch->false_successor());
  compiler::Label* fall_through = NextNonEmptyLabel();
  BranchLabels result = {true_label, false_label, fall_through};
  return result;
}

void FlowGraphCompiler::AddSlowPathCode(SlowPathCode* code) {
  slow_path_code_.Add(code);
}

void FlowGraphCompiler::GenerateDeferredCode() {
#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  const auto lr_state = ComputeInnerLRState(flow_graph());
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)

  for (intptr_t i = 0; i < slow_path_code_.length(); i++) {
    SlowPathCode* const slow_path = slow_path_code_[i];
    const CombinedCodeStatistics::EntryCounter stats_tag =
        CombinedCodeStatistics::SlowPathCounterFor(
            slow_path->instruction()->tag());
#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    assembler()->set_lr_state(lr_state);
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    set_current_instruction(slow_path->instruction());
    SpecialStatsBegin(stats_tag);
    BeginCodeSourceRange(slow_path->instruction()->source());
    DEBUG_ONLY(current_instruction_ = slow_path->instruction());
    slow_path->GenerateCode(this);
    DEBUG_ONLY(current_instruction_ = nullptr);
    EndCodeSourceRange(slow_path->instruction()->source());
    SpecialStatsEnd(stats_tag);
    set_current_instruction(nullptr);
  }
  // All code generated by deferred deopt info is treated as in the root
  // function.
  const InstructionSource deopt_source(TokenPosition::kDeferredDeoptInfo,
                                       /*inlining_id=*/0);
  for (intptr_t i = 0; i < deopt_infos_.length(); i++) {
    BeginCodeSourceRange(deopt_source);
#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    assembler()->set_lr_state(lr_state);
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    deopt_infos_[i]->GenerateCode(this, i);
    EndCodeSourceRange(deopt_source);
  }
}

void FlowGraphCompiler::AddExceptionHandler(intptr_t try_index,
                                            intptr_t outer_try_index,
                                            intptr_t pc_offset,
                                            bool is_generated,
                                            const Array& handler_types,
                                            bool needs_stacktrace) {
  exception_handlers_list_->AddHandler(try_index, outer_try_index, pc_offset,
                                       is_generated, handler_types,
                                       needs_stacktrace);
}

void FlowGraphCompiler::SetNeedsStackTrace(intptr_t try_index) {
  exception_handlers_list_->SetNeedsStackTrace(try_index);
}

void FlowGraphCompiler::AddDescriptor(PcDescriptorsLayout::Kind kind,
                                      intptr_t pc_offset,
                                      intptr_t deopt_id,
                                      const InstructionSource& source,
                                      intptr_t try_index,
                                      intptr_t yield_index) {
  code_source_map_builder_->NoteDescriptor(kind, pc_offset, source);
  // Don't emit deopt-descriptors in AOT mode.
  if (FLAG_precompiled_mode && (kind == PcDescriptorsLayout::kDeopt)) return;
  // Use the token position of the original call in the root function if source
  // has an inlining id.
  const auto& root_pos = code_source_map_builder_->RootPosition(source);
  pc_descriptors_list_->AddDescriptor(kind, pc_offset, deopt_id, root_pos,
                                      try_index, yield_index);
}

// Uses current pc position and try-index.
void FlowGraphCompiler::AddCurrentDescriptor(PcDescriptorsLayout::Kind kind,
                                             intptr_t deopt_id,
                                             const InstructionSource& source) {
  AddDescriptor(kind, assembler()->CodeSize(), deopt_id, source,
                CurrentTryIndex());
}

void FlowGraphCompiler::AddNullCheck(const InstructionSource& source,
                                     const String& name) {
#if defined(DART_PRECOMPILER)
  // If we are generating an AOT snapshot and have DWARF stack traces enabled,
  // the AOT runtime is unable to obtain the pool index at runtime. Therefore,
  // there is no reason to put the name into the pool in the first place.
  // TODO(dartbug.com/40605): Move this info to the pc descriptors.
  if (FLAG_precompiled_mode && FLAG_dwarf_stack_traces_mode) return;
#endif
  const intptr_t name_index =
      assembler()->object_pool_builder().FindObject(name);
  code_source_map_builder_->NoteNullCheck(assembler()->CodeSize(), source,
                                          name_index);
}

void FlowGraphCompiler::AddPcRelativeCallTarget(const Function& function,
                                                Code::EntryKind entry_kind) {
  ASSERT(function.IsZoneHandle());
  const auto entry_point = entry_kind == Code::EntryKind::kUnchecked
                               ? Code::kUncheckedEntry
                               : Code::kDefaultEntry;
  static_calls_target_table_.Add(new (zone()) StaticCallsStruct(
      Code::kPcRelativeCall, entry_point, assembler()->CodeSize(), &function,
      nullptr, nullptr));
}

void FlowGraphCompiler::AddPcRelativeCallStubTarget(const Code& stub_code) {
  ASSERT(stub_code.IsZoneHandle() || stub_code.IsReadOnlyHandle());
  ASSERT(!stub_code.IsNull());
  static_calls_target_table_.Add(new (zone()) StaticCallsStruct(
      Code::kPcRelativeCall, Code::kDefaultEntry, assembler()->CodeSize(),
      nullptr, &stub_code, nullptr));
}

void FlowGraphCompiler::AddPcRelativeTailCallStubTarget(const Code& stub_code) {
  ASSERT(stub_code.IsZoneHandle() || stub_code.IsReadOnlyHandle());
  ASSERT(!stub_code.IsNull());
  static_calls_target_table_.Add(new (zone()) StaticCallsStruct(
      Code::kPcRelativeTailCall, Code::kDefaultEntry, assembler()->CodeSize(),
      nullptr, &stub_code, nullptr));
}

void FlowGraphCompiler::AddPcRelativeTTSCallTypeTarget(
    const AbstractType& dst_type) {
  ASSERT(dst_type.IsZoneHandle() || dst_type.IsReadOnlyHandle());
  ASSERT(!dst_type.IsNull());
  static_calls_target_table_.Add(new (zone()) StaticCallsStruct(
      Code::kPcRelativeTTSCall, Code::kDefaultEntry, assembler()->CodeSize(),
      nullptr, nullptr, &dst_type));
}

void FlowGraphCompiler::AddStaticCallTarget(const Function& func,
                                            Code::EntryKind entry_kind) {
  ASSERT(func.IsZoneHandle());
  const auto entry_point = entry_kind == Code::EntryKind::kUnchecked
                               ? Code::kUncheckedEntry
                               : Code::kDefaultEntry;
  static_calls_target_table_.Add(new (zone()) StaticCallsStruct(
      Code::kCallViaCode, entry_point, assembler()->CodeSize(), &func, nullptr,
      nullptr));
}

void FlowGraphCompiler::AddStubCallTarget(const Code& code) {
  ASSERT(code.IsZoneHandle() || code.IsReadOnlyHandle());
  static_calls_target_table_.Add(new (zone()) StaticCallsStruct(
      Code::kCallViaCode, Code::kDefaultEntry, assembler()->CodeSize(), nullptr,
      &code, nullptr));
}

void FlowGraphCompiler::AddDispatchTableCallTarget(
    const compiler::TableSelector* selector) {
  dispatch_table_call_targets_.Add(selector);
}

CompilerDeoptInfo* FlowGraphCompiler::AddDeoptIndexAtCall(intptr_t deopt_id) {
  ASSERT(is_optimizing());
  ASSERT(!intrinsic_mode());
  ASSERT(!FLAG_precompiled_mode);
  CompilerDeoptInfo* info =
      new (zone()) CompilerDeoptInfo(deopt_id, ICData::kDeoptAtCall,
                                     0,  // No flags.
                                     pending_deoptimization_env_);
  info->set_pc_offset(assembler()->CodeSize());
  deopt_infos_.Add(info);
  return info;
}

CompilerDeoptInfo* FlowGraphCompiler::AddSlowPathDeoptInfo(intptr_t deopt_id,
                                                           Environment* env) {
  ASSERT(deopt_id != DeoptId::kNone);
  deopt_id = DeoptId::ToDeoptAfter(deopt_id);
  CompilerDeoptInfo* info =
      new (zone()) CompilerDeoptInfo(deopt_id, ICData::kDeoptUnknown, 0, env);
  info->set_pc_offset(assembler()->CodeSize());
  deopt_infos_.Add(info);
  return info;
}

// This function must be in sync with FlowGraphCompiler::SaveLiveRegisters
// and FlowGraphCompiler::SlowPathEnvironmentFor.
// See StackFrame::VisitObjectPointers for the details of how stack map is
// interpreted.
void FlowGraphCompiler::RecordSafepoint(LocationSummary* locs,
                                        intptr_t slow_path_argument_count) {
  if (is_optimizing() || locs->live_registers()->HasUntaggedValues()) {
    const intptr_t spill_area_size =
        is_optimizing() ? flow_graph_.graph_entry()->spill_slot_count() : 0;

    RegisterSet* registers = locs->live_registers();
    ASSERT(registers != NULL);
    const intptr_t kFpuRegisterSpillFactor =
        kFpuRegisterSize / compiler::target::kWordSize;
    intptr_t saved_registers_size = 0;
    const bool using_shared_stub = locs->call_on_shared_slow_path();
    if (using_shared_stub) {
      saved_registers_size =
          Utils::CountOneBitsWord(kDartAvailableCpuRegs) +
          (registers->FpuRegisterCount() > 0
               ? kFpuRegisterSpillFactor * kNumberOfFpuRegisters
               : 0) +
          1 /*saved PC*/;
    } else {
      saved_registers_size =
          registers->CpuRegisterCount() +
          (registers->FpuRegisterCount() * kFpuRegisterSpillFactor);
    }

    BitmapBuilder* bitmap = locs->stack_bitmap();

    // An instruction may have two safepoints in deferred code. The
    // call to RecordSafepoint has the side-effect of appending the live
    // registers to the bitmap. This is why the second call to RecordSafepoint
    // with the same instruction (and same location summary) sees a bitmap that
    // is larger that StackSize(). It will never be larger than StackSize() +
    // unboxed_arg_bits_count + live_registers_size.
    // The first safepoint will grow the bitmap to be the size of
    // spill_area_size but the second safepoint will truncate the bitmap and
    // append the bits for arguments and live registers to it again.
    const intptr_t bitmap_previous_length = bitmap->Length();
    bitmap->SetLength(spill_area_size);

    intptr_t unboxed_arg_bits_count = 0;

    auto instr = current_instruction();
    const intptr_t args_count = instr->ArgumentCount();
    bool pushed_unboxed = false;

    for (intptr_t i = 0; i < args_count; i++) {
      auto push_arg =
          instr->ArgumentValueAt(i)->instruction()->AsPushArgument();
      switch (push_arg->representation()) {
        case kUnboxedInt64:
          bitmap->SetRange(
              bitmap->Length(),
              bitmap->Length() + compiler::target::kIntSpillFactor - 1, false);
          unboxed_arg_bits_count += compiler::target::kIntSpillFactor;
          pushed_unboxed = true;
          break;
        case kUnboxedDouble:
          bitmap->SetRange(
              bitmap->Length(),
              bitmap->Length() + compiler::target::kDoubleSpillFactor - 1,
              false);
          unboxed_arg_bits_count += compiler::target::kDoubleSpillFactor;
          pushed_unboxed = true;
          break;
        case kTagged:
          if (!pushed_unboxed) {
            // GC considers everything to be tagged between prefix of stack
            // frame (spill area size) and postfix of stack frame (e.g. slow
            // path arguments, shared pushed registers).
            // From the first unboxed argument on we will include bits in the
            // postfix.
            continue;
          }
          bitmap->Set(bitmap->Length(), true);
          unboxed_arg_bits_count++;
          break;
        default:
          UNREACHABLE();
          break;
      }
    }
    ASSERT(bitmap_previous_length <=
           (spill_area_size + unboxed_arg_bits_count + saved_registers_size));

    ASSERT(slow_path_argument_count == 0 || !using_shared_stub);

    // Mark the bits in the stack map in the same order we push registers in
    // slow path code (see FlowGraphCompiler::SaveLiveRegisters).
    //
    // Slow path code can have registers at the safepoint.
    if (!locs->always_calls() && !using_shared_stub) {
      RegisterSet* regs = locs->live_registers();
      if (regs->FpuRegisterCount() > 0) {
        // Denote FPU registers with 0 bits in the stackmap.  Based on the
        // assumption that there are normally few live FPU registers, this
        // encoding is simpler and roughly as compact as storing a separate
        // count of FPU registers.
        //
        // FPU registers have the highest register number at the highest
        // address (i.e., first in the stackmap).
        for (intptr_t i = kNumberOfFpuRegisters - 1; i >= 0; --i) {
          FpuRegister reg = static_cast<FpuRegister>(i);
          if (regs->ContainsFpuRegister(reg)) {
            for (intptr_t j = 0; j < kFpuRegisterSpillFactor; ++j) {
              bitmap->Set(bitmap->Length(), false);
            }
          }
        }
      }

      // General purpose registers have the highest register number at the
      // highest address (i.e., first in the stackmap).
      for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
        Register reg = static_cast<Register>(i);
        if (locs->live_registers()->ContainsRegister(reg)) {
          bitmap->Set(bitmap->Length(), locs->live_registers()->IsTagged(reg));
        }
      }
    }

    if (using_shared_stub) {
      // To simplify the code in the shared stub, we create an untagged hole
      // in the stack frame where the shared stub can leave the return address
      // before saving registers.
      bitmap->Set(bitmap->Length(), false);
      if (registers->FpuRegisterCount() > 0) {
        bitmap->SetRange(bitmap->Length(),
                         bitmap->Length() +
                             kNumberOfFpuRegisters * kFpuRegisterSpillFactor -
                             1,
                         false);
      }
      for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
        if ((kReservedCpuRegisters & (1 << i)) != 0) continue;
        const Register reg = static_cast<Register>(i);
        bitmap->Set(bitmap->Length(),
                    locs->live_registers()->ContainsRegister(reg) &&
                        locs->live_registers()->IsTagged(reg));
      }
    }

    // Arguments pushed after live registers in the slow path are tagged.
    for (intptr_t i = 0; i < slow_path_argument_count; ++i) {
      bitmap->Set(bitmap->Length(), true);
    }

    compressed_stackmaps_builder_->AddEntry(assembler()->CodeSize(), bitmap,
                                            spill_area_size);
  }
}

// This function must be kept in sync with:
//
//     FlowGraphCompiler::RecordSafepoint
//     FlowGraphCompiler::SaveLiveRegisters
//     MaterializeObjectInstr::RemapRegisters
//
Environment* FlowGraphCompiler::SlowPathEnvironmentFor(
    Environment* env,
    LocationSummary* locs,
    intptr_t num_slow_path_args) {
  const bool using_shared_stub = locs->call_on_shared_slow_path();
  const bool shared_stub_save_fpu_registers =
      using_shared_stub && locs->live_registers()->FpuRegisterCount() > 0;
  // TODO(sjindel): Modify logic below to account for slow-path args with shared
  // stubs.
  ASSERT(!using_shared_stub || num_slow_path_args == 0);
  if (env == nullptr) {
    // In AOT, environments can be removed by EliminateEnvironments pass
    // (if not in a try block).
    ASSERT(!is_optimizing() || FLAG_precompiled_mode);
    return nullptr;
  }

  Environment* slow_path_env = env->DeepCopy(zone());
  // 1. Iterate the registers in the order they will be spilled to compute
  //    the slots they will be spilled to.
  intptr_t next_slot = StackSize() + slow_path_env->CountArgsPushed();
  if (using_shared_stub) {
    // The PC from the call to the shared stub is pushed here.
    next_slot++;
  }
  RegisterSet* regs = locs->live_registers();
  intptr_t fpu_reg_slots[kNumberOfFpuRegisters];
  intptr_t cpu_reg_slots[kNumberOfCpuRegisters];
  const intptr_t kFpuRegisterSpillFactor =
      kFpuRegisterSize / compiler::target::kWordSize;
  // FPU registers are spilled first from highest to lowest register number.
  for (intptr_t i = kNumberOfFpuRegisters - 1; i >= 0; --i) {
    FpuRegister reg = static_cast<FpuRegister>(i);
    if (regs->ContainsFpuRegister(reg)) {
      // We use the lowest address (thus highest index) to identify a
      // multi-word spill slot.
      next_slot += kFpuRegisterSpillFactor;
      fpu_reg_slots[i] = (next_slot - 1);
    } else {
      if (using_shared_stub && shared_stub_save_fpu_registers) {
        next_slot += kFpuRegisterSpillFactor;
      }
      fpu_reg_slots[i] = -1;
    }
  }
  // General purpose registers are spilled from highest to lowest register
  // number.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
    if ((kReservedCpuRegisters & (1 << i)) != 0) continue;
    Register reg = static_cast<Register>(i);
    if (regs->ContainsRegister(reg)) {
      cpu_reg_slots[i] = next_slot++;
    } else {
      if (using_shared_stub) next_slot++;
      cpu_reg_slots[i] = -1;
    }
  }

  // 2. Iterate the environment and replace register locations with the
  //    corresponding spill slot locations.
  for (Environment::DeepIterator it(slow_path_env); !it.Done(); it.Advance()) {
    Location loc = it.CurrentLocation();
    Value* value = it.CurrentValue();
    it.SetCurrentLocation(LocationRemapForSlowPath(
        loc, value->definition(), cpu_reg_slots, fpu_reg_slots));
  }

  return slow_path_env;
}

compiler::Label* FlowGraphCompiler::AddDeoptStub(intptr_t deopt_id,
                                                 ICData::DeoptReasonId reason,
                                                 uint32_t flags) {
  if (intrinsic_mode()) {
    return intrinsic_slow_path_label_;
  }

  // No deoptimization allowed when 'FLAG_precompiled_mode' is set.
  if (FLAG_precompiled_mode) {
    if (FLAG_trace_compiler) {
      THR_Print(
          "Retrying compilation %s, suppressing inlining of deopt_id:%" Pd "\n",
          parsed_function_.function().ToFullyQualifiedCString(), deopt_id);
    }
    ASSERT(speculative_policy_->AllowsSpeculativeInlining());
    ASSERT(deopt_id != 0);  // longjmp must return non-zero value.
    Thread::Current()->long_jump_base()->Jump(
        deopt_id, Object::speculative_inlining_error());
  }

  ASSERT(is_optimizing_);
  CompilerDeoptInfoWithStub* stub = new (zone()) CompilerDeoptInfoWithStub(
      deopt_id, reason, flags, pending_deoptimization_env_);
  deopt_infos_.Add(stub);
  return stub->entry_label();
}

void FlowGraphCompiler::FinalizeExceptionHandlers(const Code& code) {
  ASSERT(exception_handlers_list_ != NULL);
  const ExceptionHandlers& handlers = ExceptionHandlers::Handle(
      exception_handlers_list_->FinalizeExceptionHandlers(code.PayloadStart()));
  code.set_exception_handlers(handlers);
}

void FlowGraphCompiler::FinalizePcDescriptors(const Code& code) {
  ASSERT(pc_descriptors_list_ != NULL);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      pc_descriptors_list_->FinalizePcDescriptors(code.PayloadStart()));
  if (!is_optimizing_) descriptors.Verify(parsed_function_.function());
  code.set_pc_descriptors(descriptors);
}

ArrayPtr FlowGraphCompiler::CreateDeoptInfo(compiler::Assembler* assembler) {
  // No deopt information if we precompile (no deoptimization allowed).
  if (FLAG_precompiled_mode) {
    return Array::empty_array().raw();
  }
  // For functions with optional arguments, all incoming arguments are copied
  // to spill slots. The deoptimization environment does not track them.
  const Function& function = parsed_function().function();
  const intptr_t incoming_arg_count =
      function.HasOptionalParameters() ? 0 : function.num_fixed_parameters();
  DeoptInfoBuilder builder(zone(), incoming_arg_count, assembler);

  intptr_t deopt_info_table_size = DeoptTable::SizeFor(deopt_infos_.length());
  if (deopt_info_table_size == 0) {
    return Object::empty_array().raw();
  } else {
    const Array& array =
        Array::Handle(Array::New(deopt_info_table_size, Heap::kOld));
    Smi& offset = Smi::Handle();
    TypedData& info = TypedData::Handle();
    Smi& reason_and_flags = Smi::Handle();
    for (intptr_t i = 0; i < deopt_infos_.length(); i++) {
      offset = Smi::New(deopt_infos_[i]->pc_offset());
      info = deopt_infos_[i]->CreateDeoptInfo(this, &builder, array);
      reason_and_flags = DeoptTable::EncodeReasonAndFlags(
          deopt_infos_[i]->reason(), deopt_infos_[i]->flags());
      DeoptTable::SetEntry(array, i, offset, info, reason_and_flags);
    }
    return array.raw();
  }
}

void FlowGraphCompiler::FinalizeStackMaps(const Code& code) {
  ASSERT(compressed_stackmaps_builder_ != NULL);
  // Finalize the compressed stack maps and add it to the code object.
  const auto& maps =
      CompressedStackMaps::Handle(compressed_stackmaps_builder_->Finalize());
  code.set_compressed_stackmaps(maps);
}

void FlowGraphCompiler::FinalizeVarDescriptors(const Code& code) {
#if defined(PRODUCT)
// No debugger: no var descriptors.
#else
  if (code.is_optimized()) {
    // Optimized code does not need variable descriptors. They are
    // only stored in the unoptimized version.
    code.set_var_descriptors(Object::empty_var_descriptors());
    return;
  }
  LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle();
  if (flow_graph().IsIrregexpFunction()) {
    // Eager local var descriptors computation for Irregexp function as it is
    // complicated to factor out.
    // TODO(srdjan): Consider canonicalizing and reusing the local var
    // descriptor for IrregexpFunction.
    ASSERT(parsed_function().scope() == nullptr);
    var_descs = LocalVarDescriptors::New(1);
    LocalVarDescriptorsLayout::VarInfo info;
    info.set_kind(LocalVarDescriptorsLayout::kSavedCurrentContext);
    info.scope_id = 0;
    info.begin_pos = TokenPosition::kMinSource;
    info.end_pos = TokenPosition::kMinSource;
    info.set_index(compiler::target::frame_layout.FrameSlotForVariable(
        parsed_function().current_context_var()));
    var_descs.SetVar(0, Symbols::CurrentContextVar(), &info);
  }
  code.set_var_descriptors(var_descs);
#endif
}

void FlowGraphCompiler::FinalizeCatchEntryMovesMap(const Code& code) {
#if defined(DART_PRECOMPILER)
  if (FLAG_precompiled_mode) {
    TypedData& maps = TypedData::Handle(
        catch_entry_moves_maps_builder_->FinalizeCatchEntryMovesMap());
    code.set_catch_entry_moves_maps(maps);
    return;
  }
#endif
  code.set_num_variables(flow_graph().variable_count());
}

void FlowGraphCompiler::FinalizeStaticCallTargetsTable(const Code& code) {
  ASSERT(code.static_calls_target_table() == Array::null());
  const auto& calls = static_calls_target_table_;
  const intptr_t array_length = calls.length() * Code::kSCallTableEntryLength;
  const auto& targets =
      Array::Handle(zone(), Array::New(array_length, Heap::kOld));

  StaticCallsTable entries(targets);
  auto& kind_type_and_offset = Smi::Handle(zone());
  for (intptr_t i = 0; i < calls.length(); i++) {
    auto entry = calls[i];
    kind_type_and_offset =
        Smi::New(Code::KindField::encode(entry->call_kind) |
                 Code::EntryPointField::encode(entry->entry_point) |
                 Code::OffsetField::encode(entry->offset));
    auto view = entries[i];
    view.Set<Code::kSCallTableKindAndOffset>(kind_type_and_offset);
    const Object* target = nullptr;
    if (entry->function != nullptr) {
      target = entry->function;
      view.Set<Code::kSCallTableFunctionTarget>(*entry->function);
    }
    if (entry->code != nullptr) {
      ASSERT(target == nullptr);
      target = entry->code;
      view.Set<Code::kSCallTableCodeOrTypeTarget>(*entry->code);
    }
    if (entry->dst_type != nullptr) {
      ASSERT(target == nullptr);
      view.Set<Code::kSCallTableCodeOrTypeTarget>(*entry->dst_type);
    }
  }
  code.set_static_calls_target_table(targets);
}

void FlowGraphCompiler::FinalizeCodeSourceMap(const Code& code) {
  const Array& inlined_id_array =
      Array::Handle(zone(), code_source_map_builder_->InliningIdToFunction());
  code.set_inlined_id_to_function(inlined_id_array);

  const CodeSourceMap& map =
      CodeSourceMap::Handle(code_source_map_builder_->Finalize());
  code.set_code_source_map(map);

#if defined(DEBUG)
  // Force simulation through the last pc offset. This checks we can decode
  // the whole CodeSourceMap without hitting an unknown opcode, stack underflow,
  // etc.
  GrowableArray<const Function*> fs;
  GrowableArray<TokenPosition> tokens;
  code.GetInlinedFunctionsAtInstruction(code.Size() - 1, &fs, &tokens);
#endif
}

// Returns 'true' if regular code generation should be skipped.
bool FlowGraphCompiler::TryIntrinsify() {
  if (TryIntrinsifyHelper()) {
    fully_intrinsified_ = true;
    return true;
  }
  return false;
}

bool FlowGraphCompiler::TryIntrinsifyHelper() {
  ASSERT(!flow_graph().IsCompiledForOsr());

  compiler::Label exit;
  set_intrinsic_slow_path_label(&exit);

  if (FLAG_intrinsify) {
    const auto& function = parsed_function().function();
    if (function.IsMethodExtractor()) {
#if !defined(TARGET_ARCH_IA32)
      auto& extracted_method =
          Function::ZoneHandle(function.extracted_method_closure());
      auto& klass = Class::Handle(extracted_method.Owner());
      const intptr_t type_arguments_field_offset =
          compiler::target::Class::HasTypeArgumentsField(klass)
              ? (compiler::target::Class::TypeArgumentsFieldOffset(klass) -
                 kHeapObjectTag)
              : 0;

      SpecialStatsBegin(CombinedCodeStatistics::kTagIntrinsics);
      GenerateMethodExtractorIntrinsic(extracted_method,
                                       type_arguments_field_offset);
      SpecialStatsEnd(CombinedCodeStatistics::kTagIntrinsics);
      return true;
#endif  // !defined(TARGET_ARCH_IA32)
    }
  }

  EnterIntrinsicMode();

  SpecialStatsBegin(CombinedCodeStatistics::kTagIntrinsics);
  bool complete = compiler::Intrinsifier::Intrinsify(parsed_function(), this);
  SpecialStatsEnd(CombinedCodeStatistics::kTagIntrinsics);

  ExitIntrinsicMode();

  // "Deoptimization" from intrinsic continues here. All deoptimization
  // branches from intrinsic code redirect to here where the slow-path
  // (normal function body) starts.
  // This means that there must not be any side-effects in intrinsic code
  // before any deoptimization point.
  assembler()->Bind(intrinsic_slow_path_label());
  set_intrinsic_slow_path_label(nullptr);
  return complete;
}

void FlowGraphCompiler::GenerateStubCall(const InstructionSource& source,
                                         const Code& stub,
                                         PcDescriptorsLayout::Kind kind,
                                         LocationSummary* locs,
                                         intptr_t deopt_id,
                                         Environment* env) {
  EmitCallToStub(stub);
  EmitCallsiteMetadata(source, deopt_id, kind, locs, env);
}

static const Code& StubEntryFor(const ICData& ic_data, bool optimized) {
  switch (ic_data.NumArgsTested()) {
    case 1:
#if defined(TARGET_ARCH_X64)
      if (ic_data.is_tracking_exactness()) {
        if (optimized) {
          return StubCode::OneArgOptimizedCheckInlineCacheWithExactnessCheck();
        } else {
          return StubCode::OneArgCheckInlineCacheWithExactnessCheck();
        }
      }
#else
      // TODO(dartbug.com/34170) Port exactness tracking to other platforms.
      ASSERT(!ic_data.is_tracking_exactness());
#endif
      return optimized ? StubCode::OneArgOptimizedCheckInlineCache()
                       : StubCode::OneArgCheckInlineCache();
    case 2:
      ASSERT(!ic_data.is_tracking_exactness());
      return optimized ? StubCode::TwoArgsOptimizedCheckInlineCache()
                       : StubCode::TwoArgsCheckInlineCache();
    default:
      ic_data.Print();
      UNIMPLEMENTED();
      return Code::Handle();
  }
}

void FlowGraphCompiler::GenerateInstanceCall(intptr_t deopt_id,
                                             const InstructionSource& source,
                                             LocationSummary* locs,
                                             const ICData& ic_data_in,
                                             Code::EntryKind entry_kind,
                                             bool receiver_can_be_smi) {
  ICData& ic_data = ICData::ZoneHandle(ic_data_in.Original());
  if (FLAG_precompiled_mode) {
    ic_data = ic_data.AsUnaryClassChecks();
    EmitInstanceCallAOT(ic_data, deopt_id, source, locs, entry_kind,
                        receiver_can_be_smi);
    return;
  }
  ASSERT(!ic_data.IsNull());
  if (is_optimizing() && (ic_data_in.NumberOfUsedChecks() == 0)) {
    // Emit IC call that will count and thus may need reoptimization at
    // function entry.
    ASSERT(may_reoptimize() || flow_graph().IsCompiledForOsr());
    EmitOptimizedInstanceCall(StubEntryFor(ic_data, /*optimized=*/true),
                              ic_data, deopt_id, source, locs, entry_kind);
    return;
  }

  if (is_optimizing()) {
    EmitMegamorphicInstanceCall(ic_data_in, deopt_id, source, locs,
                                kInvalidTryIndex);
    return;
  }

  EmitInstanceCallJIT(StubEntryFor(ic_data, /*optimized=*/false), ic_data,
                      deopt_id, source, locs, entry_kind);
}

void FlowGraphCompiler::GenerateStaticCall(intptr_t deopt_id,
                                           const InstructionSource& source,
                                           const Function& function,
                                           ArgumentsInfo args_info,
                                           LocationSummary* locs,
                                           const ICData& ic_data_in,
                                           ICData::RebindRule rebind_rule,
                                           Code::EntryKind entry_kind) {
  const ICData& ic_data = ICData::ZoneHandle(ic_data_in.Original());
  const Array& arguments_descriptor = Array::ZoneHandle(
      zone(), ic_data.IsNull() ? args_info.ToArgumentsDescriptor()
                               : ic_data.arguments_descriptor());
  ASSERT(ArgumentsDescriptor(arguments_descriptor).TypeArgsLen() ==
         args_info.type_args_len);
  ASSERT(ArgumentsDescriptor(arguments_descriptor).Count() ==
         args_info.count_without_type_args);
  ASSERT(ArgumentsDescriptor(arguments_descriptor).Size() ==
         args_info.size_without_type_args);
  // Force-optimized functions lack the deopt info which allows patching of
  // optimized static calls.
  if (is_optimizing() && (!ForcedOptimization() || FLAG_precompiled_mode)) {
    EmitOptimizedStaticCall(function, arguments_descriptor,
                            args_info.size_with_type_args, deopt_id, source,
                            locs, entry_kind);
  } else {
    ICData& call_ic_data = ICData::ZoneHandle(zone(), ic_data.raw());
    if (call_ic_data.IsNull()) {
      const intptr_t kNumArgsChecked = 0;
      call_ic_data =
          GetOrAddStaticCallICData(deopt_id, function, arguments_descriptor,
                                   kNumArgsChecked, rebind_rule)
              ->raw();
      call_ic_data = call_ic_data.Original();
    }
    AddCurrentDescriptor(PcDescriptorsLayout::kRewind, deopt_id, source);
    EmitUnoptimizedStaticCall(args_info.size_with_type_args, deopt_id, source,
                              locs, call_ic_data, entry_kind);
  }
}

void FlowGraphCompiler::GenerateNumberTypeCheck(
    Register class_id_reg,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  assembler()->Comment("NumberTypeCheck");
  GrowableArray<intptr_t> args;
  if (type.IsNumberType()) {
    args.Add(kDoubleCid);
    args.Add(kMintCid);
  } else if (type.IsIntType()) {
    args.Add(kMintCid);
  } else if (type.IsDoubleType()) {
    args.Add(kDoubleCid);
  }
  CheckClassIds(class_id_reg, args, is_instance_lbl, is_not_instance_lbl);
}

void FlowGraphCompiler::GenerateStringTypeCheck(
    Register class_id_reg,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  assembler()->Comment("StringTypeCheck");
  GrowableArray<intptr_t> args;
  args.Add(kOneByteStringCid);
  args.Add(kTwoByteStringCid);
  args.Add(kExternalOneByteStringCid);
  args.Add(kExternalTwoByteStringCid);
  CheckClassIds(class_id_reg, args, is_instance_lbl, is_not_instance_lbl);
}

void FlowGraphCompiler::GenerateListTypeCheck(
    Register class_id_reg,
    compiler::Label* is_instance_lbl) {
  assembler()->Comment("ListTypeCheck");
  compiler::Label unknown;
  GrowableArray<intptr_t> args;
  args.Add(kArrayCid);
  args.Add(kGrowableObjectArrayCid);
  args.Add(kImmutableArrayCid);
  CheckClassIds(class_id_reg, args, is_instance_lbl, &unknown);
  assembler()->Bind(&unknown);
}

void FlowGraphCompiler::EmitComment(Instruction* instr) {
  if (!FLAG_support_il_printer || !FLAG_support_disassembler) {
    return;
  }
#ifndef PRODUCT
  char buffer[256];
  BufferFormatter f(buffer, sizeof(buffer));
  instr->PrintTo(&f);
  assembler()->Comment("%s", buffer);
#endif
}

bool FlowGraphCompiler::NeedsEdgeCounter(BlockEntryInstr* block) {
  // Only emit an edge counter if there is not goto at the end of the block,
  // except for the entry block.
  return FLAG_reorder_basic_blocks &&
         (!block->last_instruction()->IsGoto() || block->IsFunctionEntry());
}

// Allocate a register that is not explictly blocked.
static Register AllocateFreeRegister(bool* blocked_registers) {
  for (intptr_t regno = 0; regno < kNumberOfCpuRegisters; regno++) {
    if (!blocked_registers[regno]) {
      blocked_registers[regno] = true;
      return static_cast<Register>(regno);
    }
  }
  UNREACHABLE();
  return kNoRegister;
}

void FlowGraphCompiler::AllocateRegistersLocally(Instruction* instr) {
  ASSERT(!is_optimizing());
  instr->InitializeLocationSummary(zone(), false);  // Not optimizing.

  LocationSummary* locs = instr->locs();

  bool blocked_registers[kNumberOfCpuRegisters];

  // Connect input with peephole output for some special cases. All other
  // cases are handled by simply allocating registers and generating code.
  if (top_of_stack_ != nullptr) {
    const intptr_t p = locs->input_count() - 1;
    Location peephole = top_of_stack_->locs()->out(0);
    if (locs->in(p).IsUnallocated() || locs->in(p).IsConstant()) {
      // If input is unallocated, match with an output register, if set. Also,
      // if input is a direct constant, but the peephole output is a register,
      // use that register to avoid wasting the already generated code.
      if (peephole.IsRegister()) {
        locs->set_in(p, Location::RegisterLocation(peephole.reg()));
      }
    }
  }

  // Block all registers globally reserved by the assembler, etc and mark
  // the rest as free.
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    blocked_registers[i] = (kDartAvailableCpuRegs & (1 << i)) == 0;
  }

  // Mark all fixed input, temp and output registers as used.
  for (intptr_t i = 0; i < locs->input_count(); i++) {
    Location loc = locs->in(i);
    if (loc.IsRegister()) {
      // Check that a register is not specified twice in the summary.
      ASSERT(!blocked_registers[loc.reg()]);
      blocked_registers[loc.reg()] = true;
    }
  }

  for (intptr_t i = 0; i < locs->temp_count(); i++) {
    Location loc = locs->temp(i);
    if (loc.IsRegister()) {
      // Check that a register is not specified twice in the summary.
      ASSERT(!blocked_registers[loc.reg()]);
      blocked_registers[loc.reg()] = true;
    }
  }

  if (locs->out(0).IsRegister()) {
    // Fixed output registers are allowed to overlap with
    // temps and inputs.
    blocked_registers[locs->out(0).reg()] = true;
  }

  // Allocate all unallocated input locations.
  const bool should_pop = !instr->IsPushArgument();
  for (intptr_t i = locs->input_count() - 1; i >= 0; i--) {
    Location loc = locs->in(i);
    Register reg = kNoRegister;
    if (loc.IsRegister()) {
      reg = loc.reg();
    } else if (loc.IsUnallocated()) {
      ASSERT((loc.policy() == Location::kRequiresRegister) ||
             (loc.policy() == Location::kWritableRegister) ||
             (loc.policy() == Location::kPrefersRegister) ||
             (loc.policy() == Location::kAny));
      reg = AllocateFreeRegister(blocked_registers);
      locs->set_in(i, Location::RegisterLocation(reg));
    }
    ASSERT(reg != kNoRegister || loc.IsConstant());

    // Inputs are consumed from the simulated frame (or a peephole push/pop).
    // In case of a call argument we leave it until the call instruction.
    if (should_pop) {
      if (top_of_stack_ != nullptr) {
        if (!loc.IsConstant()) {
          // Moves top of stack location of the peephole into the required
          // input. None of the required moves needs a temp register allocator.
          EmitMove(locs->in(i), top_of_stack_->locs()->out(0), nullptr);
        }
        top_of_stack_ = nullptr;  // consumed!
      } else if (loc.IsConstant()) {
        assembler()->Drop(1);
      } else {
        assembler()->PopRegister(reg);
      }
    }
  }

  // Allocate all unallocated temp locations.
  for (intptr_t i = 0; i < locs->temp_count(); i++) {
    Location loc = locs->temp(i);
    if (loc.IsUnallocated()) {
      ASSERT(loc.policy() == Location::kRequiresRegister);
      loc = Location::RegisterLocation(AllocateFreeRegister(blocked_registers));
      locs->set_temp(i, loc);
    }
  }

  Location result_location = locs->out(0);
  if (result_location.IsUnallocated()) {
    switch (result_location.policy()) {
      case Location::kAny:
      case Location::kPrefersRegister:
      case Location::kRequiresRegister:
      case Location::kWritableRegister:
        result_location =
            Location::RegisterLocation(AllocateFreeRegister(blocked_registers));
        break;
      case Location::kSameAsFirstInput:
        result_location = locs->in(0);
        break;
      case Location::kRequiresFpuRegister:
      case Location::kRequiresStackSlot:
        UNREACHABLE();
        break;
    }
    locs->set_out(0, result_location);
  }
}

static uword RegMaskBit(Register reg) {
  return ((reg) != kNoRegister) ? (1 << (reg)) : 0;
}

ParallelMoveResolver::ParallelMoveResolver(FlowGraphCompiler* compiler)
    : compiler_(compiler), moves_(32) {}

void ParallelMoveResolver::EmitNativeCode(ParallelMoveInstr* parallel_move) {
  ASSERT(moves_.is_empty());

  // Build up a worklist of moves.
  BuildInitialMoveList(parallel_move);

  const InstructionSource& move_source = InstructionSource(
      TokenPosition::kParallelMove, parallel_move->inlining_id());
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& move = *moves_[i];
    // Skip constants to perform them last.  They don't block other moves
    // and skipping such moves with register destinations keeps those
    // registers free for the whole algorithm.
    if (!move.IsEliminated() && !move.src().IsConstant()) {
      PerformMove(move_source, i);
    }
  }

  // Perform the moves with constant sources.
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& move = *moves_[i];
    if (!move.IsEliminated()) {
      ASSERT(move.src().IsConstant());
      compiler_->BeginCodeSourceRange(move_source);
      EmitMove(i);
      compiler_->EndCodeSourceRange(move_source);
    }
  }

  moves_.Clear();
}

void ParallelMoveResolver::BuildInitialMoveList(
    ParallelMoveInstr* parallel_move) {
  // Perform a linear sweep of the moves to add them to the initial list of
  // moves to perform, ignoring any move that is redundant (the source is
  // the same as the destination, the destination is ignored and
  // unallocated, or the move was already eliminated).
  for (int i = 0; i < parallel_move->NumMoves(); i++) {
    MoveOperands* move = parallel_move->MoveOperandsAt(i);
    if (!move->IsRedundant()) moves_.Add(move);
  }
}

void ParallelMoveResolver::PerformMove(const InstructionSource& source,
                                       int index) {
  // Each call to this function performs a move and deletes it from the move
  // graph.  We first recursively perform any move blocking this one.  We
  // mark a move as "pending" on entry to PerformMove in order to detect
  // cycles in the move graph.  We use operand swaps to resolve cycles,
  // which means that a call to PerformMove could change any source operand
  // in the move graph.

  ASSERT(!moves_[index]->IsPending());
  ASSERT(!moves_[index]->IsRedundant());

  // Clear this move's destination to indicate a pending move.  The actual
  // destination is saved in a stack-allocated local.  Recursion may allow
  // multiple moves to be pending.
  ASSERT(!moves_[index]->src().IsInvalid());
  Location destination = moves_[index]->MarkPending();

  // Perform a depth-first traversal of the move graph to resolve
  // dependencies.  Any unperformed, unpending move with a source the same
  // as this one's destination blocks this one so recursively perform all
  // such moves.
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& other_move = *moves_[i];
    if (other_move.Blocks(destination) && !other_move.IsPending()) {
      // Though PerformMove can change any source operand in the move graph,
      // this call cannot create a blocking move via a swap (this loop does
      // not miss any).  Assume there is a non-blocking move with source A
      // and this move is blocked on source B and there is a swap of A and
      // B.  Then A and B must be involved in the same cycle (or they would
      // not be swapped).  Since this move's destination is B and there is
      // only a single incoming edge to an operand, this move must also be
      // involved in the same cycle.  In that case, the blocking move will
      // be created but will be "pending" when we return from PerformMove.
      PerformMove(source, i);
    }
  }

  // We are about to resolve this move and don't need it marked as
  // pending, so restore its destination.
  moves_[index]->ClearPending(destination);

  // This move's source may have changed due to swaps to resolve cycles and
  // so it may now be the last move in the cycle.  If so remove it.
  if (moves_[index]->src().Equals(destination)) {
    moves_[index]->Eliminate();
    return;
  }

  // The move may be blocked on a (at most one) pending move, in which case
  // we have a cycle.  Search for such a blocking move and perform a swap to
  // resolve it.
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& other_move = *moves_[i];
    if (other_move.Blocks(destination)) {
      ASSERT(other_move.IsPending());
      compiler_->BeginCodeSourceRange(source);
      EmitSwap(index);
      compiler_->EndCodeSourceRange(source);
      return;
    }
  }

  // This move is not blocked.
  compiler_->BeginCodeSourceRange(source);
  EmitMove(index);
  compiler_->EndCodeSourceRange(source);
}

void ParallelMoveResolver::EmitMove(int index) {
  MoveOperands* const move = moves_[index];
  const Location dst = move->dest();
  if (dst.IsStackSlot() || dst.IsDoubleStackSlot()) {
    ASSERT((dst.base_reg() != FPREG) ||
           ((-compiler::target::frame_layout.VariableIndexForFrameSlot(
                dst.stack_index())) < compiler_->StackSize()));
  }
  const Location src = move->src();
  ParallelMoveResolver::TemporaryAllocator temp(this, /*blocked=*/kNoRegister);
  compiler_->EmitMove(dst, src, &temp);
#if defined(DEBUG)
  // Allocating a scratch register here may cause stack spilling. Neither the
  // source nor destination register should be SP-relative in that case.
  for (const Location& loc : {dst, src}) {
    ASSERT(!temp.DidAllocateTemporary() || !loc.HasStackIndex() ||
           loc.base_reg() != SPREG);
  }
#endif
  move->Eliminate();
}

bool ParallelMoveResolver::IsScratchLocation(Location loc) {
  for (int i = 0; i < moves_.length(); ++i) {
    if (moves_[i]->Blocks(loc)) {
      return false;
    }
  }

  for (int i = 0; i < moves_.length(); ++i) {
    if (moves_[i]->dest().Equals(loc)) {
      return true;
    }
  }

  return false;
}

intptr_t ParallelMoveResolver::AllocateScratchRegister(
    Location::Kind kind,
    uword blocked_mask,
    intptr_t first_free_register,
    intptr_t last_free_register,
    bool* spilled) {
  COMPILE_ASSERT(static_cast<intptr_t>(sizeof(blocked_mask)) * kBitsPerByte >=
                 kNumberOfFpuRegisters);
  COMPILE_ASSERT(static_cast<intptr_t>(sizeof(blocked_mask)) * kBitsPerByte >=
                 kNumberOfCpuRegisters);
  intptr_t scratch = -1;
  for (intptr_t reg = first_free_register; reg <= last_free_register; reg++) {
    if ((((1 << reg) & blocked_mask) == 0) &&
        IsScratchLocation(Location::MachineRegisterLocation(kind, reg))) {
      scratch = reg;
      break;
    }
  }

  if (scratch == -1) {
    *spilled = true;
    for (intptr_t reg = first_free_register; reg <= last_free_register; reg++) {
      if (((1 << reg) & blocked_mask) == 0) {
        scratch = reg;
        break;
      }
    }
  } else {
    *spilled = false;
  }

  return scratch;
}

ParallelMoveResolver::ScratchFpuRegisterScope::ScratchFpuRegisterScope(
    ParallelMoveResolver* resolver,
    FpuRegister blocked)
    : resolver_(resolver), reg_(kNoFpuRegister), spilled_(false) {
  COMPILE_ASSERT(FpuTMP != kNoFpuRegister);
  uword blocked_mask =
      ((blocked != kNoFpuRegister) ? 1 << blocked : 0) | 1 << FpuTMP;
  reg_ = static_cast<FpuRegister>(resolver_->AllocateScratchRegister(
      Location::kFpuRegister, blocked_mask, 0, kNumberOfFpuRegisters - 1,
      &spilled_));

  if (spilled_) {
    resolver->SpillFpuScratch(reg_);
  }
}

ParallelMoveResolver::ScratchFpuRegisterScope::~ScratchFpuRegisterScope() {
  if (spilled_) {
    resolver_->RestoreFpuScratch(reg_);
  }
}

ParallelMoveResolver::TemporaryAllocator::TemporaryAllocator(
    ParallelMoveResolver* resolver,
    Register blocked)
    : resolver_(resolver),
      blocked_(blocked),
      reg_(kNoRegister),
      spilled_(false) {}

Register ParallelMoveResolver::TemporaryAllocator::AllocateTemporary() {
  ASSERT(reg_ == kNoRegister);

  uword blocked_mask = RegMaskBit(blocked_) | kReservedCpuRegisters;
  if (resolver_->compiler_->intrinsic_mode()) {
    // Block additional registers that must be preserved for intrinsics.
    blocked_mask |= RegMaskBit(ARGS_DESC_REG);
#if !defined(TARGET_ARCH_IA32)
    // Need to preserve CODE_REG to be able to store the PC marker
    // and load the pool pointer.
    blocked_mask |= RegMaskBit(CODE_REG);
#endif
  }
  reg_ = static_cast<Register>(
      resolver_->AllocateScratchRegister(Location::kRegister, blocked_mask, 0,
                                         kNumberOfCpuRegisters - 1, &spilled_));

  if (spilled_) {
    resolver_->SpillScratch(reg_);
  }

  DEBUG_ONLY(allocated_ = true;)
  return reg_;
}

void ParallelMoveResolver::TemporaryAllocator::ReleaseTemporary() {
  if (spilled_) {
    resolver_->RestoreScratch(reg_);
  }
  reg_ = kNoRegister;
}

ParallelMoveResolver::ScratchRegisterScope::ScratchRegisterScope(
    ParallelMoveResolver* resolver,
    Register blocked)
    : allocator_(resolver, blocked) {
  reg_ = allocator_.AllocateTemporary();
}

ParallelMoveResolver::ScratchRegisterScope::~ScratchRegisterScope() {
  allocator_.ReleaseTemporary();
}

const ICData* FlowGraphCompiler::GetOrAddInstanceCallICData(
    intptr_t deopt_id,
    const String& target_name,
    const Array& arguments_descriptor,
    intptr_t num_args_tested,
    const AbstractType& receiver_type,
    const Function& binary_smi_target) {
  if ((deopt_id_to_ic_data_ != NULL) &&
      ((*deopt_id_to_ic_data_)[deopt_id] != NULL)) {
    const ICData* res = (*deopt_id_to_ic_data_)[deopt_id];
    ASSERT(res->deopt_id() == deopt_id);
    ASSERT(res->target_name() == target_name.raw());
    ASSERT(res->NumArgsTested() == num_args_tested);
    ASSERT(res->TypeArgsLen() ==
           ArgumentsDescriptor(arguments_descriptor).TypeArgsLen());
    ASSERT(!res->is_static_call());
    ASSERT(res->receivers_static_type() == receiver_type.raw());
    return res;
  }

  auto& ic_data = ICData::ZoneHandle(zone());
  if (!binary_smi_target.IsNull()) {
    ASSERT(num_args_tested == 2);
    ASSERT(!binary_smi_target.IsNull());
    GrowableArray<intptr_t> cids(num_args_tested);
    cids.Add(kSmiCid);
    cids.Add(kSmiCid);
    ic_data = ICData::NewWithCheck(parsed_function().function(), target_name,
                                   arguments_descriptor, deopt_id,
                                   num_args_tested, ICData::kInstance, &cids,
                                   binary_smi_target, receiver_type);
  } else {
    ic_data = ICData::New(parsed_function().function(), target_name,
                          arguments_descriptor, deopt_id, num_args_tested,
                          ICData::kInstance, receiver_type);
  }

  if (deopt_id_to_ic_data_ != NULL) {
    (*deopt_id_to_ic_data_)[deopt_id] = &ic_data;
  }
  ASSERT(!ic_data.is_static_call());
  return &ic_data;
}

const ICData* FlowGraphCompiler::GetOrAddStaticCallICData(
    intptr_t deopt_id,
    const Function& target,
    const Array& arguments_descriptor,
    intptr_t num_args_tested,
    ICData::RebindRule rebind_rule) {
  if ((deopt_id_to_ic_data_ != NULL) &&
      ((*deopt_id_to_ic_data_)[deopt_id] != NULL)) {
    const ICData* res = (*deopt_id_to_ic_data_)[deopt_id];
    ASSERT(res->deopt_id() == deopt_id);
    ASSERT(res->target_name() == target.name());
    ASSERT(res->NumArgsTested() == num_args_tested);
    ASSERT(res->TypeArgsLen() ==
           ArgumentsDescriptor(arguments_descriptor).TypeArgsLen());
    ASSERT(res->is_static_call());
    return res;
  }

  const auto& ic_data = ICData::ZoneHandle(
      zone(), ICData::NewForStaticCall(parsed_function().function(), target,
                                       arguments_descriptor, deopt_id,
                                       num_args_tested, rebind_rule));
  if (deopt_id_to_ic_data_ != NULL) {
    (*deopt_id_to_ic_data_)[deopt_id] = &ic_data;
  }
  return &ic_data;
}

intptr_t FlowGraphCompiler::GetOptimizationThreshold() const {
  intptr_t threshold;
  if (is_optimizing()) {
    threshold = FLAG_reoptimization_counter_threshold;
  } else if (parsed_function_.function().IsIrregexpFunction()) {
    threshold = FLAG_regexp_optimization_counter_threshold;
  } else if (FLAG_randomize_optimization_counter) {
    threshold = Thread::Current()->GetRandomUInt64() %
                FLAG_optimization_counter_threshold;
  } else {
    const intptr_t basic_blocks = flow_graph().preorder().length();
    ASSERT(basic_blocks > 0);
    threshold = FLAG_optimization_counter_scale * basic_blocks +
                FLAG_min_optimization_counter_threshold;
    if (threshold > FLAG_optimization_counter_threshold) {
      threshold = FLAG_optimization_counter_threshold;
    }
  }

  // Threshold = 0 doesn't make sense because we increment the counter before
  // testing against the threshold. Perhaps we could interpret it to mean
  // "generate optimized code immediately without unoptimized compilation
  // first", but this isn't supported in our pipeline because there would be no
  // code for the optimized code to deoptimize into.
  if (threshold == 0) threshold = 1;

  // See Compiler::CanOptimizeFunction. In short, we have to allow the
  // unoptimized code to run at least once to prevent an infinite compilation
  // loop.
  if (threshold == 1 && parsed_function().function().HasBreakpoint()) {
    threshold = 2;
  }

  return threshold;
}

const Class& FlowGraphCompiler::BoxClassFor(Representation rep) {
  switch (rep) {
    case kUnboxedFloat:
    case kUnboxedDouble:
      return double_class();
    case kUnboxedFloat32x4:
      return float32x4_class();
    case kUnboxedFloat64x2:
      return float64x2_class();
    case kUnboxedInt32x4:
      return int32x4_class();
    case kUnboxedInt64:
      return mint_class();
    default:
      UNREACHABLE();
      return Class::ZoneHandle();
  }
}

void FlowGraphCompiler::BeginCodeSourceRange(const InstructionSource& source) {
  code_source_map_builder_->BeginCodeSourceRange(assembler()->CodeSize(),
                                                 source);
}

void FlowGraphCompiler::EndCodeSourceRange(const InstructionSource& source) {
  code_source_map_builder_->EndCodeSourceRange(assembler()->CodeSize(), source);
}

const CallTargets* FlowGraphCompiler::ResolveCallTargetsForReceiverCid(
    intptr_t cid,
    const String& selector,
    const Array& args_desc_array) {
  Zone* zone = Thread::Current()->zone();

  ArgumentsDescriptor args_desc(args_desc_array);

  Function& fn = Function::ZoneHandle(zone);
  if (!LookupMethodFor(cid, selector, args_desc, &fn)) return NULL;

  CallTargets* targets = new (zone) CallTargets(zone);
  targets->Add(new (zone) TargetInfo(cid, cid, &fn, /* count = */ 1,
                                     StaticTypeExactnessState::NotTracking()));

  return targets;
}

bool FlowGraphCompiler::LookupMethodFor(int class_id,
                                        const String& name,
                                        const ArgumentsDescriptor& args_desc,
                                        Function* fn_return,
                                        bool* class_is_abstract_return) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  if (class_id < 0) return false;
  if (class_id >= isolate->class_table()->NumCids()) return false;

  ClassPtr raw_class = isolate->class_table()->At(class_id);
  if (raw_class == nullptr) return false;
  Class& cls = Class::Handle(zone, raw_class);
  if (cls.IsNull()) return false;
  if (!cls.is_finalized()) return false;
  if (Array::Handle(cls.current_functions()).IsNull()) return false;

  if (class_is_abstract_return != NULL) {
    *class_is_abstract_return = cls.is_abstract();
  }
  const bool allow_add = false;
  Function& target_function =
      Function::Handle(zone, Resolver::ResolveDynamicForReceiverClass(
                                 cls, name, args_desc, allow_add));
  if (target_function.IsNull()) return false;
  *fn_return = target_function.raw();
  return true;
}

void FlowGraphCompiler::EmitPolymorphicInstanceCall(
    const PolymorphicInstanceCallInstr* call,
    const CallTargets& targets,
    ArgumentsInfo args_info,
    intptr_t deopt_id,
    const InstructionSource& source,
    LocationSummary* locs,
    bool complete,
    intptr_t total_ic_calls,
    bool receiver_can_be_smi) {
  ASSERT(call != nullptr);
  if (FLAG_polymorphic_with_deopt) {
    compiler::Label* deopt =
        AddDeoptStub(deopt_id, ICData::kDeoptPolymorphicInstanceCallTestFail);
    compiler::Label ok;
    EmitTestAndCall(targets, call->function_name(), args_info,
                    deopt,  // No cid match.
                    &ok,    // Found cid.
                    deopt_id, source, locs, complete, total_ic_calls,
                    call->entry_kind());
    assembler()->Bind(&ok);
  } else {
    if (complete) {
      compiler::Label ok;
      EmitTestAndCall(targets, call->function_name(), args_info,
                      NULL,  // No cid match.
                      &ok,   // Found cid.
                      deopt_id, source, locs, true, total_ic_calls,
                      call->entry_kind());
      assembler()->Bind(&ok);
    } else {
      const ICData& unary_checks =
          ICData::ZoneHandle(zone(), call->ic_data()->AsUnaryClassChecks());
      EmitInstanceCallAOT(unary_checks, deopt_id, source, locs,
                          call->entry_kind(), receiver_can_be_smi);
    }
  }
}

#define __ assembler()->

void FlowGraphCompiler::CheckClassIds(Register class_id_reg,
                                      const GrowableArray<intptr_t>& class_ids,
                                      compiler::Label* is_equal_lbl,
                                      compiler::Label* is_not_equal_lbl) {
  for (const auto& id : class_ids) {
    __ CompareImmediate(class_id_reg, id);
    __ BranchIf(EQUAL, is_equal_lbl);
  }
  __ Jump(is_not_equal_lbl);
}

void FlowGraphCompiler::EmitTestAndCall(const CallTargets& targets,
                                        const String& function_name,
                                        ArgumentsInfo args_info,
                                        compiler::Label* failed,
                                        compiler::Label* match_found,
                                        intptr_t deopt_id,
                                        const InstructionSource& source_index,
                                        LocationSummary* locs,
                                        bool complete,
                                        intptr_t total_ic_calls,
                                        Code::EntryKind entry_kind) {
  ASSERT(is_optimizing());
  ASSERT(complete || (failed != nullptr));  // Complete calls can't fail.

  const Array& arguments_descriptor =
      Array::ZoneHandle(zone(), args_info.ToArgumentsDescriptor());
  EmitTestAndCallLoadReceiver(args_info.count_without_type_args,
                              arguments_descriptor);

  static const int kNoCase = -1;
  int smi_case = kNoCase;
  int which_case_to_skip = kNoCase;

  const int length = targets.length();
  ASSERT(length > 0);
  int non_smi_length = length;

  // Find out if one of the classes in one of the cases is the Smi class. We
  // will be handling that specially.
  for (int i = 0; i < length; i++) {
    const intptr_t start = targets[i].cid_start;
    if (start > kSmiCid) continue;
    const intptr_t end = targets[i].cid_end;
    if (end >= kSmiCid) {
      smi_case = i;
      if (start == kSmiCid && end == kSmiCid) {
        // If this case has only the Smi class then we won't need to emit it at
        // all later.
        which_case_to_skip = i;
        non_smi_length--;
      }
      break;
    }
  }

  if (smi_case != kNoCase) {
    compiler::Label after_smi_test;
    // If the call is complete and there are no other possible receiver
    // classes - then receiver can only be a smi value and we don't need
    // to check if it is a smi.
    if (!(complete && non_smi_length == 0)) {
      EmitTestAndCallSmiBranch(non_smi_length == 0 ? failed : &after_smi_test,
                               /* jump_if_smi= */ false);
    }

    // Do not use the code from the function, but let the code be patched so
    // that we can record the outgoing edges to other code.
    const Function& function = *targets.TargetAt(smi_case)->target;
    GenerateStaticDartCall(deopt_id, source_index, PcDescriptorsLayout::kOther,
                           locs, function, entry_kind);
    __ Drop(args_info.size_with_type_args);
    if (match_found != NULL) {
      __ Jump(match_found);
    }
    __ Bind(&after_smi_test);
  } else {
    if (!complete) {
      // Smi is not a valid class.
      EmitTestAndCallSmiBranch(failed, /* jump_if_smi = */ true);
    }
  }

  if (non_smi_length == 0) {
    // If non_smi_length is 0 then only a Smi check was needed; the Smi check
    // above will fail if there was only one check and receiver is not Smi.
    return;
  }

  bool add_megamorphic_call = false;
  int bias = 0;

  // Value is not Smi.
  EmitTestAndCallLoadCid(EmitTestCidRegister());

  int last_check = which_case_to_skip == length - 1 ? length - 2 : length - 1;

  for (intptr_t i = 0; i < length; i++) {
    if (i == which_case_to_skip) continue;
    const bool is_last_check = (i == last_check);
    const int count = targets.TargetAt(i)->count;
    if (!is_last_check && !complete && count < (total_ic_calls >> 5)) {
      // This case is hit too rarely to be worth writing class-id checks inline
      // for.  Note that we can't do this for calls with only one target because
      // the type propagator may have made use of that and expects a deopt if
      // a new class is seen at this calls site.  See IsMonomorphic.
      add_megamorphic_call = true;
      break;
    }
    compiler::Label next_test;
    if (!complete || !is_last_check) {
      bias = EmitTestAndCallCheckCid(assembler(),
                                     is_last_check ? failed : &next_test,
                                     EmitTestCidRegister(), targets[i], bias,
                                     /*jump_on_miss =*/true);
    }
    // Do not use the code from the function, but let the code be patched so
    // that we can record the outgoing edges to other code.
    const Function& function = *targets.TargetAt(i)->target;
    GenerateStaticDartCall(deopt_id, source_index, PcDescriptorsLayout::kOther,
                           locs, function, entry_kind);
    __ Drop(args_info.size_with_type_args);
    if (!is_last_check || add_megamorphic_call) {
      __ Jump(match_found);
    }
    __ Bind(&next_test);
  }
  if (add_megamorphic_call) {
    int try_index = kInvalidTryIndex;
    EmitMegamorphicInstanceCall(function_name, arguments_descriptor, deopt_id,
                                source_index, locs, try_index);
  }
}

bool FlowGraphCompiler::GenerateSubtypeRangeCheck(Register class_id_reg,
                                                  const Class& type_class,
                                                  compiler::Label* is_subtype) {
  HierarchyInfo* hi = Thread::Current()->hierarchy_info();
  if (hi != NULL) {
    const CidRangeVector& ranges =
        hi->SubtypeRangesForClass(type_class,
                                  /*include_abstract=*/false,
                                  /*exclude_null=*/false);
    if (ranges.length() <= kMaxNumberOfCidRangesToTest) {
      GenerateCidRangesCheck(assembler(), class_id_reg, ranges, is_subtype);
      return true;
    }
  }

  // We don't have cid-ranges for subclasses, so we'll just test against the
  // class directly if it's non-abstract.
  if (!type_class.is_abstract()) {
    __ CompareImmediate(class_id_reg, type_class.id());
    __ BranchIf(EQUAL, is_subtype);
  }
  return false;
}

void FlowGraphCompiler::GenerateCidRangesCheck(
    compiler::Assembler* assembler,
    Register class_id_reg,
    const CidRangeVector& cid_ranges,
    compiler::Label* inside_range_lbl,
    compiler::Label* outside_range_lbl,
    bool fall_through_if_inside) {
  // If there are no valid class ranges, the check will fail.  If we are
  // supposed to fall-through in the positive case, we'll explicitly jump to
  // the [outside_range_lbl].
  if (cid_ranges.length() == 1 && cid_ranges[0].IsIllegalRange()) {
    if (fall_through_if_inside) {
      assembler->Jump(outside_range_lbl);
    }
    return;
  }

  int bias = 0;
  for (intptr_t i = 0; i < cid_ranges.length(); ++i) {
    const CidRangeValue& range = cid_ranges[i];
    RELEASE_ASSERT(!range.IsIllegalRange());
    const bool last_round = i == (cid_ranges.length() - 1);

    compiler::Label* jump_label = last_round && fall_through_if_inside
                                      ? outside_range_lbl
                                      : inside_range_lbl;
    const bool jump_on_miss = last_round && fall_through_if_inside;

    bias = EmitTestAndCallCheckCid(assembler, jump_label, class_id_reg, range,
                                   bias, jump_on_miss);
  }
}

bool FlowGraphCompiler::CheckAssertAssignableTypeTestingABILocations(
    const LocationSummary& locs) {
  ASSERT(locs.in(AssertAssignableInstr::kInstancePos).IsRegister() &&
         locs.in(AssertAssignableInstr::kInstancePos).reg() ==
             TypeTestABI::kInstanceReg);
  ASSERT((locs.in(AssertAssignableInstr::kDstTypePos).IsConstant() &&
          locs.in(AssertAssignableInstr::kDstTypePos)
              .constant()
              .IsAbstractType()) ||
         (locs.in(AssertAssignableInstr::kDstTypePos).IsRegister() &&
          locs.in(AssertAssignableInstr::kDstTypePos).reg() ==
              TypeTestABI::kDstTypeReg));
  ASSERT(locs.in(AssertAssignableInstr::kInstantiatorTAVPos).IsRegister() &&
         locs.in(AssertAssignableInstr::kInstantiatorTAVPos).reg() ==
             TypeTestABI::kInstantiatorTypeArgumentsReg);
  ASSERT(locs.in(AssertAssignableInstr::kFunctionTAVPos).IsRegister() &&
         locs.in(AssertAssignableInstr::kFunctionTAVPos).reg() ==
             TypeTestABI::kFunctionTypeArgumentsReg);
  ASSERT(locs.out(0).IsRegister() &&
         locs.out(0).reg() == TypeTestABI::kInstanceReg);
  return true;
}

// Generates function type check.
//
// See [GenerateInlineInstanceof] for calling convention.
SubtypeTestCachePtr FlowGraphCompiler::GenerateFunctionTypeTest(
    const InstructionSource& source,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("FunctionTypeTest");

  __ BranchIfSmi(TypeTestABI::kInstanceReg, is_not_instance_lbl);
  // Load the type into the right register for the subtype test cache check.
  __ LoadUniqueObject(TypeTestABI::kDstTypeReg, type);
  // Uninstantiated type class is known at compile time, but the type
  // arguments are determined at runtime by the instantiator(s).
  return GenerateCallSubtypeTestStub(kTestTypeSevenArgs, is_instance_lbl,
                                     is_not_instance_lbl);
}

// Inputs (from TypeTestABI):
//   - kInstanceReg : instance to test against.
//   - kInstantiatorTypeArgumentsReg : instantiator type arguments (if needed).
//   - kFunctionTypeArgumentsReg : function type arguments (if needed).
//
// Preserves all input registers.
//
// Clobbers kDstTypeReg, kSubtypeTestCacheReg and kSubtypeTestCacheResultReg at
// a minimum, may clobber additional registers depending on architecture. See
// GenerateSubtypeNTestCacheStub for architecture-specific registers that should
// be saved across a subtype test cache stub call.
//
// Note that this inlined code must be followed by the runtime_call code, as it
// may fall through to it. Otherwise, this inline code will jump to the label
// is_instance or to the label is_not_instance.
SubtypeTestCachePtr FlowGraphCompiler::GenerateInlineInstanceof(
    const InstructionSource& source,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("InlineInstanceof");

  if (type.IsFunctionType()) {
    return GenerateFunctionTypeTest(source, type, is_instance_lbl,
                                    is_not_instance_lbl);
  }

  if (type.IsInstantiated()) {
    const Class& type_class = Class::ZoneHandle(zone(), type.type_class());
    // A class equality check is only applicable with a dst type (not a
    // function type) of a non-parameterized class or with a raw dst type of
    // a parameterized class.
    if (type_class.NumTypeArguments() > 0) {
      return GenerateInstantiatedTypeWithArgumentsTest(
          source, type, is_instance_lbl, is_not_instance_lbl);
      // Fall through to runtime call.
    }
    const bool has_fall_through = GenerateInstantiatedTypeNoArgumentsTest(
        source, type, is_instance_lbl, is_not_instance_lbl);
    if (has_fall_through) {
      // If test non-conclusive so far, try the inlined type-test cache.
      // 'type' is known at compile time.
      return GenerateSubtype1TestCacheLookup(
          source, type_class, is_instance_lbl, is_not_instance_lbl);
    } else {
      return SubtypeTestCache::null();
    }
  }
  return GenerateUninstantiatedTypeTest(source, type, is_instance_lbl,
                                        is_not_instance_lbl);
}

FlowGraphCompiler::TypeTestStubKind
FlowGraphCompiler::GetTypeTestStubKindForTypeParameter(
    const TypeParameter& type_param) {
  // If it's guaranteed, by type-parameter bound, that the type parameter will
  // never have a value of a function type, then we can safely do a 5-type
  // test instead of a 7-type test.
  AbstractType& bound = AbstractType::Handle(zone(), type_param.bound());
  bound = bound.UnwrapFutureOr();
  return !bound.IsTopTypeForSubtyping() && !bound.IsObjectType() &&
                 !bound.IsFunctionType() && !bound.IsDartFunctionType() &&
                 bound.IsType()
             ? kTestTypeFiveArgs
             : kTestTypeSevenArgs;
}

// Generates quick and subtype cache tests when only the instance need be
// checked. Jumps to 'is_instance' or 'is_not_instance' respectively, if any
// generated check is conclusive, otherwise falls through if further checking is
// required.
//
// See [GenerateInlineInstanceof] for calling convention.
SubtypeTestCachePtr FlowGraphCompiler::GenerateSubtype1TestCacheLookup(
    const InstructionSource& source,
    const Class& type_class,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("Subtype1TestCacheLookup");
#if defined(DEBUG)
  compiler::Label ok;
  __ BranchIfNotSmi(TypeTestABI::kInstanceReg, &ok);
  __ Breakpoint();
  __ Bind(&ok);
#endif
  // Check immediate superclass equality. If type_class is Object, then testing
  // supertype may yield a wrong result for Null in NNBD strong mode (because
  // Null also extends Object).
  if (!type_class.IsObjectClass() ||
      !Isolate::Current()->use_strict_null_safety_checks()) {
    // We don't use TypeTestABI::kScratchReg for the first scratch register as
    // it is not defined on IA32. Instead, we use the subtype test cache
    // register, as it is clobbered by the subtype test cache stub call anyway.
    const Register kScratch1Reg = TypeTestABI::kSubtypeTestCacheReg;
#if defined(TARGET_ARCH_IA32)
    // We don't use TypeTestABI::kScratchReg as it is not defined on IA32.
    // Instead, we pick another TypeTestABI register and push/pop it around
    // the uses of the second scratch register.
    const Register kScratch2Reg = TypeTestABI::kDstTypeReg;
    __ PushRegister(kScratch2Reg);
#else
    // We can use TypeTestABI::kScratchReg for the second scratch register, as
    // IA32 is handled separately.
    const Register kScratch2Reg = TypeTestABI::kScratchReg;
#endif
    static_assert(kScratch1Reg != kScratch2Reg,
                  "Scratch registers must be distinct");
    __ LoadClassId(kScratch2Reg, TypeTestABI::kInstanceReg);
    __ LoadClassById(kScratch1Reg, kScratch2Reg);
#if defined(TARGET_ARCH_IA32)
    // kScratch2 is no longer used, so restore it.
    __ PopRegister(kScratch2Reg);
#endif
    __ LoadFieldFromOffset(kScratch1Reg, kScratch1Reg,
                           compiler::target::Class::super_type_offset());
    __ LoadFieldFromOffset(kScratch1Reg, kScratch1Reg,
                           compiler::target::Type::type_class_id_offset());
    __ CompareImmediate(kScratch1Reg, Smi::RawValue(type_class.id()));
    __ BranchIf(EQUAL, is_instance_lbl);
  }

  return GenerateCallSubtypeTestStub(kTestTypeOneArg, is_instance_lbl,
                                     is_not_instance_lbl);
}

// Generates quick and subtype cache tests for an instantiated generic type.
// Jumps to 'is_instance' or 'is_not_instance' respectively, if any generated
// check is conclusive, otherwise falls through if further checking is required.
//
// See [GenerateInlineInstanceof] for calling convention.
SubtypeTestCachePtr
FlowGraphCompiler::GenerateInstantiatedTypeWithArgumentsTest(
    const InstructionSource& source,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("InstantiatedTypeWithArgumentsTest");
  ASSERT(type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  const Class& type_class = Class::ZoneHandle(zone(), type.type_class());
  ASSERT(type_class.NumTypeArguments() > 0);
  const Type& smi_type = Type::Handle(zone(), Type::SmiType());
  const bool smi_is_ok = smi_type.IsSubtypeOf(type, Heap::kOld);
  __ BranchIfSmi(TypeTestABI::kInstanceReg,
                 smi_is_ok ? is_instance_lbl : is_not_instance_lbl);

  const intptr_t num_type_args = type_class.NumTypeArguments();
  const intptr_t num_type_params = type_class.NumTypeParameters();
  const intptr_t from_index = num_type_args - num_type_params;
  const TypeArguments& type_arguments =
      TypeArguments::ZoneHandle(zone(), type.arguments());
  const bool is_raw_type = type_arguments.IsNull() ||
                           type_arguments.IsRaw(from_index, num_type_params);
  // We don't use TypeTestABI::kScratchReg as it is not defined on IA32.
  // Instead, we use the subtype test cache register, as it is clobbered by the
  // subtype test cache stub call anyway.
  const Register kScratchReg = TypeTestABI::kSubtypeTestCacheReg;
  if (is_raw_type) {
    // dynamic type argument, check only classes.
    __ LoadClassId(kScratchReg, TypeTestABI::kInstanceReg);
    __ CompareImmediate(kScratchReg, type_class.id());
    __ BranchIf(EQUAL, is_instance_lbl);
    // List is a very common case.
    if (IsListClass(type_class)) {
      GenerateListTypeCheck(kScratchReg, is_instance_lbl);
    }
    return GenerateSubtype1TestCacheLookup(source, type_class, is_instance_lbl,
                                           is_not_instance_lbl);
  }
  // If one type argument only, check if type argument is a top type.
  if (type_arguments.Length() == 1) {
    const AbstractType& tp_argument =
        AbstractType::ZoneHandle(zone(), type_arguments.TypeAt(0));
    if (tp_argument.IsTopTypeForSubtyping()) {
      // Instance class test only necessary.
      return GenerateSubtype1TestCacheLookup(
          source, type_class, is_instance_lbl, is_not_instance_lbl);
    }
  }

  // Load the type into the right register for the subtype test cache check.
  __ LoadUniqueObject(TypeTestABI::kDstTypeReg, type);
  // Regular subtype test cache involving instance's type arguments.
  return GenerateCallSubtypeTestStub(kTestTypeThreeArgs, is_instance_lbl,
                                     is_not_instance_lbl);
}

// Generates quick and subtype cache tests for an instantiated non-generic type.
// Jumps to 'is_instance' or 'is_not_instance' respectively, if any generated
// check is conclusive. Returns whether the code will fall through for further
// type checking because the checks are not exhaustive.
//
// See [GenerateInlineInstanceof] for calling convention.
//
// Uses kScratchReg, so this implementation cannot be shared with IA32.
bool FlowGraphCompiler::GenerateInstantiatedTypeNoArgumentsTest(
    const InstructionSource& source,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("InstantiatedTypeNoArgumentsTest");
  ASSERT(type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  const Class& type_class = Class::Handle(zone(), type.type_class());
  ASSERT(type_class.NumTypeArguments() == 0);

  // We don't use TypeTestABI::kScratchReg as it is not defined on IA32.
  // Instead, we use the subtype test cache register, as it is clobbered by the
  // subtype test cache stub call anyway.
  const Register kScratchReg = TypeTestABI::kSubtypeTestCacheReg;

  const Class& smi_class = Class::Handle(zone(), Smi::Class());
  const bool smi_is_ok =
      Class::IsSubtypeOf(smi_class, Object::null_type_arguments(),
                         Nullability::kNonNullable, type, Heap::kOld);
  __ BranchIfSmi(TypeTestABI::kInstanceReg,
                 smi_is_ok ? is_instance_lbl : is_not_instance_lbl);
  __ LoadClassId(kScratchReg, TypeTestABI::kInstanceReg);
  // Bool interface can be implemented only by core class Bool.
  if (type.IsBoolType()) {
    __ CompareImmediate(kScratchReg, kBoolCid);
    __ BranchIf(EQUAL, is_instance_lbl);
    __ Jump(is_not_instance_lbl);
    return false;
  }
  // Custom checking for numbers (Smi, Mint and Double).
  // Note that instance is not Smi (checked above).
  if (type.IsNumberType() || type.IsIntType() || type.IsDoubleType()) {
    GenerateNumberTypeCheck(kScratchReg, type, is_instance_lbl,
                            is_not_instance_lbl);
    return false;
  }
  if (type.IsStringType()) {
    GenerateStringTypeCheck(kScratchReg, is_instance_lbl, is_not_instance_lbl);
    return false;
  }
  if (type.IsDartFunctionType()) {
    // Check if instance is a closure.
    __ CompareImmediate(kScratchReg, kClosureCid);
    __ BranchIf(EQUAL, is_instance_lbl);
    return true;
  }

  // Fast case for cid-range based checks.
  // Warning: This code destroys the contents of [kScratchReg], so this should
  // be the last check in this method. It returns whether the checks were
  // exhaustive, so we negate it to indicate whether we'll fall through.
  return !GenerateSubtypeRangeCheck(kScratchReg, type_class, is_instance_lbl);
}

// Generates inlined check if 'type' is a type parameter or type itself.
//
// See [GenerateInlineInstanceof] for calling convention.
SubtypeTestCachePtr FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    const InstructionSource& source,
    const AbstractType& type,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  __ Comment("UninstantiatedTypeTest");
  ASSERT(!type.IsInstantiated());
  ASSERT(!type.IsFunctionType());
  // Skip check if destination is a dynamic type.
  if (type.IsTypeParameter()) {
    // We don't use TypeTestABI::kScratchReg as it is not defined on IA32.
    // Instead, we use the subtype test cache register, as it is clobbered by
    // the subtype test cache stub call anyway.
    const Register kScratchReg = TypeTestABI::kSubtypeTestCacheReg;

    const TypeParameter& type_param = TypeParameter::Cast(type);

    const Register kTypeArgumentsReg =
        type_param.IsClassTypeParameter()
            ? TypeTestABI::kInstantiatorTypeArgumentsReg
            : TypeTestABI::kFunctionTypeArgumentsReg;
    // Check if type arguments are null, i.e. equivalent to vector of dynamic.
    __ CompareObject(kTypeArgumentsReg, Object::null_object());
    __ BranchIf(EQUAL, is_instance_lbl);
    __ LoadFieldFromOffset(
        kScratchReg, kTypeArgumentsReg,
        compiler::target::TypeArguments::type_at_offset(type_param.index()));
    // kScratchReg: Concrete type of type.
    // Check if type argument is dynamic, Object?, or void.
    __ CompareObject(kScratchReg, Object::dynamic_type());
    __ BranchIf(EQUAL, is_instance_lbl);
    __ CompareObject(
        kScratchReg,
        Type::ZoneHandle(zone(),
                         isolate()->object_store()->nullable_object_type()));
    __ BranchIf(EQUAL, is_instance_lbl);
    __ CompareObject(kScratchReg, Object::void_type());
    __ BranchIf(EQUAL, is_instance_lbl);

    // For Smi check quickly against int and num interfaces.
    compiler::Label not_smi;
    __ BranchIfNotSmi(TypeTestABI::kInstanceReg, &not_smi,
                      compiler::Assembler::kNearJump);
    __ CompareObject(kScratchReg, Type::ZoneHandle(zone(), Type::IntType()));
    __ BranchIf(EQUAL, is_instance_lbl);
    __ CompareObject(kScratchReg, Type::ZoneHandle(zone(), Type::Number()));
    __ BranchIf(EQUAL, is_instance_lbl);
    // Smi can be handled by type test cache.
    __ Bind(&not_smi);

    // Load the type into the right register for the subtype test cache check.
    __ LoadUniqueObject(TypeTestABI::kDstTypeReg, type);
    const auto test_kind = GetTypeTestStubKindForTypeParameter(type_param);
    return GenerateCallSubtypeTestStub(test_kind, is_instance_lbl,
                                       is_not_instance_lbl);
  }
  if (type.IsType()) {
    // The only uninstantiated type to which a Smi is assignable is FutureOr<T>,
    // as T might be a top type or int or num when instantiated
    if (!type.IsFutureOrType()) {
      __ BranchIfSmi(TypeTestABI::kInstanceReg, is_not_instance_lbl);
    }
    // Load the type into the right register for the subtype test cache check.
    __ LoadUniqueObject(TypeTestABI::kDstTypeReg, type);
    // Uninstantiated type class is known at compile time, but the type
    // arguments are determined at runtime by the instantiator(s).
    return GenerateCallSubtypeTestStub(kTestTypeFiveArgs, is_instance_lbl,
                                       is_not_instance_lbl);
  }
  return SubtypeTestCache::null();
}

#if !defined(TARGET_ARCH_IA32)
// If instanceof type test cannot be performed successfully at compile time and
// therefore eliminated, optimize it by adding inlined tests for:
// - Null -> see comment below.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs (from TypeTestABI):
// - kInstanceReg: object.
// - kInstantiatorTypeArgumentsReg: instantiator type arguments or raw_null.
// - kFunctionTypeArgumentsReg: function type arguments or raw_null.
// Returns:
// - true or false in kInstanceOfResultReg.
void FlowGraphCompiler::GenerateInstanceOf(const InstructionSource& source,
                                           intptr_t deopt_id,
                                           const AbstractType& type,
                                           LocationSummary* locs) {
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsTopTypeForInstanceOf());  // Already checked.

  compiler::Label is_instance, is_not_instance;
  // 'null' is an instance of Null, Object*, Never*, void, and dynamic.
  // In addition, 'null' is an instance of any nullable type.
  // It is also an instance of FutureOr<T> if it is an instance of T.
  const AbstractType& unwrapped_type =
      AbstractType::Handle(type.UnwrapFutureOr());
  if (!unwrapped_type.IsTypeParameter() || unwrapped_type.IsNullable()) {
    // Only nullable type parameter remains nullable after instantiation.
    // See NullIsInstanceOf().
    __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
    __ BranchIf(EQUAL,
                (unwrapped_type.IsNullable() ||
                 (unwrapped_type.IsLegacy() && unwrapped_type.IsNeverType()))
                    ? &is_instance
                    : &is_not_instance);
  }

  // Generate inline instanceof test.
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle(zone());
  // kInstanceReg, kInstantiatorTypeArgumentsReg, and kFunctionTypeArgumentsReg
  // are preserved across the call.
  test_cache =
      GenerateInlineInstanceof(source, type, &is_instance, &is_not_instance);

  // test_cache is null if there is no fall-through.
  compiler::Label done;
  if (!test_cache.IsNull()) {
    // Generate Runtime call.
    __ LoadUniqueObject(TypeTestABI::kDstTypeReg, type);
    __ LoadUniqueObject(TypeTestABI::kSubtypeTestCacheReg, test_cache);
    GenerateStubCall(source, StubCode::InstanceOf(),
                     /*kind=*/PcDescriptorsLayout::kOther, locs, deopt_id);
    __ Jump(&done, compiler::Assembler::kNearJump);
  }
  __ Bind(&is_not_instance);
  __ LoadObject(TypeTestABI::kInstanceOfResultReg, Bool::Get(false));
  __ Jump(&done, compiler::Assembler::kNearJump);

  __ Bind(&is_instance);
  __ LoadObject(TypeTestABI::kInstanceOfResultReg, Bool::Get(true));
  __ Bind(&done);
}

// Expected inputs (from TypeTestABI):
// - kInstanceReg: instance (preserved).
// - kDstTypeReg: destination type (for test_kind != kTestTypeOneArg).
// - kInstantiatorTypeArgumentsReg: instantiator type arguments
//   (for test_kind == kTestTypeFiveArg or test_kind == kTestTypeSevenArg).
// - kFunctionTypeArgumentsReg: function type arguments
//   (for test_kind == kTestTypeFiveArg or test_kind == kTestTypeSevenArg).
//
// See the arch-specific GenerateSubtypeNTestCacheStub method to see which
// registers may need saving across this call.
SubtypeTestCachePtr FlowGraphCompiler::GenerateCallSubtypeTestStub(
    TypeTestStubKind test_kind,
    compiler::Label* is_instance_lbl,
    compiler::Label* is_not_instance_lbl) {
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(zone(), SubtypeTestCache::New());
  __ LoadUniqueObject(TypeTestABI::kSubtypeTestCacheReg, type_test_cache);
  if (test_kind == kTestTypeOneArg) {
    __ Call(StubCode::Subtype1TestCache());
  } else if (test_kind == kTestTypeThreeArgs) {
    __ Call(StubCode::Subtype3TestCache());
  } else if (test_kind == kTestTypeFiveArgs) {
    __ Call(StubCode::Subtype5TestCache());
  } else if (test_kind == kTestTypeSevenArgs) {
    __ Call(StubCode::Subtype7TestCache());
  } else {
    UNREACHABLE();
  }
  GenerateBoolToJump(TypeTestABI::kSubtypeTestCacheResultReg, is_instance_lbl,
                     is_not_instance_lbl);
  return type_test_cache.raw();
}

// Generates an assignable check for a given object. Emits no code if the
// destination type is known at compile time and is a top type. See
// GenerateCallerChecksForAssertAssignable for other optimized cases.
//
// Inputs (preserved for successful checks):
// - TypeTestABI::kInstanceReg: object.
// - TypeTestABI::kDstTypeReg: destination type (if non-constant).
// - TypeTestABI::kInstantiatorTypeArgumentsReg: instantiator type arguments.
// - TypeTestABI::kFunctionTypeArgumentsReg: function type arguments.
//
// Throws:
// - TypeError (on unsuccessful assignable checks)
//
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateAssertAssignable(
    CompileType* receiver_type,
    const InstructionSource& source,
    intptr_t deopt_id,
    const String& dst_name,
    LocationSummary* locs) {
  ASSERT(!source.token_pos.IsClassifying());
  ASSERT(CheckAssertAssignableTypeTestingABILocations(*locs));

  // Non-null if we have a constant destination type.
  const auto& dst_type =
      locs->in(AssertAssignableInstr::kDstTypePos).IsConstant()
          ? AbstractType::Cast(
                locs->in(AssertAssignableInstr::kDstTypePos).constant())
          : Object::null_abstract_type();

  if (!dst_type.IsNull()) {
    ASSERT(dst_type.IsFinalized());
    if (dst_type.IsTopTypeForSubtyping()) return;  // No code needed.
  }

  compiler::Label done;
  Register type_reg = TypeTestABI::kDstTypeReg;
  // Generate caller-side checks to perform prior to calling the TTS.
  if (dst_type.IsNull()) {
    __ Comment("AssertAssignable for runtime type");
    // kDstTypeReg should already contain the destination type.
  } else {
    __ Comment("AssertAssignable for compile-time type");
    GenerateCallerChecksForAssertAssignable(receiver_type, dst_type, &done);
    if (dst_type.IsTypeParameter()) {
      // The resolved type parameter is in the scratch register.
      type_reg = TypeTestABI::kScratchReg;
    }
  }

  GenerateTTSCall(source, deopt_id, type_reg, dst_type, dst_name, locs);
  __ Bind(&done);
}

// Generates a call to the type testing stub for the type in [reg_with_type].
// Provide a non-null [dst_type] and [dst_name] if they are known at compile
// time.
void FlowGraphCompiler::GenerateTTSCall(const InstructionSource& source,
                                        intptr_t deopt_id,
                                        Register reg_with_type,
                                        const AbstractType& dst_type,
                                        const String& dst_name,
                                        LocationSummary* locs) {
  ASSERT(!dst_name.IsNull());
  // We use 2 consecutive entries in the pool for the subtype cache and the
  // destination name.  The second entry, namely [dst_name] seems to be unused,
  // but it will be used by the code throwing a TypeError if the type test fails
  // (see runtime/vm/runtime_entry.cc:TypeCheck).  It will use pattern matching
  // on the call site to find out at which pool index the destination name is
  // located.
  const intptr_t sub_type_cache_index = __ object_pool_builder().AddObject(
      Object::null_object(), compiler::ObjectPoolBuilderEntry::kPatchable);
  const intptr_t dst_name_index = __ object_pool_builder().AddObject(
      dst_name, compiler::ObjectPoolBuilderEntry::kPatchable);
  ASSERT((sub_type_cache_index + 1) == dst_name_index);
  ASSERT(__ constant_pool_allowed());

  __ Comment("TTSCall");
  // If the dst_type is known at compile time and instantiated, we know the
  // target TTS stub and so can use a PC-relative call when available.
  if (!dst_type.IsNull() && dst_type.IsInstantiated() &&
      CanPcRelativeCall(dst_type)) {
    __ LoadWordFromPoolIndex(TypeTestABI::kSubtypeTestCacheReg,
                             sub_type_cache_index);
    __ GenerateUnRelocatedPcRelativeCall();
    AddPcRelativeTTSCallTypeTarget(dst_type);
  } else {
    GenerateIndirectTTSCall(assembler(), reg_with_type, sub_type_cache_index);
  }
  EmitCallsiteMetadata(source, deopt_id, PcDescriptorsLayout::kOther, locs);
}

// Optimize assignable type check by adding inlined tests for:
// - non-null object -> return object (only if in null safe mode and type is
//   non-nullable Object).
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
//
// Inputs (preserved):
// - TypeTestABI::kInstanceReg: object.
// - TypeTestABI::kInstantiatorTypeArgumentsReg: instantiator type arguments.
// - TypeTestABI::kFunctionTypeArgumentsReg: function type arguments.
//
// Assumes:
// - Destination type is not a top type.
// - Object to check is not null, unless in null safe mode and destination type
//   is not a nullable type.
//
// Outputs:
// - TypeTestABI::kDstTypeReg: destination type
// Additional output if dst_type is a TypeParameter:
// - TypeTestABI::kScratchReg: type on which to call TTS stub.
//
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void FlowGraphCompiler::GenerateCallerChecksForAssertAssignable(
    CompileType* receiver_type,
    const AbstractType& dst_type,
    compiler::Label* done) {
  // Top types should be handled by the caller and cannot reach here.
  ASSERT(!dst_type.IsTopTypeForSubtyping());

  // Set this to avoid marking the type testing stub for optimization.
  bool elide_info = false;
  // Call before any return points to set the destination type register and
  // mark the destination type TTS as needing optimization, unless it is
  // unlikely to be called.
  auto output_dst_type = [&]() -> void {
    // If we haven't handled the positive case of the type check on the call
    // site and we'll be using the TTS of the destination type, we want an
    // optimized type testing stub and thus record it in the [TypeUsageInfo].
    if (!elide_info) {
      if (auto const type_usage_info = thread()->type_usage_info()) {
        type_usage_info->UseTypeInAssertAssignable(dst_type);
      } else {
        ASSERT(!FLAG_precompiled_mode);
      }
    }
    __ LoadObject(TypeTestABI::kDstTypeReg, dst_type);
  };

  // We can handle certain types and checks very efficiently on the call site,
  // meaning those need not be checked within the stubs (which may involve
  // a runtime call).

  if (dst_type.IsObjectType()) {
    // Special case: non-nullable Object.
    ASSERT(dst_type.IsNonNullable() &&
           isolate()->use_strict_null_safety_checks());
    __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
    __ BranchIf(NOT_EQUAL, done);
    // Fall back to type testing stub in caller to throw the exception.
    return output_dst_type();
  }

  // If the int type is assignable to [dst_type] we special case it on the
  // caller side!
  const Type& int_type = Type::Handle(zone(), Type::IntType());
  bool is_non_smi = false;
  if (int_type.IsSubtypeOf(dst_type, Heap::kOld)) {
    __ BranchIfSmi(TypeTestABI::kInstanceReg, done);
    is_non_smi = true;
  } else if (!receiver_type->CanBeSmi()) {
    is_non_smi = true;
  }

  if (dst_type.IsTypeParameter()) {
    // Special case: Instantiate the type parameter on the caller side, invoking
    // the TTS of the corresponding type parameter in the caller.
    const TypeParameter& type_param = TypeParameter::Cast(dst_type);
    if (isolate()->use_strict_null_safety_checks() &&
        !type_param.IsNonNullable()) {
      // If the type parameter is nullable when running in strong mode, we need
      // to handle null before calling the TTS because the type parameter may be
      // instantiated with a non-nullable type, where the TTS rejects null.
      __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
      __ BranchIf(EQUAL, done);
    }
    const Register kTypeArgumentsReg =
        type_param.IsClassTypeParameter()
            ? TypeTestABI::kInstantiatorTypeArgumentsReg
            : TypeTestABI::kFunctionTypeArgumentsReg;

    // Check if type arguments are null, i.e. equivalent to vector of dynamic.
    // If so, then the value is guaranteed assignable as dynamic is a top type.
    __ CompareObject(kTypeArgumentsReg, Object::null_object());
    __ BranchIf(EQUAL, done);
    // Put the instantiated type parameter into the scratch register, so its
    // TTS can be called by the caller.
    __ LoadField(
        TypeTestABI::kScratchReg,
        compiler::FieldAddress(kTypeArgumentsReg,
                               compiler::target::TypeArguments::type_at_offset(
                                   type_param.index())));
    return output_dst_type();
  }

  if (auto const hi = thread()->hierarchy_info()) {
    const Class& type_class = Class::Handle(zone(), dst_type.type_class());

    if (hi->CanUseSubtypeRangeCheckFor(dst_type)) {
      const CidRangeVector& ranges = hi->SubtypeRangesForClass(
          type_class,
          /*include_abstract=*/false,
          /*exclude_null=*/!Instance::NullIsAssignableTo(dst_type));
      if (ranges.length() <= kMaxNumberOfCidRangesToTest) {
        if (is_non_smi) {
          __ LoadClassId(TypeTestABI::kScratchReg, TypeTestABI::kInstanceReg);
        } else {
          __ LoadClassIdMayBeSmi(TypeTestABI::kScratchReg,
                                 TypeTestABI::kInstanceReg);
        }
        GenerateCidRangesCheck(assembler(), TypeTestABI::kScratchReg, ranges,
                               done);
        elide_info = true;
      } else if (IsListClass(type_class)) {
        __ LoadClassIdMayBeSmi(TypeTestABI::kScratchReg,
                               TypeTestABI::kInstanceReg);
        GenerateListTypeCheck(TypeTestABI::kScratchReg, done);
      }
    }
  }
  output_dst_type();
}
#endif  // !defined(TARGET_ARCH_IA32)

#undef __

#if defined(DEBUG)
void FlowGraphCompiler::FrameStateUpdateWith(Instruction* instr) {
  ASSERT(!is_optimizing());

  switch (instr->tag()) {
    case Instruction::kPushArgument:
      // Do nothing.
      break;

    case Instruction::kDropTemps:
      FrameStatePop(instr->locs()->input_count() +
                    instr->AsDropTemps()->num_temps());
      break;

    default:
      FrameStatePop(instr->locs()->input_count());
      break;
  }

  ASSERT(!instr->locs()->can_call() || FrameStateIsSafeToCall());

  FrameStatePop(instr->ArgumentCount());
  Definition* defn = instr->AsDefinition();
  if ((defn != NULL) && defn->HasTemp()) {
    FrameStatePush(defn);
  }
}

void FlowGraphCompiler::FrameStatePush(Definition* defn) {
  Representation rep = defn->representation();
  if ((rep == kUnboxedDouble) || (rep == kUnboxedFloat64x2) ||
      (rep == kUnboxedFloat32x4)) {
    // The LoadField instruction may lie about its representation in unoptimized
    // code for Dart fields because Definition::representation() can't depend on
    // the type of compilation but MakeLocationSummary and EmitNativeCode can.
    ASSERT(defn->IsLoadField() &&
           defn->AsLoadField()->IsUnboxedDartFieldLoad());
    ASSERT(defn->locs()->out(0).IsRegister());
    rep = kTagged;
  }
  ASSERT(!is_optimizing());
  ASSERT((rep == kTagged) || (rep == kUntagged) || (rep == kUnboxedUint32) ||
         (rep == kUnboxedUint8));
  ASSERT(rep != kUntagged || flow_graph_.IsIrregexpFunction());
  const auto& function = flow_graph_.parsed_function().function();
  // Currently, we only allow unboxed uint8 and uint32 on the stack in
  // unoptimized code  when building a dynamic closure call dispatcher, where
  // any unboxed values on the stack are consumed before possible
  // FrameStateIsSafeToCall() checks.
  // See FlowGraphBuilder::BuildDynamicCallVarsInit().
  ASSERT((rep != kUnboxedUint32 && rep != kUnboxedUint8) ||
         function.IsDynamicClosureCallDispatcher(thread()));
  frame_state_.Add(rep);
}

void FlowGraphCompiler::FrameStatePop(intptr_t count) {
  ASSERT(!is_optimizing());
  frame_state_.TruncateTo(
      Utils::Maximum(static_cast<intptr_t>(0), frame_state_.length() - count));
}

bool FlowGraphCompiler::FrameStateIsSafeToCall() {
  ASSERT(!is_optimizing());
  for (intptr_t i = 0; i < frame_state_.length(); i++) {
    if (frame_state_[i] != kTagged) {
      return false;
    }
  }
  return true;
}

void FlowGraphCompiler::FrameStateClear() {
  ASSERT(!is_optimizing());
  frame_state_.TruncateTo(0);
}
#endif  // defined(DEBUG)

#define __ compiler->assembler()->

void ThrowErrorSlowPathCode::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (compiler::Assembler::EmittingComments()) {
    __ Comment("slow path %s operation", name());
  }
  const bool use_shared_stub =
      instruction()->UseSharedSlowPathStub(compiler->is_optimizing());
  ASSERT(use_shared_stub == instruction()->locs()->call_on_shared_slow_path());
  const bool live_fpu_registers =
      instruction()->locs()->live_registers()->FpuRegisterCount() > 0;
  const intptr_t num_args =
      use_shared_stub ? 0 : GetNumberOfArgumentsForRuntimeCall();
  __ Bind(entry_label());
  EmitCodeAtSlowPathEntry(compiler);
  LocationSummary* locs = instruction()->locs();
  // Save registers as they are needed for lazy deopt / exception handling.
  if (use_shared_stub) {
    EmitSharedStubCall(compiler, live_fpu_registers);
  } else {
    compiler->SaveLiveRegisters(locs);
    PushArgumentsForRuntimeCall(compiler);
    __ CallRuntime(runtime_entry_, num_args);
  }
  const intptr_t deopt_id = instruction()->deopt_id();
  compiler->AddDescriptor(PcDescriptorsLayout::kOther,
                          compiler->assembler()->CodeSize(), deopt_id,
                          instruction()->source(), try_index_);
  AddMetadataForRuntimeCall(compiler);
  compiler->RecordSafepoint(locs, num_args);
  if (!FLAG_precompiled_mode || (try_index_ != kInvalidTryIndex) ||
      (compiler->CurrentTryIndex() != kInvalidTryIndex)) {
    Environment* env =
        compiler->SlowPathEnvironmentFor(instruction(), num_args);
    if (FLAG_precompiled_mode) {
      compiler->RecordCatchEntryMoves(env, try_index_);
    } else if (env != nullptr) {
      compiler->AddSlowPathDeoptInfo(deopt_id, env);
    }
  }
  if (!use_shared_stub) {
    __ Breakpoint();
  }
}

const char* NullErrorSlowPath::name() {
  switch (exception_type()) {
    case CheckNullInstr::kNoSuchMethod:
      return "check null (nsm)";
    case CheckNullInstr::kArgumentError:
      return "check null (arg)";
    case CheckNullInstr::kCastError:
      return "check null (cast)";
  }
  UNREACHABLE();
}

const RuntimeEntry& NullErrorSlowPath::GetRuntimeEntry(
    CheckNullInstr::ExceptionType exception_type) {
  switch (exception_type) {
    case CheckNullInstr::kNoSuchMethod:
      return kNullErrorRuntimeEntry;
    case CheckNullInstr::kArgumentError:
      return kArgumentNullErrorRuntimeEntry;
    case CheckNullInstr::kCastError:
      return kNullCastErrorRuntimeEntry;
  }
  UNREACHABLE();
}

CodePtr NullErrorSlowPath::GetStub(FlowGraphCompiler* compiler,
                                   CheckNullInstr::ExceptionType exception_type,
                                   bool save_fpu_registers) {
  auto object_store = compiler->isolate()->object_store();
  switch (exception_type) {
    case CheckNullInstr::kNoSuchMethod:
      return save_fpu_registers
                 ? object_store->null_error_stub_with_fpu_regs_stub()
                 : object_store->null_error_stub_without_fpu_regs_stub();
    case CheckNullInstr::kArgumentError:
      return save_fpu_registers
                 ? object_store->null_arg_error_stub_with_fpu_regs_stub()
                 : object_store->null_arg_error_stub_without_fpu_regs_stub();
    case CheckNullInstr::kCastError:
      return save_fpu_registers
                 ? object_store->null_cast_error_stub_with_fpu_regs_stub()
                 : object_store->null_cast_error_stub_without_fpu_regs_stub();
  }
  UNREACHABLE();
}

void NullErrorSlowPath::EmitSharedStubCall(FlowGraphCompiler* compiler,
                                           bool save_fpu_registers) {
#if defined(TARGET_ARCH_IA32)
  UNREACHABLE();
#else
  const auto& stub =
      Code::ZoneHandle(compiler->zone(),
                       GetStub(compiler, exception_type(), save_fpu_registers));
  compiler->EmitCallToStub(stub);
#endif
}

void RangeErrorSlowPath::PushArgumentsForRuntimeCall(
    FlowGraphCompiler* compiler) {
  LocationSummary* locs = instruction()->locs();
  __ PushRegisterPair(locs->in(CheckBoundBase::kIndexPos).reg(),
                      locs->in(CheckBoundBase::kLengthPos).reg());
}

void LateInitializationErrorSlowPath::PushArgumentsForRuntimeCall(
    FlowGraphCompiler* compiler) {
  const Field& original_field = Field::ZoneHandle(
      instruction()->AsLoadField()->slot().field().Original());
  __ PushObject(original_field);
}

void LateInitializationErrorSlowPath::EmitSharedStubCall(
    FlowGraphCompiler* compiler,
    bool save_fpu_registers) {
#if defined(TARGET_ARCH_IA32)
  UNREACHABLE();
#else
  ASSERT(instruction()->locs()->temp(0).reg() ==
         LateInitializationErrorABI::kFieldReg);
  const Field& original_field = Field::ZoneHandle(
      instruction()->AsLoadField()->slot().field().Original());
  __ LoadObject(LateInitializationErrorABI::kFieldReg, original_field);
  auto object_store = compiler->isolate()->object_store();
  const auto& stub = Code::ZoneHandle(
      compiler->zone(),
      save_fpu_registers
          ? object_store->late_initialization_error_stub_with_fpu_regs_stub()
          : object_store
                ->late_initialization_error_stub_without_fpu_regs_stub());
  compiler->EmitCallToStub(stub);
#endif
}

void FlowGraphCompiler::EmitNativeMove(
    const compiler::ffi::NativeLocation& destination,
    const compiler::ffi::NativeLocation& source,
    TemporaryRegisterAllocator* temp) {
  const auto& src_payload_type = source.payload_type();
  const auto& dst_payload_type = destination.payload_type();
  const auto& src_container_type = source.container_type();
  const auto& dst_container_type = destination.container_type();
  const intptr_t src_payload_size = src_payload_type.SizeInBytes();
  const intptr_t dst_payload_size = dst_payload_type.SizeInBytes();
  const intptr_t src_container_size = src_container_type.SizeInBytes();
  const intptr_t dst_container_size = dst_container_type.SizeInBytes();

  // This function does not know how to do larger mem copy moves yet.
  ASSERT(src_payload_type.IsPrimitive());
  ASSERT(dst_payload_type.IsPrimitive());

  // This function does not deal with sign conversions yet.
  ASSERT(src_payload_type.IsSigned() == dst_payload_type.IsSigned());

  // This function does not deal with bit casts yet.
  ASSERT(src_container_type.IsFloat() == dst_container_type.IsFloat());
  ASSERT(src_container_type.IsInt() == dst_container_type.IsInt());

  // If the location, payload, and container are equal, we're done.
  if (source.Equals(destination) && src_payload_type.Equals(dst_payload_type) &&
      src_container_type.Equals(dst_container_type)) {
    return;
  }

  // Solve descrepancies between container size and payload size.
  if (src_payload_type.IsInt() && dst_payload_type.IsInt() &&
      (src_payload_size != src_container_size ||
       dst_payload_size != dst_container_size)) {
    if (src_payload_size <= dst_payload_size &&
        src_container_size >= dst_container_size) {
      // The upper bits of the source are already properly sign or zero
      // extended, so just copy the required amount of bits.
      return EmitNativeMove(destination.WithOtherNativeType(
                                zone_, dst_container_type, dst_container_type),
                            source.WithOtherNativeType(
                                zone_, dst_container_type, dst_container_type),
                            temp);
    }
    if (src_payload_size >= dst_payload_size &&
        dst_container_size > dst_payload_size) {
      // The upper bits of the source are not properly sign or zero extended
      // to be copied to the target, so regard the source as smaller.
      return EmitNativeMove(
          destination.WithOtherNativeType(zone_, dst_container_type,
                                          dst_container_type),
          source.WithOtherNativeType(zone_, dst_payload_type, dst_payload_type),
          temp);
    }
    UNREACHABLE();
  }
  ASSERT(src_payload_size == src_container_size);
  ASSERT(dst_payload_size == dst_container_size);

  // Split moves that are larger than kWordSize, these require separate
  // instructions on all architectures.
  if (compiler::target::kWordSize == 4 && src_container_size == 8 &&
      dst_container_size == 8 && !source.IsFpuRegisters() &&
      !destination.IsFpuRegisters()) {
    // TODO(40209): If this is stack to stack, we could use FpuTMP.
    // Test the impact on code size and speed.
    EmitNativeMove(destination.Split(zone_, 2, 0), source.Split(zone_, 2, 0),
                   temp);
    EmitNativeMove(destination.Split(zone_, 2, 1), source.Split(zone_, 2, 1),
                   temp);
    return;
  }

  // Split moves from stack to stack, none of the architectures provides
  // memory to memory move instructions.
  if (source.IsStack() && destination.IsStack()) {
    Register scratch = TMP;
    if (TMP == kNoRegister) {
      scratch = temp->AllocateTemporary();
    }
    const auto& intermediate =
        *new (zone_) compiler::ffi::NativeRegistersLocation(
            zone_, dst_payload_type, dst_container_type, scratch);
    EmitNativeMove(intermediate, source, temp);
    EmitNativeMove(destination, intermediate, temp);
    if (TMP == kNoRegister) {
      temp->ReleaseTemporary();
    }
    return;
  }

  const bool sign_or_zero_extend = dst_container_size > src_container_size;

  // No architecture supports sign extending with memory as destination.
  if (sign_or_zero_extend && destination.IsStack()) {
    ASSERT(source.IsRegisters());
    const auto& intermediate =
        source.WithOtherNativeType(zone_, dst_payload_type, dst_container_type);
    EmitNativeMove(intermediate, source, temp);
    EmitNativeMove(destination, intermediate, temp);
    return;
  }

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  // Arm does not support sign extending from a memory location, x86 does.
  if (sign_or_zero_extend && source.IsStack()) {
    ASSERT(destination.IsRegisters());
    const auto& intermediate = destination.WithOtherNativeType(
        zone_, src_payload_type, src_container_type);
    EmitNativeMove(intermediate, source, temp);
    EmitNativeMove(destination, intermediate, temp);
    return;
  }
#endif

  // If we're not sign extending, and we're moving 8 or 16 bits into a
  // register, upgrade the move to take upper bits of garbage from the
  // source location. This is the same as leaving the previous garbage in
  // there.
  //
  // TODO(40210): If our assemblers would support moving 1 and 2 bytes into
  // registers, this code can be removed.
  if (!sign_or_zero_extend && destination.IsRegisters() &&
      destination.container_type().SizeInBytes() <= 2) {
    ASSERT(source.payload_type().IsInt());
    return EmitNativeMove(destination.WidenTo4Bytes(zone_),
                          source.WidenTo4Bytes(zone_), temp);
  }

  // Do the simple architecture specific moves.
  EmitNativeMoveArchitecture(destination, source);
}

void FlowGraphCompiler::EmitMoveToNative(
    const compiler::ffi::NativeLocation& dst,
    Location src_loc,
    Representation src_type,
    TemporaryRegisterAllocator* temp) {
  if (src_loc.IsPairLocation()) {
    for (intptr_t i : {0, 1}) {
      const auto& src_split = compiler::ffi::NativeLocation::FromPairLocation(
          zone_, src_loc, src_type, i);
      EmitNativeMove(dst.Split(zone_, 2, i), src_split, temp);
    }
  } else {
    const auto& src =
        compiler::ffi::NativeLocation::FromLocation(zone_, src_loc, src_type);
    EmitNativeMove(dst, src, temp);
  }
}

void FlowGraphCompiler::EmitMoveFromNative(
    Location dst_loc,
    Representation dst_type,
    const compiler::ffi::NativeLocation& src,
    TemporaryRegisterAllocator* temp) {
  if (dst_loc.IsPairLocation()) {
    for (intptr_t i : {0, 1}) {
      const auto& dest_split = compiler::ffi::NativeLocation::FromPairLocation(
          zone_, dst_loc, dst_type, i);
      EmitNativeMove(dest_split, src.Split(zone_, 2, i), temp);
    }
  } else {
    const auto& dest =
        compiler::ffi::NativeLocation::FromLocation(zone_, dst_loc, dst_type);
    EmitNativeMove(dest, src, temp);
  }
}

void FlowGraphCompiler::EmitMoveConst(const compiler::ffi::NativeLocation& dst,
                                      Location src,
                                      Representation src_type,
                                      TemporaryRegisterAllocator* temp) {
  ASSERT(src.IsConstant());
  const auto& dst_type = dst.payload_type();
  if (dst.IsExpressibleAsLocation() &&
      dst_type.IsExpressibleAsRepresentation() &&
      dst_type.AsRepresentationOverApprox(zone_) == src_type) {
    // We can directly emit the const in the right place and representation.
    const Location dst_loc = dst.AsLocation();
    EmitMove(dst_loc, src, temp);
  } else {
    // We need an intermediate location.
    Location intermediate;
    if (dst_type.IsInt()) {
      if (TMP == kNoRegister) {
        Register scratch = temp->AllocateTemporary();
        Location::RegisterLocation(scratch);
      } else {
        intermediate = Location::RegisterLocation(TMP);
      }
    } else {
      ASSERT(dst_type.IsFloat());
      intermediate = Location::FpuRegisterLocation(FpuTMP);
    }

    if (src.IsPairLocation()) {
      for (intptr_t i : {0, 1}) {
        const Representation src_type_split =
            compiler::ffi::NativeType::FromUnboxedRepresentation(zone_,
                                                                 src_type)
                .Split(zone_, i)
                .AsRepresentation();
        const auto& intermediate_native =
            compiler::ffi::NativeLocation::FromLocation(zone_, intermediate,
                                                        src_type_split);
        EmitMove(intermediate, src.AsPairLocation()->At(i), temp);
        EmitNativeMove(dst.Split(zone_, 2, i), intermediate_native, temp);
      }
    } else {
      const auto& intermediate_native =
          compiler::ffi::NativeLocation::FromLocation(zone_, intermediate,
                                                      src_type);
      EmitMove(intermediate, src, temp);
      EmitNativeMove(dst, intermediate_native, temp);
    }

    if (dst_type.IsInt() && TMP == kNoRegister) {
      temp->ReleaseTemporary();
    }
  }
  return;
}

// The assignment to loading units here must match that in
// AssignLoadingUnitsCodeVisitor, which runs after compilation is done.
static intptr_t LoadingUnitOf(Zone* zone, const Function& function) {
  const Class& cls = Class::Handle(zone, function.Owner());
  const Library& lib = Library::Handle(zone, cls.library());
  const LoadingUnit& unit = LoadingUnit::Handle(zone, lib.loading_unit());
  ASSERT(!unit.IsNull());
  return unit.id();
}

static intptr_t LoadingUnitOf(Zone* zone, const Code& code) {
  // No WeakSerializationReference owners here because those are only
  // introduced during AOT serialization.
  if (code.IsStubCode() || code.IsTypeTestStubCode()) {
    return LoadingUnit::kRootId;
  } else if (code.IsAllocationStubCode()) {
    const Class& cls = Class::Cast(Object::Handle(zone, code.owner()));
    const Library& lib = Library::Handle(zone, cls.library());
    const LoadingUnit& unit = LoadingUnit::Handle(zone, lib.loading_unit());
    ASSERT(!unit.IsNull());
    return unit.id();
  } else if (code.IsFunctionCode()) {
    return LoadingUnitOf(zone,
                         Function::Cast(Object::Handle(zone, code.owner())));
  } else {
    UNREACHABLE();
    return LoadingUnit::kIllegalId;
  }
}

bool FlowGraphCompiler::CanPcRelativeCall(const Function& target) const {
  return FLAG_precompiled_mode && FLAG_use_bare_instructions &&
         (LoadingUnitOf(zone_, function()) == LoadingUnitOf(zone_, target));
}

bool FlowGraphCompiler::CanPcRelativeCall(const Code& target) const {
  return FLAG_precompiled_mode && FLAG_use_bare_instructions &&
         !target.InVMIsolateHeap() &&
         (LoadingUnitOf(zone_, function()) == LoadingUnitOf(zone_, target));
}

bool FlowGraphCompiler::CanPcRelativeCall(const AbstractType& target) const {
  return FLAG_precompiled_mode && FLAG_use_bare_instructions &&
         !target.InVMIsolateHeap() &&
         (LoadingUnitOf(zone_, function()) == LoadingUnit::kRootId);
}

#undef __

}  // namespace dart
