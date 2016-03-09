// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_XXX.

#include "vm/flow_graph_compiler.h"

#include "vm/bit_vector.h"
#include "vm/cha.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/flow_graph_allocator.h"
#include "vm/il_printer.h"
#include "vm/intrinsifier.h"
#include "vm/locations.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/timeline.h"

namespace dart {

DEFINE_FLAG(bool, enable_simd_inline, true,
    "Enable inlining of SIMD related method calls.");
DEFINE_FLAG(int, min_optimization_counter_threshold, 5000,
    "The minimum invocation count for a function.");
DEFINE_FLAG(int, optimization_counter_scale, 2000,
    "The scale of invocation count, by size of the function.");
DEFINE_FLAG(bool, source_lines, false, "Emit source line as assembly comment.");
DEFINE_FLAG(bool, trace_inlining_intervals, false,
    "Inlining interval diagnostics");
DEFINE_FLAG(bool, use_megamorphic_stub, true, "Out of line megamorphic lookup");

DECLARE_FLAG(bool, code_comments);
DECLARE_FLAG(charp, deoptimize_filter);
DECLARE_FLAG(bool, intrinsify);
DECLARE_FLAG(bool, propagate_ic_data);
DECLARE_FLAG(int, regexp_optimization_counter_threshold);
DECLARE_FLAG(int, reoptimization_counter_threshold);
DECLARE_FLAG(int, stacktrace_every);
DECLARE_FLAG(charp, stacktrace_filter);
DECLARE_FLAG(bool, trace_compiler);
DECLARE_FLAG(int, inlining_hotness);
DECLARE_FLAG(int, inlining_size_threshold);
DECLARE_FLAG(int, inlining_callee_size_threshold);
DECLARE_FLAG(int, inline_getters_setters_smaller_than);
DECLARE_FLAG(int, inlining_depth_threshold);
DECLARE_FLAG(int, inlining_caller_size_threshold);
DECLARE_FLAG(int, inlining_constant_arguments_max_size_threshold);
DECLARE_FLAG(int, inlining_constant_arguments_min_size_threshold);

static void PrecompilationModeHandler(bool value) {
  if (value) {
#if defined(TARGET_ARCH_IA32)
    FATAL("Precompilation not supported on IA32");
#endif

    // Flags affecting compilation only:
    // There is no counter feedback in precompilation, so ignore the counter
    // when making inlining decisions.
    FLAG_inlining_hotness = 0;
    // Use smaller thresholds in precompilation as we are compiling everything
    // with the optimizing compiler instead of only hot functions.
    FLAG_inlining_size_threshold = 5;
    FLAG_inline_getters_setters_smaller_than = 5;
    FLAG_inlining_callee_size_threshold = 20;
    FLAG_inlining_depth_threshold = 2;
    FLAG_inlining_caller_size_threshold = 1000;
    FLAG_inlining_constant_arguments_max_size_threshold = 100;
    FLAG_inlining_constant_arguments_min_size_threshold = 30;

    FLAG_allow_absolute_addresses = false;
    FLAG_always_megamorphic_calls = true;
    FLAG_collect_dynamic_function_names = true;
    FLAG_fields_may_be_reset = true;
    FLAG_ic_range_profiling = false;
    FLAG_interpret_irregexp = true;
    FLAG_lazy_dispatchers = false;
    FLAG_link_natives_lazily = true;
    FLAG_optimization_counter_threshold = -1;
    FLAG_polymorphic_with_deopt = false;
    FLAG_precompiled_mode = true;
    FLAG_reorder_basic_blocks = false;
    FLAG_use_field_guards = false;
    FLAG_use_cha_deopt = false;

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
    // Set flags affecting runtime accordingly for dart_noopt.
    FLAG_background_compilation = false;
    FLAG_collect_code = false;
    FLAG_support_debugger = false;
    FLAG_deoptimize_alot = false;  // Used in some tests.
    FLAG_deoptimize_every = 0;     // Used in some tests.
    FLAG_enable_mirrors = false;
    FLAG_load_deferred_eagerly = true;
    FLAG_print_stop_message = false;
    FLAG_use_osr = false;
#endif
  }
}

DEFINE_FLAG_HANDLER(PrecompilationModeHandler,
                    precompilation,
                    "Precompilation mode");

#ifdef DART_PRECOMPILED_RUNTIME

COMPILE_ASSERT(!FLAG_background_compilation);
COMPILE_ASSERT(!FLAG_collect_code);
COMPILE_ASSERT(!FLAG_deoptimize_alot);  // Used in some tests.
COMPILE_ASSERT(!FLAG_enable_mirrors);
COMPILE_ASSERT(FLAG_precompiled_runtime);
COMPILE_ASSERT(!FLAG_print_stop_message);
COMPILE_ASSERT(!FLAG_use_osr);
COMPILE_ASSERT(FLAG_deoptimize_every == 0);  // Used in some tests.
COMPILE_ASSERT(FLAG_load_deferred_eagerly);

#endif  // DART_PRECOMPILED_RUNTIME


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
      it.SetCurrentLocation(Location::StackSlot((*stack_height)++));
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
    Assembler* assembler,
    FlowGraph* flow_graph,
    const ParsedFunction& parsed_function,
    bool is_optimizing,
    const GrowableArray<const Function*>& inline_id_to_function,
    const GrowableArray<TokenPosition>& inline_id_to_token_pos,
    const GrowableArray<intptr_t>& caller_inline_id)
      : thread_(Thread::Current()),
        zone_(Thread::Current()->zone()),
        assembler_(assembler),
        parsed_function_(parsed_function),
        flow_graph_(*flow_graph),
        block_order_(*flow_graph->CodegenBlockOrder(is_optimizing)),
        current_block_(NULL),
        exception_handlers_list_(NULL),
        pc_descriptors_list_(NULL),
        stackmap_table_builder_(NULL),
        code_source_map_builder_(NULL),
        saved_code_size_(0),
        block_info_(block_order_.length()),
        deopt_infos_(),
        static_calls_target_table_(),
        is_optimizing_(is_optimizing),
        may_reoptimize_(false),
        intrinsic_mode_(false),
        double_class_(Class::ZoneHandle(
            isolate()->object_store()->double_class())),
        mint_class_(Class::ZoneHandle(
            isolate()->object_store()->mint_class())),
        float32x4_class_(Class::ZoneHandle(
            isolate()->object_store()->float32x4_class())),
        float64x2_class_(Class::ZoneHandle(
            isolate()->object_store()->float64x2_class())),
        int32x4_class_(Class::ZoneHandle(
            isolate()->object_store()->int32x4_class())),
        list_class_(Class::ZoneHandle(
            Library::Handle(Library::CoreLibrary()).
                LookupClass(Symbols::List()))),
        parallel_move_resolver_(this),
        pending_deoptimization_env_(NULL),
        lazy_deopt_pc_offset_(Code::kInvalidPc),
        deopt_id_to_ic_data_(NULL),
        edge_counters_array_(Array::ZoneHandle()),
        inlined_code_intervals_(Array::ZoneHandle(Object::empty_array().raw())),
        inline_id_to_function_(inline_id_to_function),
        inline_id_to_token_pos_(inline_id_to_token_pos),
        caller_inline_id_(caller_inline_id) {
  ASSERT(flow_graph->parsed_function().function().raw() ==
         parsed_function.function().raw());
  if (!is_optimizing) {
    const intptr_t len = thread()->deopt_id();
    deopt_id_to_ic_data_ = new(zone()) ZoneGrowableArray<const ICData*>(len);
    deopt_id_to_ic_data_->SetLength(len);
    for (intptr_t i = 0; i < len; i++) {
      (*deopt_id_to_ic_data_)[i] = NULL;
    }
    // TODO(fschneider): Abstract iteration into ICDataArrayIterator.
    const Array& old_saved_ic_data = Array::Handle(zone(),
        flow_graph->function().ic_data_array());
    const intptr_t saved_len =
        old_saved_ic_data.IsNull() ? 0 : old_saved_ic_data.Length();
    for (intptr_t i = 1; i < saved_len; i++) {
      ICData& ic_data = ICData::ZoneHandle(zone());
      ic_data ^= old_saved_ic_data.At(i);
      (*deopt_id_to_ic_data_)[ic_data.deopt_id()] = &ic_data;
    }
  }
  ASSERT(assembler != NULL);
  ASSERT(!list_class_.IsNull());
}


bool FlowGraphCompiler::IsUnboxedField(const Field& field) {
  bool valid_class = (SupportsUnboxedDoubles() &&
                      (field.guarded_cid() == kDoubleCid)) ||
                     (SupportsUnboxedSimd128() &&
                      (field.guarded_cid() == kFloat32x4Cid)) ||
                     (SupportsUnboxedSimd128() &&
                      (field.guarded_cid() == kFloat64x2Cid));
  return field.is_unboxing_candidate()
      && !field.is_final()
      && !field.is_nullable()
      && valid_class;
}


bool FlowGraphCompiler::IsPotentialUnboxedField(const Field& field) {
  return field.is_unboxing_candidate() &&
         (FlowGraphCompiler::IsUnboxedField(field) ||
          (!field.is_final() && (field.guarded_cid() == kIllegalCid)));
}


void FlowGraphCompiler::InitCompiler() {
#ifndef PRODUCT
  TimelineDurationScope tds(thread(),
                            isolate()->GetCompilerStream(),
                            "InitCompiler");
#endif  // !PRODUCT
  pc_descriptors_list_ = new(zone()) DescriptorList(64);
  exception_handlers_list_ = new(zone()) ExceptionHandlerList();
  block_info_.Clear();
  // Conservative detection of leaf routines used to remove the stack check
  // on function entry.
  bool is_leaf = is_optimizing() && !flow_graph().IsCompiledForOsr();
  // Initialize block info and search optimized (non-OSR) code for calls
  // indicating a non-leaf routine and calls without IC data indicating
  // possible reoptimization.
  for (int i = 0; i < block_order_.length(); ++i) {
    block_info_.Add(new(zone()) BlockInfo());
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
        if (is_leaf &&
            !current->IsCheckStackOverflow() &&
            !current->IsParallelMove()) {
          // Note that we do not care if the code contains instructions that
          // can deoptimize.
          LocationSummary* locs = current->locs();
          if ((locs != NULL) && locs->can_call()) {
            is_leaf = false;
          }
        }
      }
    }
  }
  if (is_leaf) {
    // Remove the stack overflow check at function entry.
    Instruction* first = flow_graph_.graph_entry()->normal_entry()->next();
    if (first->IsCheckStackOverflow()) first->RemoveFromGraph();
  }
  if (!is_optimizing()) {
    // Initialize edge counter array.
    const intptr_t num_counters = flow_graph_.preorder().length();
    const Array& edge_counters =
        Array::Handle(Array::New(num_counters, Heap::kOld));
    const Smi& zero_smi = Smi::Handle(Smi::New(0));
    for (intptr_t i = 0; i < num_counters; ++i) {
      edge_counters.SetAt(i, zero_smi);
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
  return FLAG_use_osr & CanOptimizeFunction() && !is_optimizing();
}


bool FlowGraphCompiler::ForceSlowPathForStackOverflow() const {
  if (FLAG_stacktrace_every > 0 || FLAG_deoptimize_every > 0) {
    return true;
  }
  if (FLAG_stacktrace_filter != NULL &&
      strstr(parsed_function().function().ToFullyQualifiedCString(),
             FLAG_stacktrace_filter) != NULL) {
    return true;
  }
  if (is_optimizing() &&
      FLAG_deoptimize_filter != NULL &&
      strstr(parsed_function().function().ToFullyQualifiedCString(),
             FLAG_deoptimize_filter) != NULL) {
    return true;
  }
  return false;
}


static bool IsEmptyBlock(BlockEntryInstr* block) {
  return !block->IsCatchBlockEntry() &&
         !block->HasNonRedundantParallelMove() &&
         block->next()->IsGoto() &&
         !block->next()->AsGoto()->HasNonRedundantParallelMove() &&
         !block->IsIndirectEntry();
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
  Label* nonempty_label = NULL;
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


void FlowGraphCompiler::EmitInstructionPrologue(Instruction* instr) {
  if (!is_optimizing()) {
    if (instr->CanBecomeDeoptimizationTarget() && !instr->IsGoto()) {
      // Instructions that can be deoptimization targets need to record kDeopt
      // PcDescriptor corresponding to their deopt id. GotoInstr records its
      // own so that it can control the placement.
      AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                           instr->deopt_id(),
                           instr->token_pos());
    }
    AllocateRegistersLocally(instr);
  } else if (instr->MayThrow()  &&
             (CurrentTryIndex() != CatchClauseNode::kInvalidTryIndex)) {
    // Optimized try-block: Sync locals to fixed stack locations.
    EmitTrySync(instr, CurrentTryIndex());
  }
}



void FlowGraphCompiler::EmitSourceLine(Instruction* instr) {
  if (!instr->token_pos().IsReal() || (instr->env() == NULL)) {
    return;
  }
  const Script& script =
      Script::Handle(zone(), instr->env()->function().script());
  intptr_t line_nr;
  intptr_t column_nr;
  script.GetTokenLocation(instr->token_pos(), &line_nr, &column_nr);
  const String& line = String::Handle(zone(), script.GetLine(line_nr));
  assembler()->Comment("Line %" Pd " in '%s':\n           %s",
      line_nr,
      instr->env()->function().ToFullyQualifiedCString(),
      line.ToCString());
}


static void LoopInfoComment(
    Assembler* assembler,
    const BlockEntryInstr& block,
    const ZoneGrowableArray<BlockEntryInstr*>& loop_headers) {
  if (Assembler::EmittingComments()) {
    for (intptr_t loop_id = 0; loop_id < loop_headers.length(); ++loop_id) {
      for (BitVector::Iterator loop_it(loop_headers[loop_id]->loop_info());
           !loop_it.Done();
           loop_it.Advance()) {
        if (loop_it.Current() == block.preorder_number()) {
           assembler->Comment("  Loop %" Pd "", loop_id);
        }
      }
    }
  }
}


// We collect intervals while generating code.
struct IntervalStruct {
  // 'start' is the pc-offsets where the inlined code started.
  // 'pos' is the token position where the inlined call occured.
  intptr_t start;
  TokenPosition pos;
  intptr_t inlining_id;
  IntervalStruct(intptr_t s, TokenPosition tp, intptr_t id)
      : start(s), pos(tp), inlining_id(id) {}
  void Dump() {
    THR_Print("start: 0x%" Px " iid: %" Pd " pos: %s",
              start, inlining_id, pos.ToCString());
  }
};


void FlowGraphCompiler::VisitBlocks() {
  CompactBlocks();
  const ZoneGrowableArray<BlockEntryInstr*>* loop_headers = NULL;
  if (Assembler::EmittingComments()) {
    // 'loop_headers' were cleared, recompute.
    loop_headers = flow_graph().ComputeLoops();
    ASSERT(loop_headers != NULL);
  }

  // For collecting intervals of inlined code.
  GrowableArray<IntervalStruct> intervals;
  intptr_t prev_offset = 0;
  intptr_t prev_inlining_id = 0;
  TokenPosition prev_inlining_pos = parsed_function_.function().token_pos();
  intptr_t max_inlining_id = 0;
  for (intptr_t i = 0; i < block_order().length(); ++i) {
    // Compile the block entry.
    BlockEntryInstr* entry = block_order()[i];
    assembler()->Comment("B%" Pd "", entry->block_id());
    set_current_block(entry);

    if (WasCompacted(entry)) {
      continue;
    }

#if defined(DEBUG)
    if (!is_optimizing()) {
      FrameStateClear();
    }
#endif

    LoopInfoComment(assembler(), *entry, *loop_headers);

    entry->set_offset(assembler()->CodeSize());
    BeginCodeSourceRange();
    entry->EmitNativeCode(this);
    EndCodeSourceRange(entry->token_pos());
    // Compile all successors until an exit, branch, or a block entry.
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      // Compose intervals.
      if (instr->has_inlining_id() && is_optimizing()) {
        if (prev_inlining_id != instr->inlining_id()) {
          intervals.Add(
              IntervalStruct(prev_offset, prev_inlining_pos, prev_inlining_id));
          prev_offset = assembler()->CodeSize();
          prev_inlining_id = instr->inlining_id();
          if (prev_inlining_id < inline_id_to_token_pos_.length()) {
            prev_inlining_pos = inline_id_to_token_pos_[prev_inlining_id];
          } else {
            // We will add this token position later when generating the
            // profile.
            prev_inlining_pos = TokenPosition::kNoSource;
          }
          if (prev_inlining_id > max_inlining_id) {
            max_inlining_id = prev_inlining_id;
          }
        }
      }
      if (FLAG_code_comments ||
          FLAG_disassemble || FLAG_disassemble_optimized) {
        if (FLAG_source_lines) {
          EmitSourceLine(instr);
        }
        EmitComment(instr);
      }
      if (instr->IsParallelMove()) {
        parallel_move_resolver_.EmitNativeCode(instr->AsParallelMove());
      } else {
        BeginCodeSourceRange();
        EmitInstructionPrologue(instr);
        ASSERT(pending_deoptimization_env_ == NULL);
        pending_deoptimization_env_ = instr->env();
        instr->EmitNativeCode(this);
        pending_deoptimization_env_ = NULL;
        EmitInstructionEpilogue(instr);
        EndCodeSourceRange(instr->token_pos());
      }

#if defined(DEBUG)
      if (!is_optimizing()) {
        FrameStateUpdateWith(instr);
      }
#endif
    }

#if defined(DEBUG)
    ASSERT(is_optimizing() || FrameStateIsSafeToCall());
#endif
  }

  if (is_optimizing()) {
    LogBlock lb;
    intervals.Add(
        IntervalStruct(prev_offset, prev_inlining_pos, prev_inlining_id));
    inlined_code_intervals_ =
        Array::New(intervals.length() * Code::kInlIntNumEntries, Heap::kOld);
    Smi& start_h = Smi::Handle();
    Smi& caller_inline_id = Smi::Handle();
    Smi& inline_id = Smi::Handle();
    for (intptr_t i = 0; i < intervals.length(); i++) {
      if (FLAG_trace_inlining_intervals && is_optimizing()) {
        const Function& function =
            *inline_id_to_function_.At(intervals[i].inlining_id);
        intervals[i].Dump();
        THR_Print(" parent iid %" Pd " %s\n",
            caller_inline_id_[intervals[i].inlining_id],
            function.ToQualifiedCString());
      }

      const intptr_t id = intervals[i].inlining_id;
      start_h = Smi::New(intervals[i].start);
      inline_id = Smi::New(id);
      caller_inline_id = Smi::New(caller_inline_id_[intervals[i].inlining_id]);

      const intptr_t p = i * Code::kInlIntNumEntries;
      inlined_code_intervals_.SetAt(p + Code::kInlIntStart, start_h);
      inlined_code_intervals_.SetAt(p + Code::kInlIntInliningId, inline_id);
    }
  }
  set_current_block(NULL);
  if (FLAG_trace_inlining_intervals && is_optimizing()) {
    LogBlock lb;
    THR_Print("Intervals:\n");
    for (intptr_t cc = 0; cc < caller_inline_id_.length(); cc++) {
      THR_Print("  iid: %" Pd " caller iid: %" Pd "\n",
          cc, caller_inline_id_[cc]);
    }
    Smi& temp = Smi::Handle();
    for (intptr_t i = 0; i < inlined_code_intervals_.Length();
         i += Code::kInlIntNumEntries) {
      temp ^= inlined_code_intervals_.At(i + Code::kInlIntStart);
      ASSERT(!temp.IsNull());
      THR_Print("% " Pd " start: 0x%" Px " ", i, temp.Value());
      temp ^= inlined_code_intervals_.At(i + Code::kInlIntInliningId);
      THR_Print("iid: %" Pd " ", temp.Value());
    }
  }
}


void FlowGraphCompiler::Bailout(const char* reason) {
  const Function& function = parsed_function_.function();
  Report::MessageF(Report::kBailout,
                   Script::Handle(function.script()),
                   function.token_pos(),
                   Report::AtLocation,
                   "FlowGraphCompiler Bailout: %s %s",
                   String::Handle(function.name()).ToCString(),
                   reason);
  UNREACHABLE();
}


void FlowGraphCompiler::EmitTrySync(Instruction* instr, intptr_t try_index) {
  ASSERT(is_optimizing());
  Environment* env = instr->env()->Outermost();
  CatchBlockEntryInstr* catch_block =
      flow_graph().graph_entry()->GetCatchEntry(try_index);
  const GrowableArray<Definition*>* idefs = catch_block->initial_definitions();

  // Construct a ParallelMove instruction for parameters and locals. Skip the
  // special locals exception_var and stacktrace_var since they will be filled
  // when an exception is thrown. Constant locations are known to be the same
  // at all instructions that may throw, and do not need to be materialized.

  // Parameters first.
  intptr_t i = 0;
  const intptr_t num_non_copied_params = flow_graph().num_non_copied_params();
  ParallelMoveInstr* move_instr = new(zone()) ParallelMoveInstr();
  for (; i < num_non_copied_params; ++i) {
    // Don't sync captured parameters. They are not in the environment.
    if (flow_graph().captured_parameters()->Contains(i)) continue;
    if ((*idefs)[i]->IsConstant()) continue;  // Common constants
    Location src = env->LocationAt(i);
    intptr_t dest_index = i - num_non_copied_params;
    Location dest = Location::StackSlot(dest_index);
    move_instr->AddMove(dest, src);
  }

  // Process locals. Skip exception_var and stacktrace_var.
  intptr_t local_base = kFirstLocalSlotFromFp + num_non_copied_params;
  intptr_t ex_idx = local_base - catch_block->exception_var().index();
  intptr_t st_idx = local_base - catch_block->stacktrace_var().index();
  for (; i < flow_graph().variable_count(); ++i) {
    // Don't sync captured parameters. They are not in the environment.
    if (flow_graph().captured_parameters()->Contains(i)) continue;
    if (i == ex_idx || i == st_idx) continue;
    if ((*idefs)[i]->IsConstant()) continue;
    Location src = env->LocationAt(i);
    ASSERT(!src.IsFpuRegister());
    ASSERT(!src.IsDoubleStackSlot());
    intptr_t dest_index = i - num_non_copied_params;
    Location dest = Location::StackSlot(dest_index);
    move_instr->AddMove(dest, src);
    // Update safepoint bitmap to indicate that the target location
    // now contains a pointer.
    instr->locs()->SetStackBit(dest_index);
  }
  parallel_move_resolver()->EmitNativeCode(move_instr);
}


intptr_t FlowGraphCompiler::StackSize() const {
  if (is_optimizing_) {
    return flow_graph_.graph_entry()->spill_slot_count();
  } else {
    return parsed_function_.num_stack_locals() +
        parsed_function_.num_copied_params();
  }
}


Label* FlowGraphCompiler::GetJumpLabel(
    BlockEntryInstr* block_entry) const {
  const intptr_t block_index = block_entry->postorder_number();
  return block_info_[block_index]->jump_label();
}


bool FlowGraphCompiler::WasCompacted(
    BlockEntryInstr* block_entry) const {
  const intptr_t block_index = block_entry->postorder_number();
  return block_info_[block_index]->WasCompacted();
}


Label* FlowGraphCompiler::NextNonEmptyLabel() const {
  const intptr_t current_index = current_block()->postorder_number();
  return block_info_[current_index]->next_nonempty_label();
}


bool FlowGraphCompiler::CanFallThroughTo(BlockEntryInstr* block_entry) const {
  return NextNonEmptyLabel() == GetJumpLabel(block_entry);
}


BranchLabels FlowGraphCompiler::CreateBranchLabels(BranchInstr* branch) const {
  Label* true_label = GetJumpLabel(branch->true_successor());
  Label* false_label = GetJumpLabel(branch->false_successor());
  Label* fall_through = NextNonEmptyLabel();
  BranchLabels result = { true_label, false_label, fall_through };
  return result;
}


void FlowGraphCompiler::AddSlowPathCode(SlowPathCode* code) {
  slow_path_code_.Add(code);
}


void FlowGraphCompiler::GenerateDeferredCode() {
  for (intptr_t i = 0; i < slow_path_code_.length(); i++) {
    BeginCodeSourceRange();
    slow_path_code_[i]->GenerateCode(this);
    EndCodeSourceRange(TokenPosition::kDeferredSlowPath);
  }
  for (intptr_t i = 0; i < deopt_infos_.length(); i++) {
    BeginCodeSourceRange();
    deopt_infos_[i]->GenerateCode(this, i);
    EndCodeSourceRange(TokenPosition::kDeferredDeoptInfo);
  }
}


void FlowGraphCompiler::AddExceptionHandler(intptr_t try_index,
                                            intptr_t outer_try_index,
                                            intptr_t pc_offset,
                                            const Array& handler_types,
                                            bool needs_stacktrace) {
  exception_handlers_list_->AddHandler(try_index,
                                       outer_try_index,
                                       pc_offset,
                                       handler_types,
                                       needs_stacktrace);
}


void FlowGraphCompiler::SetNeedsStacktrace(intptr_t try_index) {
  exception_handlers_list_->SetNeedsStacktrace(try_index);
}


// Uses current pc position and try-index.
void FlowGraphCompiler::AddCurrentDescriptor(RawPcDescriptors::Kind kind,
                                             intptr_t deopt_id,
                                             TokenPosition token_pos) {
  // When running with optimizations disabled, don't emit deopt-descriptors.
  if (!CanOptimize() && (kind == RawPcDescriptors::kDeopt)) return;
  pc_descriptors_list()->AddDescriptor(kind,
                                       assembler()->CodeSize(),
                                       deopt_id,
                                       token_pos,
                                       CurrentTryIndex());
}


void FlowGraphCompiler::AddStaticCallTarget(const Function& func) {
  ASSERT(func.IsZoneHandle());
  static_calls_target_table_.Add(
      new(zone()) StaticCallsStruct(assembler()->CodeSize(), &func, NULL));
}


void FlowGraphCompiler::AddStubCallTarget(const Code& code) {
  ASSERT(code.IsZoneHandle());
  static_calls_target_table_.Add(
      new(zone()) StaticCallsStruct(assembler()->CodeSize(), NULL, &code));
}


void FlowGraphCompiler::AddDeoptIndexAtCall(intptr_t deopt_id,
                                            TokenPosition token_pos) {
  ASSERT(is_optimizing());
  ASSERT(!intrinsic_mode());
  CompilerDeoptInfo* info =
      new(zone()) CompilerDeoptInfo(deopt_id,
                                    ICData::kDeoptAtCall,
                                    0,  // No flags.
                                    pending_deoptimization_env_);
  info->set_pc_offset(assembler()->CodeSize());
  deopt_infos_.Add(info);
}


// This function must be in sync with FlowGraphCompiler::SaveLiveRegisters
// and FlowGraphCompiler::SlowPathEnvironmentFor.
// See StackFrame::VisitObjectPointers for the details of how stack map is
// interpreted.
void FlowGraphCompiler::RecordSafepoint(LocationSummary* locs,
                                        intptr_t slow_path_argument_count) {
  if (is_optimizing() || locs->live_registers()->HasUntaggedValues()) {
    const intptr_t spill_area_size = is_optimizing() ?
        flow_graph_.graph_entry()->spill_slot_count() : 0;

    RegisterSet* registers = locs->live_registers();
    ASSERT(registers != NULL);
    const intptr_t kFpuRegisterSpillFactor =
            kFpuRegisterSize / kWordSize;
    const intptr_t live_registers_size = registers->CpuRegisterCount() +
        (registers->FpuRegisterCount() * kFpuRegisterSpillFactor);

    BitmapBuilder* bitmap = locs->stack_bitmap();

    // An instruction may have two safepoints in deferred code. The
    // call to RecordSafepoint has the side-effect of appending the live
    // registers to the bitmap. This is why the second call to RecordSafepoint
    // with the same instruction (and same location summary) sees a bitmap that
    // is larger that StackSize(). It will never be larger than StackSize() +
    // live_registers_size.
    ASSERT(bitmap->Length() <= (spill_area_size + live_registers_size));
    // The first safepoint will grow the bitmap to be the size of
    // spill_area_size but the second safepoint will truncate the bitmap and
    // append the live registers to it again. The bitmap produced by both calls
    // will be the same.
    bitmap->SetLength(spill_area_size);

    // Mark the bits in the stack map in the same order we push registers in
    // slow path code (see FlowGraphCompiler::SaveLiveRegisters).
    //
    // Slow path code can have registers at the safepoint.
    if (!locs->always_calls()) {
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

    // Arguments pushed on top of live registers in the slow path are tagged.
    for (intptr_t i = 0; i < slow_path_argument_count; ++i) {
      bitmap->Set(bitmap->Length(), true);
    }

    // The slow path area Outside the spill area contains are live registers
    // and pushed arguments for calls inside the slow path.
    intptr_t slow_path_bit_count = bitmap->Length() - spill_area_size;
    stackmap_table_builder()->AddEntry(assembler()->CodeSize(),
                                       bitmap,
                                       slow_path_bit_count);
  }
}


// This function must be kept in sync with:
//
//     FlowGraphCompiler::RecordSafepoint
//     FlowGraphCompiler::SaveLiveRegisters
//     MaterializeObjectInstr::RemapRegisters
//
Environment* FlowGraphCompiler::SlowPathEnvironmentFor(
    Instruction* instruction) {
  if (instruction->env() == NULL) {
    ASSERT(!is_optimizing());
    return NULL;
  }

  Environment* env = instruction->env()->DeepCopy(zone());
  // 1. Iterate the registers in the order they will be spilled to compute
  //    the slots they will be spilled to.
  intptr_t next_slot = StackSize() + env->CountArgsPushed();
  RegisterSet* regs = instruction->locs()->live_registers();
  intptr_t fpu_reg_slots[kNumberOfFpuRegisters];
  intptr_t cpu_reg_slots[kNumberOfCpuRegisters];
  const intptr_t kFpuRegisterSpillFactor = kFpuRegisterSize / kWordSize;
  // FPU registers are spilled first from highest to lowest register number.
  for (intptr_t i = kNumberOfFpuRegisters - 1; i >= 0; --i) {
    FpuRegister reg = static_cast<FpuRegister>(i);
    if (regs->ContainsFpuRegister(reg)) {
      // We use the lowest address (thus highest index) to identify a
      // multi-word spill slot.
      next_slot += kFpuRegisterSpillFactor;
      fpu_reg_slots[i] = (next_slot - 1);
    } else {
      fpu_reg_slots[i] = -1;
    }
  }
  // General purpose registers are spilled from highest to lowest register
  // number.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
    Register reg = static_cast<Register>(i);
    if (regs->ContainsRegister(reg)) {
      cpu_reg_slots[i] = next_slot++;
    } else {
      cpu_reg_slots[i] = -1;
    }
  }

  // 2. Iterate the environment and replace register locations with the
  //    corresponding spill slot locations.
  for (Environment::DeepIterator it(env); !it.Done(); it.Advance()) {
    Location loc = it.CurrentLocation();
    Value* value = it.CurrentValue();
    it.SetCurrentLocation(loc.RemapForSlowPath(
        value->definition(), cpu_reg_slots, fpu_reg_slots));
  }

  return env;
}


Label* FlowGraphCompiler::AddDeoptStub(intptr_t deopt_id,
                                       ICData::DeoptReasonId reason,
                                       uint32_t flags) {
  if (intrinsic_mode()) {
    return &intrinsic_slow_path_label_;
  }

  // No deoptimization allowed when 'FLAG_precompiled_mode' is set.
  if (FLAG_precompiled_mode) {
    if (FLAG_trace_compiler) {
      THR_Print(
          "Retrying compilation %s, suppressing inlining of deopt_id:%" Pd "\n",
          parsed_function_.function().ToFullyQualifiedCString(), deopt_id);
    }
    ASSERT(deopt_id != 0);  // longjmp must return non-zero value.
    Thread::Current()->long_jump_base()->Jump(
        deopt_id, Object::speculative_inlining_error());
  }

  ASSERT(is_optimizing_);
  CompilerDeoptInfoWithStub* stub =
      new(zone()) CompilerDeoptInfoWithStub(deopt_id,
                                            reason,
                                            flags,
                                            pending_deoptimization_env_);
  deopt_infos_.Add(stub);
  return stub->entry_label();
}


void FlowGraphCompiler::FinalizeExceptionHandlers(const Code& code) {
  ASSERT(exception_handlers_list_ != NULL);
  const ExceptionHandlers& handlers = ExceptionHandlers::Handle(
      exception_handlers_list_->FinalizeExceptionHandlers(code.EntryPoint()));
  code.set_exception_handlers(handlers);
  if (FLAG_compiler_stats) {
    Thread* thread = Thread::Current();
    INC_STAT(thread, total_code_size,
        ExceptionHandlers::InstanceSize(handlers.num_entries()));
    INC_STAT(thread, total_code_size, handlers.num_entries() * sizeof(uword));
  }
}


void FlowGraphCompiler::FinalizePcDescriptors(const Code& code) {
  ASSERT(pc_descriptors_list_ != NULL);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      pc_descriptors_list_->FinalizePcDescriptors(code.EntryPoint()));
  if (!is_optimizing_) descriptors.Verify(parsed_function_.function());
  code.set_pc_descriptors(descriptors);
  code.set_lazy_deopt_pc_offset(lazy_deopt_pc_offset_);
}


RawArray* FlowGraphCompiler::CreateDeoptInfo(Assembler* assembler) {
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
          deopt_infos_[i]->reason(),
          deopt_infos_[i]->flags());
      DeoptTable::SetEntry(array, i, offset, info, reason_and_flags);
    }
    return array.raw();
  }
}


void FlowGraphCompiler::FinalizeStackmaps(const Code& code) {
  if (stackmap_table_builder_ == NULL) {
    code.set_stackmaps(Object::null_array());
  } else {
    // Finalize the stack map array and add it to the code object.
    code.set_stackmaps(
        Array::Handle(stackmap_table_builder_->FinalizeStackmaps(code)));
  }
}


void FlowGraphCompiler::FinalizeVarDescriptors(const Code& code) {
  if (code.is_optimized()) {
    // Optimized code does not need variable descriptors. They are
    // only stored in the unoptimized version.
    code.set_var_descriptors(Object::empty_var_descriptors());
    return;
  }
  LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle();
  if (parsed_function().node_sequence() == NULL) {
    // Eager local var descriptors computation for Irregexp function as it is
    // complicated to factor out.
    // TODO(srdjan): Consider canonicalizing and reusing the local var
    // descriptor for IrregexpFunction.
    ASSERT(flow_graph().IsIrregexpFunction());
    var_descs = LocalVarDescriptors::New(1);
    RawLocalVarDescriptors::VarInfo info;
    info.set_kind(RawLocalVarDescriptors::kSavedCurrentContext);
    info.scope_id = 0;
    info.begin_pos = TokenPosition::kMinSource;
    info.end_pos = TokenPosition::kMinSource;
    info.set_index(parsed_function().current_context_var()->index());
    var_descs.SetVar(0, Symbols::CurrentContextVar(), &info);
  }
  code.set_var_descriptors(var_descs);
}


void FlowGraphCompiler::FinalizeStaticCallTargetsTable(const Code& code) {
  ASSERT(code.static_calls_target_table() == Array::null());
  const Array& targets = Array::Handle(zone(), Array::New(
      (static_calls_target_table_.length() * Code::kSCallTableEntryLength),
      Heap::kOld));
  Smi& smi_offset = Smi::Handle(zone());
  for (intptr_t i = 0; i < static_calls_target_table_.length(); i++) {
    const intptr_t target_ix = Code::kSCallTableEntryLength * i;
    smi_offset = Smi::New(static_calls_target_table_[i]->offset);
    targets.SetAt(target_ix + Code::kSCallTableOffsetEntry, smi_offset);
    if (static_calls_target_table_[i]->function != NULL) {
      targets.SetAt(target_ix + Code::kSCallTableFunctionEntry,
          *static_calls_target_table_[i]->function);
    }
    if (static_calls_target_table_[i]->code != NULL) {
      targets.SetAt(target_ix + Code::kSCallTableCodeEntry,
          *static_calls_target_table_[i]->code);
    }
  }
  code.set_static_calls_target_table(targets);
  INC_STAT(Thread::Current(),
           total_code_size,
           targets.Length() * sizeof(uword));
}


// Returns 'true' if regular code generation should be skipped.
bool FlowGraphCompiler::TryIntrinsify() {
  // Intrinsification skips arguments checks, therefore disable if in checked
  // mode.
  if (FLAG_intrinsify && !isolate()->type_checks()) {
    if (parsed_function().function().kind() == RawFunction::kImplicitGetter) {
      // An implicit getter must have a specific AST structure.
      const SequenceNode& sequence_node = *parsed_function().node_sequence();
      ASSERT(sequence_node.length() == 1);
      ASSERT(sequence_node.NodeAt(0)->IsReturnNode());
      const ReturnNode& return_node = *sequence_node.NodeAt(0)->AsReturnNode();
      ASSERT(return_node.value()->IsLoadInstanceFieldNode());
      const LoadInstanceFieldNode& load_node =
          *return_node.value()->AsLoadInstanceFieldNode();
      // Only intrinsify getter if the field cannot contain a mutable double.
      // Reading from a mutable double box requires allocating a fresh double.
      if (load_node.field().guarded_cid() == kDynamicCid) {
        GenerateInlinedGetter(load_node.field().Offset());
        return !FLAG_use_field_guards;
      }
      return false;
    }
    if (parsed_function().function().kind() == RawFunction::kImplicitSetter) {
      // An implicit setter must have a specific AST structure.
      // Sequence node has one store node and one return NULL node.
      const SequenceNode& sequence_node = *parsed_function().node_sequence();
      ASSERT(sequence_node.length() == 2);
      ASSERT(sequence_node.NodeAt(0)->IsStoreInstanceFieldNode());
      ASSERT(sequence_node.NodeAt(1)->IsReturnNode());
      const StoreInstanceFieldNode& store_node =
          *sequence_node.NodeAt(0)->AsStoreInstanceFieldNode();
      if (store_node.field().guarded_cid() == kDynamicCid) {
        GenerateInlinedSetter(store_node.field().Offset());
        return !FLAG_use_field_guards;
      }
    }
  }

  EnterIntrinsicMode();

  Intrinsifier::Intrinsify(parsed_function(), this);

  ExitIntrinsicMode();
  // "Deoptimization" from intrinsic continues here. All deoptimization
  // branches from intrinsic code redirect to here where the slow-path
  // (normal function body) starts.
  // This means that there must not be any side-effects in intrinsic code
  // before any deoptimization point.
  ASSERT(!intrinsic_slow_path_label_.IsBound());
  assembler()->Bind(&intrinsic_slow_path_label_);
  return false;
}


void FlowGraphCompiler::GenerateInstanceCall(
    intptr_t deopt_id,
    TokenPosition token_pos,
    intptr_t argument_count,
    LocationSummary* locs,
    const ICData& ic_data_in) {
  const ICData& ic_data = ICData::ZoneHandle(ic_data_in.Original());
  if (FLAG_precompiled_mode) {
    EmitSwitchableInstanceCall(ic_data, argument_count,
                               deopt_id, token_pos, locs);
    return;
  }
  if (FLAG_always_megamorphic_calls) {
    EmitMegamorphicInstanceCall(ic_data, argument_count,
                                deopt_id, token_pos, locs,
                                CatchClauseNode::kInvalidTryIndex);
    return;
  }
  ASSERT(!ic_data.IsNull());
  if (is_optimizing() && (ic_data.NumberOfUsedChecks() == 0)) {
    // Emit IC call that will count and thus may need reoptimization at
    // function entry.
    ASSERT(may_reoptimize() || flow_graph().IsCompiledForOsr());
    switch (ic_data.NumArgsTested()) {
      case 1:
        EmitOptimizedInstanceCall(
            *StubCode::OneArgOptimizedCheckInlineCache_entry(), ic_data,
            argument_count, deopt_id, token_pos, locs);
        return;
      case 2:
        EmitOptimizedInstanceCall(
            *StubCode::TwoArgsOptimizedCheckInlineCache_entry(), ic_data,
            argument_count, deopt_id, token_pos, locs);
        return;
      default:
        UNIMPLEMENTED();
    }
    return;
  }

  if (is_optimizing()) {
    EmitMegamorphicInstanceCall(ic_data, argument_count,
                                deopt_id, token_pos, locs,
                                CatchClauseNode::kInvalidTryIndex);
    return;
  }

  switch (ic_data.NumArgsTested()) {
    case 1:
      EmitInstanceCall(
          *StubCode::OneArgCheckInlineCache_entry(), ic_data, argument_count,
          deopt_id, token_pos, locs);
      break;
    case 2:
      EmitInstanceCall(
          *StubCode::TwoArgsCheckInlineCache_entry(), ic_data, argument_count,
          deopt_id, token_pos, locs);
      break;
    default:
      UNIMPLEMENTED();
  }
}


void FlowGraphCompiler::GenerateStaticCall(intptr_t deopt_id,
                                           TokenPosition token_pos,
                                           const Function& function,
                                           intptr_t argument_count,
                                           const Array& argument_names,
                                           LocationSummary* locs,
                                           const ICData& ic_data_in) {
  const ICData& ic_data = ICData::ZoneHandle(ic_data_in.Original());
  const Array& arguments_descriptor = Array::ZoneHandle(
      ic_data.IsNull() ? ArgumentsDescriptor::New(argument_count,
                                                  argument_names)
                       : ic_data.arguments_descriptor());
  if (is_optimizing()) {
    EmitOptimizedStaticCall(function, arguments_descriptor,
                            argument_count, deopt_id, token_pos, locs);
  } else {
    ICData& call_ic_data = ICData::ZoneHandle(ic_data.raw());
    if (call_ic_data.IsNull()) {
      const intptr_t kNumArgsChecked = 0;
      call_ic_data = GetOrAddStaticCallICData(deopt_id,
                                              function,
                                              arguments_descriptor,
                                              kNumArgsChecked)->raw();
    }
    EmitUnoptimizedStaticCall(argument_count, deopt_id, token_pos, locs,
                              call_ic_data);
  }
}


void FlowGraphCompiler::GenerateNumberTypeCheck(Register kClassIdReg,
                                                const AbstractType& type,
                                                Label* is_instance_lbl,
                                                Label* is_not_instance_lbl) {
  assembler()->Comment("NumberTypeCheck");
  GrowableArray<intptr_t> args;
  if (type.IsNumberType()) {
    args.Add(kDoubleCid);
    args.Add(kMintCid);
    args.Add(kBigintCid);
  } else if (type.IsIntType()) {
    args.Add(kMintCid);
    args.Add(kBigintCid);
  } else if (type.IsDoubleType()) {
    args.Add(kDoubleCid);
  }
  CheckClassIds(kClassIdReg, args, is_instance_lbl, is_not_instance_lbl);
}


void FlowGraphCompiler::GenerateStringTypeCheck(Register kClassIdReg,
                                                Label* is_instance_lbl,
                                                Label* is_not_instance_lbl) {
  assembler()->Comment("StringTypeCheck");
  GrowableArray<intptr_t> args;
  args.Add(kOneByteStringCid);
  args.Add(kTwoByteStringCid);
  args.Add(kExternalOneByteStringCid);
  args.Add(kExternalTwoByteStringCid);
  CheckClassIds(kClassIdReg, args, is_instance_lbl, is_not_instance_lbl);
}


void FlowGraphCompiler::GenerateListTypeCheck(Register kClassIdReg,
                                              Label* is_instance_lbl) {
  assembler()->Comment("ListTypeCheck");
  Label unknown;
  GrowableArray<intptr_t> args;
  args.Add(kArrayCid);
  args.Add(kGrowableObjectArrayCid);
  args.Add(kImmutableArrayCid);
  CheckClassIds(kClassIdReg, args, is_instance_lbl, &unknown);
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


bool FlowGraphCompiler::NeedsEdgeCounter(TargetEntryInstr* block) {
  // Only emit an edge counter if there is not goto at the end of the block,
  // except for the entry block.
  return (FLAG_reorder_basic_blocks
      && (!block->last_instruction()->IsGoto()
          || (block == flow_graph().graph_entry()->normal_entry())));
}


// Allocate a register that is not explicitly blocked.
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


static uword RegMaskBit(Register reg) {
  return ((reg) != kNoRegister) ? (1 << (reg)) : 0;
}


void FlowGraphCompiler::AllocateRegistersLocally(Instruction* instr) {
  ASSERT(!is_optimizing());

  instr->InitializeLocationSummary(zone(),
                                   false);  // Not optimizing.
  LocationSummary* locs = instr->locs();

  bool blocked_registers[kNumberOfCpuRegisters];

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
  const bool should_pop = !instr->IsPushArgument() && !instr->IsPushTemp();
  for (intptr_t i = locs->input_count() - 1; i >= 0; i--) {
    Location loc = locs->in(i);
    Register reg = kNoRegister;
    if (loc.IsRegister()) {
      reg = loc.reg();
    } else if (loc.IsUnallocated() || loc.IsConstant()) {
      ASSERT(loc.IsConstant() ||
             ((loc.policy() == Location::kRequiresRegister) ||
              (loc.policy() == Location::kWritableRegister) ||
              (loc.policy() == Location::kAny)));
      reg = AllocateFreeRegister(blocked_registers);
      locs->set_in(i, Location::RegisterLocation(reg));
    }
    ASSERT(reg != kNoRegister);

    // Inputs are consumed from the simulated frame. In case of a call argument
    // we leave it until the call instruction.
    if (should_pop) {
      assembler()->PopRegister(reg);
    }
  }

  // Allocate all unallocated temp locations.
  for (intptr_t i = 0; i < locs->temp_count(); i++) {
    Location loc = locs->temp(i);
    if (loc.IsUnallocated()) {
      ASSERT(loc.policy() == Location::kRequiresRegister);
      loc = Location::RegisterLocation(
        AllocateFreeRegister(blocked_registers));
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
        result_location = Location::RegisterLocation(
            AllocateFreeRegister(blocked_registers));
        break;
      case Location::kSameAsFirstInput:
        result_location = locs->in(0);
        break;
      case Location::kRequiresFpuRegister:
        UNREACHABLE();
        break;
    }
    locs->set_out(0, result_location);
  }
}


ParallelMoveResolver::ParallelMoveResolver(FlowGraphCompiler* compiler)
    : compiler_(compiler), moves_(32) {}


void ParallelMoveResolver::EmitNativeCode(ParallelMoveInstr* parallel_move) {
  ASSERT(moves_.is_empty());
  // Build up a worklist of moves.
  BuildInitialMoveList(parallel_move);

  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& move = *moves_[i];
    // Skip constants to perform them last.  They don't block other moves
    // and skipping such moves with register destinations keeps those
    // registers free for the whole algorithm.
    if (!move.IsEliminated() && !move.src().IsConstant()) PerformMove(i);
  }

  // Perform the moves with constant sources.
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& move = *moves_[i];
    if (!move.IsEliminated()) {
      ASSERT(move.src().IsConstant());
      compiler_->BeginCodeSourceRange();
      EmitMove(i);
      compiler_->EndCodeSourceRange(TokenPosition::kParallelMove);
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


void ParallelMoveResolver::PerformMove(int index) {
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
      PerformMove(i);
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
      compiler_->BeginCodeSourceRange();
      EmitSwap(index);
      compiler_->EndCodeSourceRange(TokenPosition::kParallelMove);
      return;
    }
  }

  // This move is not blocked.
  compiler_->BeginCodeSourceRange();
  EmitMove(index);
  compiler_->EndCodeSourceRange(TokenPosition::kParallelMove);
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
    ParallelMoveResolver* resolver, FpuRegister blocked)
    : resolver_(resolver),
      reg_(kNoFpuRegister),
      spilled_(false) {
  COMPILE_ASSERT(FpuTMP != kNoFpuRegister);
  uword blocked_mask = ((blocked != kNoFpuRegister) ? 1 << blocked : 0)
                     | 1 << FpuTMP;
  reg_ = static_cast<FpuRegister>(
      resolver_->AllocateScratchRegister(Location::kFpuRegister,
                                         blocked_mask,
                                         0,
                                         kNumberOfFpuRegisters - 1,
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


ParallelMoveResolver::ScratchRegisterScope::ScratchRegisterScope(
    ParallelMoveResolver* resolver, Register blocked)
    : resolver_(resolver),
      reg_(kNoRegister),
      spilled_(false) {
  uword blocked_mask = RegMaskBit(blocked) | kReservedCpuRegisters;
  if (resolver->compiler_->intrinsic_mode()) {
    // Block additional registers that must be preserved for intrinsics.
    blocked_mask |= RegMaskBit(ARGS_DESC_REG);
#if !defined(TARGET_ARCH_IA32)
    // Need to preserve CODE_REG to be able to store the PC marker
    // and load the pool pointer.
    blocked_mask |= RegMaskBit(CODE_REG);
#endif
  }
  reg_ = static_cast<Register>(
      resolver_->AllocateScratchRegister(Location::kRegister,
                                         blocked_mask,
                                         0,
                                         kNumberOfCpuRegisters - 1,
                                         &spilled_));

  if (spilled_) {
    resolver->SpillScratch(reg_);
  }
}


ParallelMoveResolver::ScratchRegisterScope::~ScratchRegisterScope() {
  if (spilled_) {
    resolver_->RestoreScratch(reg_);
  }
}


static int HighestCountFirst(const CidTarget* a, const CidTarget* b) {
  // Negative if 'a' should sort before 'b'.
  return b->count - a->count;
}


// Returns 'sorted' array in decreasing count order.
// The expected number of elements to sort is less than 10.
void FlowGraphCompiler::SortICDataByCount(const ICData& ic_data,
                                          GrowableArray<CidTarget>* sorted,
                                          bool drop_smi) {
  ASSERT(ic_data.NumArgsTested() == 1);
  const intptr_t len = ic_data.NumberOfChecks();
  sorted->Clear();

  for (int i = 0; i < len; i++) {
    intptr_t receiver_cid = ic_data.GetReceiverClassIdAt(i);
    if (drop_smi && (receiver_cid == kSmiCid)) continue;
    sorted->Add(CidTarget(receiver_cid,
                          &Function::ZoneHandle(ic_data.GetTargetAt(i)),
                          ic_data.GetCountAt(i)));
  }
  sorted->Sort(HighestCountFirst);
}


const ICData* FlowGraphCompiler::GetOrAddInstanceCallICData(
    intptr_t deopt_id,
    const String& target_name,
    const Array& arguments_descriptor,
    intptr_t num_args_tested) {
  if ((deopt_id_to_ic_data_ != NULL) &&
      ((*deopt_id_to_ic_data_)[deopt_id] != NULL)) {
    const ICData* res = (*deopt_id_to_ic_data_)[deopt_id];
    ASSERT(res->deopt_id() == deopt_id);
    ASSERT(res->target_name() == target_name.raw());
    ASSERT(res->NumArgsTested() == num_args_tested);
    return res;
  }
  const ICData& ic_data = ICData::ZoneHandle(zone(), ICData::New(
      parsed_function().function(), target_name,
      arguments_descriptor, deopt_id, num_args_tested));
  if (deopt_id_to_ic_data_ != NULL) {
    (*deopt_id_to_ic_data_)[deopt_id] = &ic_data;
  }
  return &ic_data;
}


const ICData* FlowGraphCompiler::GetOrAddStaticCallICData(
    intptr_t deopt_id,
    const Function& target,
    const Array& arguments_descriptor,
    intptr_t num_args_tested) {
  if ((deopt_id_to_ic_data_ != NULL) &&
      ((*deopt_id_to_ic_data_)[deopt_id] != NULL)) {
    const ICData* res = (*deopt_id_to_ic_data_)[deopt_id];
    ASSERT(res->deopt_id() == deopt_id);
    ASSERT(res->target_name() == target.name());
    ASSERT(res->NumArgsTested() == num_args_tested);
    return res;
  }
  const ICData& ic_data = ICData::ZoneHandle(zone(), ICData::New(
      parsed_function().function(), String::Handle(zone(), target.name()),
      arguments_descriptor, deopt_id, num_args_tested));
  ic_data.AddTarget(target);
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
  } else {
    const intptr_t basic_blocks = flow_graph().preorder().length();
    ASSERT(basic_blocks > 0);
    threshold = FLAG_optimization_counter_scale * basic_blocks +
        FLAG_min_optimization_counter_threshold;
    if (threshold > FLAG_optimization_counter_threshold) {
      threshold = FLAG_optimization_counter_threshold;
    }
  }
  return threshold;
}


const Class& FlowGraphCompiler::BoxClassFor(Representation rep) {
  switch (rep) {
    case kUnboxedDouble:
      return double_class();
    case kUnboxedFloat32x4:
      return float32x4_class();
    case kUnboxedFloat64x2:
      return float64x2_class();
    case kUnboxedInt32x4:
      return int32x4_class();
    case kUnboxedMint:
      return mint_class();
    default:
      UNREACHABLE();
      return Class::ZoneHandle();
  }
}


RawArray* FlowGraphCompiler::InliningIdToFunction() const {
  if (inline_id_to_function_.length() == 0) {
    return Object::empty_array().raw();
  }
  const Array& res = Array::Handle(
      Array::New(inline_id_to_function_.length(), Heap::kOld));
  for (intptr_t i = 0; i < inline_id_to_function_.length(); i++) {
    res.SetAt(i, *inline_id_to_function_[i]);
  }
  return res.raw();
}


RawArray* FlowGraphCompiler::InliningIdToTokenPos() const {
  if (inline_id_to_token_pos_.length() == 0) {
    return Object::empty_array().raw();
  }
  const Array& res = Array::Handle(zone(),
      Array::New(inline_id_to_token_pos_.length(), Heap::kOld));
  Smi& smi = Smi::Handle(zone());
  for (intptr_t i = 0; i < inline_id_to_token_pos_.length(); i++) {
    smi = Smi::New(inline_id_to_token_pos_[i].value());
    res.SetAt(i, smi);
  }
  return res.raw();
}


RawArray* FlowGraphCompiler::CallerInliningIdMap() const {
  if (caller_inline_id_.length() == 0) {
    return Object::empty_array().raw();
  }
  const Array& res = Array::Handle(
      Array::New(caller_inline_id_.length(), Heap::kOld));
  Smi& smi = Smi::Handle();
  for (intptr_t i = 0; i < caller_inline_id_.length(); i++) {
    smi = Smi::New(caller_inline_id_[i]);
    res.SetAt(i, smi);
  }
  return res.raw();
}


void FlowGraphCompiler::BeginCodeSourceRange() {
NOT_IN_PRODUCT(
  // Remember how many bytes of code we emitted so far. This function
  // is called before we call into an instruction's EmitNativeCode.
  saved_code_size_ = assembler()->CodeSize();
);
}


bool FlowGraphCompiler::EndCodeSourceRange(TokenPosition token_pos) {
NOT_IN_PRODUCT(
  // This function is called after each instructions' EmitNativeCode.
  if (saved_code_size_ < assembler()->CodeSize()) {
    // We emitted more code, now associate the emitted code chunk with
    // |token_pos|.
    code_source_map_builder()->AddEntry(saved_code_size_, token_pos);
    BeginCodeSourceRange();
    return true;
  }
);
  return false;
}


void FlowGraphCompiler::EmitPolymorphicInstanceCall(
    const ICData& ic_data,
    intptr_t argument_count,
    const Array& argument_names,
    intptr_t deopt_id,
    TokenPosition token_pos,
    LocationSummary* locs) {
  if (FLAG_polymorphic_with_deopt) {
    Label* deopt = AddDeoptStub(deopt_id,
                                ICData::kDeoptPolymorphicInstanceCallTestFail);
    Label ok;
    EmitTestAndCall(ic_data, argument_count, argument_names,
                    deopt,  // No cid match.
                    &ok,    // Found cid.
                    deopt_id, token_pos, locs);
    assembler()->Bind(&ok);
  } else {
    // Instead of deoptimizing, do a megamorphic call when no matching
    // cid found.
    Label ok;
    MegamorphicSlowPath* slow_path =
        new MegamorphicSlowPath(ic_data, argument_count, deopt_id,
                                token_pos, locs, CurrentTryIndex());
    AddSlowPathCode(slow_path);
    EmitTestAndCall(ic_data, argument_count, argument_names,
                    slow_path->entry_label(),  // No cid match.
                    &ok,                       // Found cid.
                    deopt_id, token_pos, locs);

    assembler()->Bind(slow_path->exit_label());
    assembler()->Bind(&ok);
  }
}


#if defined(DEBUG)
void FlowGraphCompiler::FrameStateUpdateWith(Instruction* instr) {
  ASSERT(!is_optimizing());

  switch (instr->tag()) {
    case Instruction::kPushArgument:
    case Instruction::kPushTemp:
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
  if ((rep == kUnboxedDouble) ||
      (rep == kUnboxedFloat64x2) ||
      (rep == kUnboxedFloat32x4)) {
    // LoadField instruction lies about its representation in the unoptimized
    // code because Definition::representation() can't depend on the type of
    // compilation but MakeLocationSummary and EmitNativeCode can.
    ASSERT(defn->IsLoadField() && defn->AsLoadField()->IsUnboxedLoad());
    ASSERT(defn->locs()->out(0).IsRegister());
    rep = kTagged;
  }
  ASSERT(!is_optimizing());
  ASSERT((rep == kTagged) || (rep == kUntagged));
  ASSERT(rep != kUntagged || flow_graph_.IsIrregexpFunction());
  frame_state_.Add(rep);
}


void FlowGraphCompiler::FrameStatePop(intptr_t count) {
  ASSERT(!is_optimizing());
  frame_state_.TruncateTo(Utils::Maximum(static_cast<intptr_t>(0),
      frame_state_.length() - count));
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
#endif


}  // namespace dart
