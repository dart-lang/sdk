// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/linearscan.h"

#include "vm/bit_vector.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/loops.h"
#include "vm/log.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"

namespace dart {

#if !defined(PRODUCT)
#define INCLUDE_LINEAR_SCAN_TRACING_CODE
#endif

#if defined(INCLUDE_LINEAR_SCAN_TRACING_CODE)
#define TRACE_ALLOC(statement)                                                 \
  do {                                                                         \
    if (FLAG_trace_ssa_allocator && CompilerState::ShouldTrace()) statement;   \
  } while (0)
#else
#define TRACE_ALLOC(statement)
#endif

static const intptr_t kNoVirtualRegister = -1;
static const intptr_t kTempVirtualRegister = -2;
static const intptr_t kIllegalPosition = -1;
static const intptr_t kMaxPosition = 0x7FFFFFFF;
static const intptr_t kPairVirtualRegisterOffset = 1;

// Definitions which have pair representations
// (kPairOfTagged) use two virtual register names.
// At SSA index allocation time each definition reserves two SSA indexes,
// the second index is only used for pairs. This function maps from the first
// SSA index to the second.
static intptr_t ToSecondPairVreg(intptr_t vreg) {
  // Map vreg to its pair vreg.
  ASSERT((vreg == kNoVirtualRegister) || vreg >= 0);
  return (vreg == kNoVirtualRegister) ? kNoVirtualRegister
                                      : (vreg + kPairVirtualRegisterOffset);
}

static intptr_t MinPosition(intptr_t a, intptr_t b) {
  return (a < b) ? a : b;
}

static bool IsInstructionStartPosition(intptr_t pos) {
  return (pos & 1) == 0;
}

static bool IsInstructionEndPosition(intptr_t pos) {
  return (pos & 1) == 1;
}

static intptr_t ToInstructionStart(intptr_t pos) {
  return (pos & ~1);
}

static intptr_t ToInstructionEnd(intptr_t pos) {
  return (pos | 1);
}

// Additional information on loops during register allocation.
struct ExtraLoopInfo : public ZoneAllocated {
  ExtraLoopInfo(intptr_t s, intptr_t e)
      : start(s), end(e), backedge_interference(nullptr) {}
  intptr_t start;
  intptr_t end;
  BitVector* backedge_interference;
};

// Returns extra loop information.
static ExtraLoopInfo* ComputeExtraLoopInfo(Zone* zone, LoopInfo* loop_info) {
  intptr_t start = loop_info->header()->start_pos();
  intptr_t end = start;
  for (auto back_edge : loop_info->back_edges()) {
    intptr_t end_pos = back_edge->end_pos();
    if (end_pos > end) {
      end = end_pos;
    }
  }
  return new (zone) ExtraLoopInfo(start, end);
}

FlowGraphAllocator::FlowGraphAllocator(const FlowGraph& flow_graph,
                                       bool intrinsic_mode)
    : flow_graph_(flow_graph),
      reaching_defs_(flow_graph),
      value_representations_(flow_graph.max_virtual_register_number()),
      block_order_(flow_graph.reverse_postorder()),
      postorder_(flow_graph.postorder()),
      instructions_(),
      block_entries_(),
      extra_loop_info_(),
      liveness_(flow_graph),
      vreg_count_(flow_graph.max_virtual_register_number()),
      live_ranges_(flow_graph.max_virtual_register_number()),
      unallocated_cpu_(),
      unallocated_xmm_(),
      cpu_regs_(),
      fpu_regs_(),
      blocked_cpu_registers_(),
      blocked_fpu_registers_(),
      spilled_(),
      safepoints_(),
      register_kind_(),
      number_of_registers_(0),
      registers_(),
      blocked_registers_(),
      unallocated_(),
      spill_slots_(),
      quad_spill_slots_(),
      untagged_spill_slots_(),
      cpu_spill_slot_count_(0),
      intrinsic_mode_(intrinsic_mode) {
  for (intptr_t i = 0; i < vreg_count_; i++) {
    live_ranges_.Add(NULL);
  }
  for (intptr_t i = 0; i < vreg_count_; i++) {
    value_representations_.Add(kNoRepresentation);
  }

  // All registers are marked as "not blocked" (array initialized to false).
  // Mark the unavailable ones as "blocked" (true).
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    if ((kDartAvailableCpuRegs & (1 << i)) == 0) {
      blocked_cpu_registers_[i] = true;
    }
  }

  // FpuTMP is used as scratch by optimized code and parallel move resolver.
  blocked_fpu_registers_[FpuTMP] = true;

  // Block additional registers needed preserved when generating intrinsics.
  // TODO(fschneider): Handle saving and restoring these registers when
  // generating intrinsic code.
  if (intrinsic_mode) {
    blocked_cpu_registers_[ARGS_DESC_REG] = true;

#if !defined(TARGET_ARCH_IA32)
    // Need to preserve CODE_REG to be able to store the PC marker
    // and load the pool pointer.
    blocked_cpu_registers_[CODE_REG] = true;
#endif
  }
}

static void DeepLiveness(MaterializeObjectInstr* mat, BitVector* live_in) {
  if (mat->was_visited_for_liveness()) {
    return;
  }
  mat->mark_visited_for_liveness();

  for (intptr_t i = 0; i < mat->InputCount(); i++) {
    if (!mat->InputAt(i)->BindsToConstant()) {
      Definition* defn = mat->InputAt(i)->definition();
      MaterializeObjectInstr* inner_mat = defn->AsMaterializeObject();
      if (inner_mat != NULL) {
        DeepLiveness(inner_mat, live_in);
      } else {
        intptr_t idx = defn->ssa_temp_index();
        live_in->Add(idx);
      }
    }
  }
}

void SSALivenessAnalysis::ComputeInitialSets() {
  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];

    BitVector* kill = kill_[i];
    BitVector* live_in = live_in_[i];

    // Iterate backwards starting at the last instruction.
    for (BackwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();

      // Initialize location summary for instruction.
      current->InitializeLocationSummary(zone(), true);  // opt

      LocationSummary* locs = current->locs();
#if defined(DEBUG)
      locs->DiscoverWritableInputs();
#endif

      // Handle definitions.
      Definition* current_def = current->AsDefinition();
      if ((current_def != NULL) && current_def->HasSSATemp()) {
        kill->Add(current_def->ssa_temp_index());
        live_in->Remove(current_def->ssa_temp_index());
        if (current_def->HasPairRepresentation()) {
          kill->Add(ToSecondPairVreg(current_def->ssa_temp_index()));
          live_in->Remove(ToSecondPairVreg(current_def->ssa_temp_index()));
        }
      }

      // Handle uses.
      ASSERT(locs->input_count() == current->InputCount());
      for (intptr_t j = 0; j < current->InputCount(); j++) {
        Value* input = current->InputAt(j);

        ASSERT(!locs->in(j).IsConstant() || input->BindsToConstant());
        if (locs->in(j).IsConstant()) continue;

        live_in->Add(input->definition()->ssa_temp_index());
        if (input->definition()->HasPairRepresentation()) {
          live_in->Add(ToSecondPairVreg(input->definition()->ssa_temp_index()));
        }
      }

      // Add non-argument uses from the deoptimization environment (pushed
      // arguments are not allocated by the register allocator).
      if (current->env() != NULL) {
        for (Environment::DeepIterator env_it(current->env()); !env_it.Done();
             env_it.Advance()) {
          Definition* defn = env_it.CurrentValue()->definition();
          if (defn->IsMaterializeObject()) {
            // MaterializeObject instruction is not in the graph.
            // Treat its inputs as part of the environment.
            DeepLiveness(defn->AsMaterializeObject(), live_in);
          } else if (!defn->IsPushArgument() && !defn->IsConstant()) {
            live_in->Add(defn->ssa_temp_index());
            if (defn->HasPairRepresentation()) {
              live_in->Add(ToSecondPairVreg(defn->ssa_temp_index()));
            }
          }
        }
      }
    }

    // Handle phis.
    if (block->IsJoinEntry()) {
      JoinEntryInstr* join = block->AsJoinEntry();
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        ASSERT(phi != NULL);
        kill->Add(phi->ssa_temp_index());
        live_in->Remove(phi->ssa_temp_index());
        if (phi->HasPairRepresentation()) {
          kill->Add(ToSecondPairVreg(phi->ssa_temp_index()));
          live_in->Remove(ToSecondPairVreg(phi->ssa_temp_index()));
        }

        // If a phi input is not defined by the corresponding predecessor it
        // must be marked live-in for that predecessor.
        for (intptr_t k = 0; k < phi->InputCount(); k++) {
          Value* val = phi->InputAt(k);
          if (val->BindsToConstant()) continue;

          BlockEntryInstr* pred = block->PredecessorAt(k);
          const intptr_t use = val->definition()->ssa_temp_index();
          if (!kill_[pred->postorder_number()]->Contains(use)) {
            live_in_[pred->postorder_number()]->Add(use);
          }
          if (phi->HasPairRepresentation()) {
            const intptr_t second_use = ToSecondPairVreg(use);
            if (!kill_[pred->postorder_number()]->Contains(second_use)) {
              live_in_[pred->postorder_number()]->Add(second_use);
            }
          }
        }
      }
    } else if (auto entry = block->AsBlockEntryWithInitialDefs()) {
      // Process initial definitions, i.e. parameters and special parameters.
      for (intptr_t i = 0; i < entry->initial_definitions()->length(); i++) {
        Definition* def = (*entry->initial_definitions())[i];
        const intptr_t vreg = def->ssa_temp_index();
        kill_[entry->postorder_number()]->Add(vreg);
        live_in_[entry->postorder_number()]->Remove(vreg);
        if (def->HasPairRepresentation()) {
          kill_[entry->postorder_number()]->Add(ToSecondPairVreg((vreg)));
          live_in_[entry->postorder_number()]->Remove(ToSecondPairVreg(vreg));
        }
      }
    }
  }
}

UsePosition* LiveRange::AddUse(intptr_t pos, Location* location_slot) {
  ASSERT(location_slot != NULL);
  ASSERT((first_use_interval_->start_ <= pos) &&
         (pos <= first_use_interval_->end_));
  if (uses_ != NULL) {
    if ((uses_->pos() == pos) && (uses_->location_slot() == location_slot)) {
      return uses_;
    } else if (uses_->pos() < pos) {
      // If an instruction at position P is using the same value both as
      // a fixed register input and a non-fixed input (in this order) we will
      // add uses both at position P-1 and *then* P which will make
      // uses_ unsorted unless we account for it here.
      UsePosition* insert_after = uses_;
      while ((insert_after->next() != NULL) &&
             (insert_after->next()->pos() < pos)) {
        insert_after = insert_after->next();
      }

      UsePosition* insert_before = insert_after->next();
      while (insert_before != NULL && (insert_before->pos() == pos)) {
        if (insert_before->location_slot() == location_slot) {
          return insert_before;
        }
        insert_before = insert_before->next();
      }

      insert_after->set_next(
          new UsePosition(pos, insert_after->next(), location_slot));
      return insert_after->next();
    }
  }
  uses_ = new UsePosition(pos, uses_, location_slot);
  return uses_;
}

void LiveRange::AddSafepoint(intptr_t pos, LocationSummary* locs) {
  ASSERT(IsInstructionStartPosition(pos));
  SafepointPosition* safepoint =
      new SafepointPosition(ToInstructionEnd(pos), locs);

  if (first_safepoint_ == NULL) {
    ASSERT(last_safepoint_ == NULL);
    first_safepoint_ = last_safepoint_ = safepoint;
  } else {
    ASSERT(last_safepoint_ != NULL);
    // We assume that safepoints list is sorted by position and that
    // safepoints are added in this order.
    ASSERT(last_safepoint_->pos() < pos);
    last_safepoint_->set_next(safepoint);
    last_safepoint_ = safepoint;
  }
}

void LiveRange::AddHintedUse(intptr_t pos,
                             Location* location_slot,
                             Location* hint) {
  ASSERT(hint != NULL);
  AddUse(pos, location_slot)->set_hint(hint);
}

void LiveRange::AddUseInterval(intptr_t start, intptr_t end) {
  ASSERT(start < end);

  // Live ranges are being build by visiting instructions in post-order.
  // This implies that use intervals will be prepended in a monotonically
  // decreasing order.
  if (first_use_interval() != NULL) {
    // If the first use interval and the use interval we are adding
    // touch then we can just extend the first interval to cover their
    // union.
    if (start > first_use_interval()->start()) {
      // The only case when we can add intervals with start greater than
      // start of an already created interval is BlockLocation.
      ASSERT(vreg() == kNoVirtualRegister);
      ASSERT(end <= first_use_interval()->end());
      return;
    } else if (start == first_use_interval()->start()) {
      // Grow first interval if necessary.
      if (end <= first_use_interval()->end()) return;
      first_use_interval_->end_ = end;
      return;
    } else if (end == first_use_interval()->start()) {
      first_use_interval()->start_ = start;
      return;
    }

    ASSERT(end < first_use_interval()->start());
  }

  first_use_interval_ = new UseInterval(start, end, first_use_interval_);
  if (last_use_interval_ == NULL) {
    ASSERT(first_use_interval_->next() == NULL);
    last_use_interval_ = first_use_interval_;
  }
}

void LiveRange::DefineAt(intptr_t pos) {
  // Live ranges are being build by visiting instructions in post-order.
  // This implies that use intervals will be prepended in a monotonically
  // decreasing order.
  // When we encounter a use of a value inside a block we optimistically
  // expand the first use interval to cover the block from the start
  // to the last use in the block and then we shrink it if we encounter
  // definition of the value inside the same block.
  if (first_use_interval_ == NULL) {
    // Definition without a use.
    first_use_interval_ = new UseInterval(pos, pos + 1, NULL);
    last_use_interval_ = first_use_interval_;
  } else {
    // Shrink the first use interval. It was optimistically expanded to
    // cover the block from the start to the last use in the block.
    ASSERT(first_use_interval_->start_ <= pos);
    first_use_interval_->start_ = pos;
  }
}

LiveRange* FlowGraphAllocator::GetLiveRange(intptr_t vreg) {
  if (live_ranges_[vreg] == NULL) {
    Representation rep = value_representations_[vreg];
    ASSERT(rep != kNoRepresentation);
    live_ranges_[vreg] = new LiveRange(vreg, rep);
  }
  return live_ranges_[vreg];
}

LiveRange* FlowGraphAllocator::MakeLiveRangeForTemporary() {
  // Representation does not matter for temps.
  Representation ignored = kNoRepresentation;
  LiveRange* range = new LiveRange(kTempVirtualRegister, ignored);
#if defined(DEBUG)
  temporaries_.Add(range);
#endif
  return range;
}

void FlowGraphAllocator::BlockRegisterLocation(Location loc,
                                               intptr_t from,
                                               intptr_t to,
                                               bool* blocked_registers,
                                               LiveRange** blocking_ranges) {
  if (blocked_registers[loc.register_code()]) {
    return;
  }

  if (blocking_ranges[loc.register_code()] == NULL) {
    Representation ignored = kNoRepresentation;
    LiveRange* range = new LiveRange(kNoVirtualRegister, ignored);
    blocking_ranges[loc.register_code()] = range;
    range->set_assigned_location(loc);
#if defined(DEBUG)
    temporaries_.Add(range);
#endif
  }

  blocking_ranges[loc.register_code()]->AddUseInterval(from, to);
}

// Block location from the start of the instruction to its end.
void FlowGraphAllocator::BlockLocation(Location loc,
                                       intptr_t from,
                                       intptr_t to) {
  if (loc.IsRegister()) {
    BlockRegisterLocation(loc, from, to, blocked_cpu_registers_, cpu_regs_);
  } else if (loc.IsFpuRegister()) {
    BlockRegisterLocation(loc, from, to, blocked_fpu_registers_, fpu_regs_);
  } else {
    UNREACHABLE();
  }
}

void LiveRange::Print() {
  if (first_use_interval() == NULL) {
    return;
  }

  THR_Print("  live range v%" Pd " [%" Pd ", %" Pd ") in ", vreg(), Start(),
            End());
  assigned_location().Print();
  if (spill_slot_.HasStackIndex()) {
    const intptr_t stack_slot =
        -compiler::target::frame_layout.VariableIndexForFrameSlot(
            spill_slot_.stack_index());
    THR_Print(" allocated spill slot: %" Pd "", stack_slot);
  }
  THR_Print("\n");

  SafepointPosition* safepoint = first_safepoint();
  while (safepoint != NULL) {
    THR_Print("    Safepoint [%" Pd "]: ", safepoint->pos());
    safepoint->locs()->stack_bitmap()->Print();
    THR_Print("\n");
    safepoint = safepoint->next();
  }

  UsePosition* use_pos = uses_;
  for (UseInterval* interval = first_use_interval_; interval != NULL;
       interval = interval->next()) {
    THR_Print("    use interval [%" Pd ", %" Pd ")\n", interval->start(),
              interval->end());
    while ((use_pos != NULL) && (use_pos->pos() <= interval->end())) {
      THR_Print("      use at %" Pd "", use_pos->pos());
      if (use_pos->location_slot() != NULL) {
        THR_Print(" as ");
        use_pos->location_slot()->Print();
      }
      THR_Print("\n");
      use_pos = use_pos->next();
    }
  }

  if (next_sibling() != NULL) {
    next_sibling()->Print();
  }
}

void FlowGraphAllocator::PrintLiveRanges() {
#if defined(DEBUG)
  for (intptr_t i = 0; i < temporaries_.length(); i++) {
    temporaries_[i]->Print();
  }
#endif

  for (intptr_t i = 0; i < live_ranges_.length(); i++) {
    if (live_ranges_[i] != NULL) {
      live_ranges_[i]->Print();
    }
  }
}

// Returns true if all uses of the given range inside the
// given loop boundary have Any allocation policy.
static bool HasOnlyUnconstrainedUsesInLoop(LiveRange* range,
                                           intptr_t boundary) {
  UsePosition* use = range->first_use();
  while ((use != NULL) && (use->pos() < boundary)) {
    if (!use->location_slot()->Equals(Location::Any())) {
      return false;
    }
    use = use->next();
  }
  return true;
}

// Returns true if all uses of the given range have Any allocation policy.
static bool HasOnlyUnconstrainedUses(LiveRange* range) {
  UsePosition* use = range->first_use();
  while (use != NULL) {
    if (!use->location_slot()->Equals(Location::Any())) {
      return false;
    }
    use = use->next();
  }
  return true;
}

void FlowGraphAllocator::BuildLiveRanges() {
  const intptr_t block_count = postorder_.length();
  ASSERT(postorder_.Last()->IsGraphEntry());
  BitVector* current_interference_set = NULL;
  Zone* zone = flow_graph_.zone();
  for (intptr_t i = 0; i < (block_count - 1); i++) {
    BlockEntryInstr* block = postorder_[i];
    ASSERT(BlockEntryAt(block->start_pos()) == block);

    // For every SSA value that is live out of this block, create an interval
    // that covers the whole block.  It will be shortened if we encounter a
    // definition of this value in this block.
    for (BitVector::Iterator it(liveness_.GetLiveOutSetAt(i)); !it.Done();
         it.Advance()) {
      LiveRange* range = GetLiveRange(it.Current());
      range->AddUseInterval(block->start_pos(), block->end_pos());
    }

    LoopInfo* loop_info = block->loop_info();
    if ((loop_info != nullptr) && (loop_info->IsBackEdge(block))) {
      BitVector* backedge_interference =
          extra_loop_info_[loop_info->id()]->backedge_interference;
      if (backedge_interference != nullptr) {
        // Restore interference for subsequent backedge a loop
        // (perhaps inner loop's header reset set in the meanwhile).
        current_interference_set = backedge_interference;
      } else {
        // All values flowing into the loop header are live at the
        // back edge and can interfere with phi moves.
        current_interference_set = new (zone)
            BitVector(zone, flow_graph_.max_virtual_register_number());
        current_interference_set->AddAll(
            liveness_.GetLiveInSet(loop_info->header()));
        extra_loop_info_[loop_info->id()]->backedge_interference =
            current_interference_set;
      }
    }

    // Connect outgoing phi-moves that were created in NumberInstructions
    // and find last instruction that contributes to liveness.
    Instruction* current =
        ConnectOutgoingPhiMoves(block, current_interference_set);

    // Now process all instructions in reverse order.
    while (current != block) {
      // Skip parallel moves that we insert while processing instructions.
      if (!current->IsParallelMove()) {
        ProcessOneInstruction(block, current, current_interference_set);
      }
      current = current->previous();
    }

    // Check if any values live into the loop can be spilled for free.
    if (block->IsLoopHeader()) {
      ASSERT(loop_info != nullptr);
      current_interference_set = nullptr;
      for (BitVector::Iterator it(liveness_.GetLiveInSetAt(i)); !it.Done();
           it.Advance()) {
        LiveRange* range = GetLiveRange(it.Current());
        intptr_t loop_end = extra_loop_info_[loop_info->id()]->end;
        if (HasOnlyUnconstrainedUsesInLoop(range, loop_end)) {
          range->MarkHasOnlyUnconstrainedUsesInLoop(loop_info->id());
        }
      }
    }

    if (auto join_entry = block->AsJoinEntry()) {
      ConnectIncomingPhiMoves(join_entry);
    } else if (auto catch_entry = block->AsCatchBlockEntry()) {
      // Process initial definitions.
      ProcessEnvironmentUses(catch_entry, catch_entry);  // For lazy deopt
      for (intptr_t i = 0; i < catch_entry->initial_definitions()->length();
           i++) {
        Definition* defn = (*catch_entry->initial_definitions())[i];
        LiveRange* range = GetLiveRange(defn->ssa_temp_index());
        range->DefineAt(catch_entry->start_pos());  // Defined at block entry.
        ProcessInitialDefinition(defn, range, catch_entry);
      }
    } else if (auto entry = block->AsBlockEntryWithInitialDefs()) {
      ASSERT(block->IsFunctionEntry() || block->IsOsrEntry());
      auto& initial_definitions = *entry->initial_definitions();
      for (intptr_t i = 0; i < initial_definitions.length(); i++) {
        Definition* defn = initial_definitions[i];
        if (defn->HasPairRepresentation()) {
          // The lower bits are pushed after the higher bits
          LiveRange* range =
              GetLiveRange(ToSecondPairVreg(defn->ssa_temp_index()));
          range->AddUseInterval(entry->start_pos(), entry->start_pos() + 2);
          range->DefineAt(entry->start_pos());
          ProcessInitialDefinition(defn, range, entry,
                                   /*second_location_for_definition=*/true);
        }
        LiveRange* range = GetLiveRange(defn->ssa_temp_index());
        range->AddUseInterval(entry->start_pos(), entry->start_pos() + 2);
        range->DefineAt(entry->start_pos());
        ProcessInitialDefinition(defn, range, entry);
      }
    }
  }

  // Process incoming parameters and constants.  Do this after all other
  // instructions so that safepoints for all calls have already been found.
  GraphEntryInstr* graph_entry = flow_graph_.graph_entry();
  for (intptr_t i = 0; i < graph_entry->initial_definitions()->length(); i++) {
    Definition* defn = (*graph_entry->initial_definitions())[i];
    ASSERT(!defn->HasPairRepresentation());
    LiveRange* range = GetLiveRange(defn->ssa_temp_index());
    range->AddUseInterval(graph_entry->start_pos(), graph_entry->end_pos());
    range->DefineAt(graph_entry->start_pos());
    ProcessInitialDefinition(defn, range, graph_entry);
  }
}

void FlowGraphAllocator::SplitInitialDefinitionAt(LiveRange* range,
                                                  intptr_t pos) {
  if (range->End() > pos) {
    LiveRange* tail = range->SplitAt(pos);
    CompleteRange(tail, Location::kRegister);
  }
}

void FlowGraphAllocator::ProcessInitialDefinition(
    Definition* defn,
    LiveRange* range,
    BlockEntryInstr* block,
    bool second_location_for_definition) {
  // Save the range end because it may change below.
  const intptr_t range_end = range->End();

  // TODO(31956): Clean up this code and factor common functionality out.
  // Consider also making a separate [ProcessInitialDefinition] for
  // [CatchBlockEntry]'s.
  if (block->IsCatchBlockEntry()) {
    if (SpecialParameterInstr* param = defn->AsSpecialParameter()) {
      Location loc;
      switch (param->kind()) {
        case SpecialParameterInstr::kException:
          loc = LocationExceptionLocation();
          break;
        case SpecialParameterInstr::kStackTrace:
          loc = LocationStackTraceLocation();
          break;
        default:
          UNREACHABLE();
      }
      range->set_assigned_location(loc);
      AssignSafepoints(defn, range);
      range->finger()->Initialize(range);
      SplitInitialDefinitionAt(range, GetLifetimePosition(block) + 1);
      ConvertAllUses(range);

      // We have exception/stacktrace in a register and need to
      // ensure this register is not available for register allocation during
      // the [CatchBlockEntry] to ensure it's not overwritten.
      if (loc.IsRegister()) {
        BlockLocation(loc, GetLifetimePosition(block),
                      GetLifetimePosition(block) + 1);
      }
      return;
    }
  }

  if (defn->IsParameter()) {
    // Only function entries may have unboxed parameters, possibly making the
    // parameters size different from the number of parameters on 32-bit
    // architectures.
    const intptr_t parameters_size = block->IsFunctionEntry()
                                         ? flow_graph_.direct_parameters_size()
                                         : flow_graph_.num_direct_parameters();
    ParameterInstr* param = defn->AsParameter();
    intptr_t slot_index =
        param->param_offset() + (second_location_for_definition ? -1 : 0);
    ASSERT(slot_index >= 0);
    if (param->base_reg() == FPREG) {
      // Slot index for the rightmost fixed parameter is -1.
      slot_index -= parameters_size;
    } else {
      // Slot index for a "frameless" parameter is reversed.
      ASSERT(param->base_reg() == SPREG);
      ASSERT(slot_index < parameters_size);
      slot_index = parameters_size - 1 - slot_index;
    }

    if (param->base_reg() == FPREG) {
      slot_index =
          compiler::target::frame_layout.FrameSlotForVariableIndex(-slot_index);
    } else {
      ASSERT(param->base_reg() == SPREG);
      slot_index += compiler::target::frame_layout.last_param_from_entry_sp;
    }

    if (param->representation() == kUnboxedInt64 ||
        param->representation() == kTagged) {
      const auto location = Location::StackSlot(slot_index, param->base_reg());
      range->set_assigned_location(location);
      range->set_spill_slot(location);
    } else {
      ASSERT(param->representation() == kUnboxedDouble);
      const auto location =
          Location::DoubleStackSlot(slot_index, param->base_reg());
      range->set_assigned_location(location);
      range->set_spill_slot(location);
    }
  } else if (defn->IsSpecialParameter()) {
    SpecialParameterInstr* param = defn->AsSpecialParameter();
    ASSERT(param->kind() == SpecialParameterInstr::kArgDescriptor);
    Location loc;
    loc = Location::RegisterLocation(ARGS_DESC_REG);
    range->set_assigned_location(loc);
    if (loc.IsRegister()) {
      AssignSafepoints(defn, range);
      if (range->End() > (GetLifetimePosition(block) + 2)) {
        SplitInitialDefinitionAt(range, GetLifetimePosition(block) + 2);
      }
      ConvertAllUses(range);
      BlockLocation(loc, GetLifetimePosition(block),
                    GetLifetimePosition(block) + 2);
      return;
    }
  } else {
    ConstantInstr* constant = defn->AsConstant();
    ASSERT(constant != NULL);
    range->set_assigned_location(Location::Constant(constant));
    range->set_spill_slot(Location::Constant(constant));
  }
  AssignSafepoints(defn, range);
  range->finger()->Initialize(range);
  UsePosition* use =
      range->finger()->FirstRegisterBeneficialUse(block->start_pos());
  if (use != NULL) {
    LiveRange* tail = SplitBetween(range, block->start_pos(), use->pos());
    CompleteRange(tail, defn->RegisterKindForResult());
  }
  ConvertAllUses(range);
  Location spill_slot = range->spill_slot();
  if (spill_slot.IsStackSlot() && spill_slot.base_reg() == FPREG &&
      spill_slot.stack_index() <=
          compiler::target::frame_layout.first_local_from_fp) {
    // On entry to the function, range is stored on the stack above the FP in
    // the same space which is used for spill slots. Update spill slot state to
    // reflect that and prevent register allocator from reusing this space as a
    // spill slot.
    spill_slots_.Add(range_end);
    quad_spill_slots_.Add(false);
    untagged_spill_slots_.Add(false);
    // Note, all incoming parameters are assumed to be tagged.
    MarkAsObjectAtSafepoints(range);
  } else if (defn->IsConstant() && block->IsCatchBlockEntry()) {
    // Constants at catch block entries consume spill slots.
    spill_slots_.Add(range_end);
    quad_spill_slots_.Add(false);
    untagged_spill_slots_.Add(false);
  }
}

static Location::Kind RegisterKindFromPolicy(Location loc) {
  if (loc.policy() == Location::kRequiresFpuRegister) {
    return Location::kFpuRegister;
  } else {
    return Location::kRegister;
  }
}

//
// When describing shape of live ranges in comments below we are going to use
// the following notation:
//
//    B    block entry
//    g g' start and end of goto instruction
//    i i' start and end of any other instruction
//    j j' start and end of any other instruction

//    -  body of a use interval
//    [  start of a use interval
//    )  end of a use interval
//    *  use
//
// For example diagram
//
//           i  i'
//  value  --*--)
//
// can be read as: use interval for value starts somewhere before instruction
// and extends until currently processed instruction, there is a use of value
// at the start of the instruction.
//

Instruction* FlowGraphAllocator::ConnectOutgoingPhiMoves(
    BlockEntryInstr* block,
    BitVector* interfere_at_backedge) {
  Instruction* last = block->last_instruction();

  GotoInstr* goto_instr = last->AsGoto();
  if (goto_instr == NULL) return last;

  // If we have a parallel move here then the successor block must be a
  // join with phis.  The phi inputs contribute uses to each predecessor
  // block (and the phi outputs contribute definitions in the successor
  // block).
  if (!goto_instr->HasParallelMove()) return goto_instr->previous();
  ParallelMoveInstr* parallel_move = goto_instr->parallel_move();

  // All uses are recorded at the position of parallel move preceding goto.
  const intptr_t pos = GetLifetimePosition(goto_instr);

  JoinEntryInstr* join = goto_instr->successor();
  ASSERT(join != NULL);

  // Search for the index of the current block in the predecessors of
  // the join.
  const intptr_t pred_index = join->IndexOfPredecessor(block);

  // Record the corresponding phi input use for each phi.
  intptr_t move_index = 0;
  for (PhiIterator it(join); !it.Done(); it.Advance()) {
    PhiInstr* phi = it.Current();
    Value* val = phi->InputAt(pred_index);
    MoveOperands* move = parallel_move->MoveOperandsAt(move_index++);

    ConstantInstr* constant = val->definition()->AsConstant();
    if (constant != NULL) {
      move->set_src(Location::Constant(constant));
      continue;
    }

    // Expected shape of live ranges:
    //
    //                 g  g'
    //      value    --*
    //
    intptr_t vreg = val->definition()->ssa_temp_index();
    LiveRange* range = GetLiveRange(vreg);
    if (interfere_at_backedge != NULL) interfere_at_backedge->Add(vreg);

    range->AddUseInterval(block->start_pos(), pos);
    range->AddHintedUse(
        pos, move->src_slot(),
        GetLiveRange(phi->ssa_temp_index())->assigned_location_slot());
    move->set_src(Location::PrefersRegister());

    if (val->definition()->HasPairRepresentation()) {
      move = parallel_move->MoveOperandsAt(move_index++);
      vreg = ToSecondPairVreg(vreg);
      range = GetLiveRange(vreg);
      if (interfere_at_backedge != NULL) {
        interfere_at_backedge->Add(vreg);
      }
      range->AddUseInterval(block->start_pos(), pos);
      range->AddHintedUse(pos, move->src_slot(),
                          GetLiveRange(ToSecondPairVreg(phi->ssa_temp_index()))
                              ->assigned_location_slot());
      move->set_src(Location::PrefersRegister());
    }
  }

  // Begin backward iteration with the instruction before the parallel
  // move.
  return goto_instr->previous();
}

void FlowGraphAllocator::ConnectIncomingPhiMoves(JoinEntryInstr* join) {
  // For join blocks we need to add destinations of phi resolution moves
  // to phi's live range so that register allocator will fill them with moves.

  // All uses are recorded at the start position in the block.
  const intptr_t pos = join->start_pos();
  const bool is_loop_header = join->IsLoopHeader();

  intptr_t move_idx = 0;
  for (PhiIterator it(join); !it.Done(); it.Advance()) {
    PhiInstr* phi = it.Current();
    ASSERT(phi != NULL);
    const intptr_t vreg = phi->ssa_temp_index();
    ASSERT(vreg >= 0);
    const bool is_pair_phi = phi->HasPairRepresentation();

    // Expected shape of live range:
    //
    //                 B
    //      phi        [--------
    //
    LiveRange* range = GetLiveRange(vreg);
    range->DefineAt(pos);  // Shorten live range.
    if (is_loop_header) range->mark_loop_phi();

    if (is_pair_phi) {
      LiveRange* second_range = GetLiveRange(ToSecondPairVreg(vreg));
      second_range->DefineAt(pos);  // Shorten live range.
      if (is_loop_header) second_range->mark_loop_phi();
    }

    for (intptr_t pred_idx = 0; pred_idx < phi->InputCount(); pred_idx++) {
      BlockEntryInstr* pred = join->PredecessorAt(pred_idx);
      GotoInstr* goto_instr = pred->last_instruction()->AsGoto();
      ASSERT((goto_instr != NULL) && (goto_instr->HasParallelMove()));
      MoveOperands* move =
          goto_instr->parallel_move()->MoveOperandsAt(move_idx);
      move->set_dest(Location::PrefersRegister());
      range->AddUse(pos, move->dest_slot());
      if (is_pair_phi) {
        LiveRange* second_range = GetLiveRange(ToSecondPairVreg(vreg));
        MoveOperands* second_move =
            goto_instr->parallel_move()->MoveOperandsAt(move_idx + 1);
        second_move->set_dest(Location::PrefersRegister());
        second_range->AddUse(pos, second_move->dest_slot());
      }
    }

    // All phi resolution moves are connected. Phi's live range is
    // complete.
    AssignSafepoints(phi, range);
    CompleteRange(range, phi->RegisterKindForResult());
    if (is_pair_phi) {
      LiveRange* second_range = GetLiveRange(ToSecondPairVreg(vreg));
      AssignSafepoints(phi, second_range);
      CompleteRange(second_range, phi->RegisterKindForResult());
    }

    move_idx += is_pair_phi ? 2 : 1;
  }
}

void FlowGraphAllocator::ProcessEnvironmentUses(BlockEntryInstr* block,
                                                Instruction* current) {
  ASSERT(current->env() != NULL);
  Environment* env = current->env();
  while (env != NULL) {
    // Any value mentioned in the deoptimization environment should survive
    // until the end of instruction but it does not need to be in the register.
    // Expected shape of live range:
    //
    //                 i  i'
    //      value    -----*
    //

    if (env->Length() == 0) {
      env = env->outer();
      continue;
    }

    const intptr_t block_start_pos = block->start_pos();
    const intptr_t use_pos = GetLifetimePosition(current) + 1;

    Location* locations = flow_graph_.zone()->Alloc<Location>(env->Length());

    for (intptr_t i = 0; i < env->Length(); ++i) {
      Value* value = env->ValueAt(i);
      Definition* def = value->definition();
      if (def->HasPairRepresentation()) {
        locations[i] = Location::Pair(Location::Any(), Location::Any());
      } else {
        locations[i] = Location::Any();
      }

      if (def->IsPushArgument()) {
        // Frame size is unknown until after allocation.
        locations[i] = Location::NoLocation();
        continue;
      }

      ConstantInstr* constant = def->AsConstant();
      if (constant != NULL) {
        locations[i] = Location::Constant(constant);
        continue;
      }

      MaterializeObjectInstr* mat = def->AsMaterializeObject();
      if (mat != NULL) {
        // MaterializeObject itself produces no value. But its uses
        // are treated as part of the environment: allocated locations
        // will be used when building deoptimization data.
        locations[i] = Location::NoLocation();
        ProcessMaterializationUses(block, block_start_pos, use_pos, mat);
        continue;
      }

      if (def->HasPairRepresentation()) {
        PairLocation* location_pair = locations[i].AsPairLocation();
        {
          // First live range.
          LiveRange* range = GetLiveRange(def->ssa_temp_index());
          range->AddUseInterval(block_start_pos, use_pos);
          range->AddUse(use_pos, location_pair->SlotAt(0));
        }
        {
          // Second live range.
          LiveRange* range =
              GetLiveRange(ToSecondPairVreg(def->ssa_temp_index()));
          range->AddUseInterval(block_start_pos, use_pos);
          range->AddUse(use_pos, location_pair->SlotAt(1));
        }
      } else {
        LiveRange* range = GetLiveRange(def->ssa_temp_index());
        range->AddUseInterval(block_start_pos, use_pos);
        range->AddUse(use_pos, &locations[i]);
      }
    }

    env->set_locations(locations);
    env = env->outer();
  }
}

void FlowGraphAllocator::ProcessMaterializationUses(
    BlockEntryInstr* block,
    const intptr_t block_start_pos,
    const intptr_t use_pos,
    MaterializeObjectInstr* mat) {
  // Materialization can occur several times in the same environment.
  // Check if we already processed this one.
  if (mat->locations() != NULL) {
    return;  // Already processed.
  }

  // Initialize location for every input of the MaterializeObject instruction.
  Location* locations = flow_graph_.zone()->Alloc<Location>(mat->InputCount());
  mat->set_locations(locations);

  for (intptr_t i = 0; i < mat->InputCount(); ++i) {
    Definition* def = mat->InputAt(i)->definition();

    ConstantInstr* constant = def->AsConstant();
    if (constant != NULL) {
      locations[i] = Location::Constant(constant);
      continue;
    }

    if (def->HasPairRepresentation()) {
      locations[i] = Location::Pair(Location::Any(), Location::Any());
      PairLocation* location_pair = locations[i].AsPairLocation();
      {
        // First live range.
        LiveRange* range = GetLiveRange(def->ssa_temp_index());
        range->AddUseInterval(block_start_pos, use_pos);
        range->AddUse(use_pos, location_pair->SlotAt(0));
      }
      {
        // Second live range.
        LiveRange* range =
            GetLiveRange(ToSecondPairVreg(def->ssa_temp_index()));
        range->AddUseInterval(block_start_pos, use_pos);
        range->AddUse(use_pos, location_pair->SlotAt(1));
      }
    } else if (def->IsMaterializeObject()) {
      locations[i] = Location::NoLocation();
      ProcessMaterializationUses(block, block_start_pos, use_pos,
                                 def->AsMaterializeObject());
    } else {
      locations[i] = Location::Any();
      LiveRange* range = GetLiveRange(def->ssa_temp_index());
      range->AddUseInterval(block_start_pos, use_pos);
      range->AddUse(use_pos, &locations[i]);
    }
  }
}

void FlowGraphAllocator::ProcessOneInput(BlockEntryInstr* block,
                                         intptr_t pos,
                                         Location* in_ref,
                                         Value* input,
                                         intptr_t vreg,
                                         RegisterSet* live_registers) {
  ASSERT(in_ref != NULL);
  ASSERT(!in_ref->IsPairLocation());
  ASSERT(input != NULL);
  ASSERT(block != NULL);
  LiveRange* range = GetLiveRange(vreg);
  if (in_ref->IsMachineRegister()) {
    // Input is expected in a fixed register. Expected shape of
    // live ranges:
    //
    //                 j' i  i'
    //      value    --*
    //      register   [-----)
    //
    if (live_registers != NULL) {
      live_registers->Add(*in_ref, range->representation());
    }
    MoveOperands* move = AddMoveAt(pos - 1, *in_ref, Location::Any());
    ASSERT(!in_ref->IsRegister() ||
           ((1 << in_ref->reg()) & kDartAvailableCpuRegs) != 0);
    BlockLocation(*in_ref, pos - 1, pos + 1);
    range->AddUseInterval(block->start_pos(), pos - 1);
    range->AddHintedUse(pos - 1, move->src_slot(), in_ref);
  } else if (in_ref->IsUnallocated()) {
    if (in_ref->policy() == Location::kWritableRegister) {
      // Writable unallocated input. Expected shape of
      // live ranges:
      //
      //                 i  i'
      //      value    --*
      //      temp       [--)
      MoveOperands* move = AddMoveAt(pos, Location::RequiresRegister(),
                                     Location::PrefersRegister());

      // Add uses to the live range of the input.
      range->AddUseInterval(block->start_pos(), pos);
      range->AddUse(pos, move->src_slot());

      // Create live range for the temporary.
      LiveRange* temp = MakeLiveRangeForTemporary();
      temp->AddUseInterval(pos, pos + 1);
      temp->AddHintedUse(pos, in_ref, move->src_slot());
      temp->AddUse(pos, move->dest_slot());
      *in_ref = Location::RequiresRegister();
      CompleteRange(temp, RegisterKindFromPolicy(*in_ref));
    } else {
      // Normal unallocated input. Expected shape of
      // live ranges:
      //
      //                 i  i'
      //      value    -----*
      //
      range->AddUseInterval(block->start_pos(), pos + 1);
      range->AddUse(pos + 1, in_ref);
    }
  } else {
    ASSERT(in_ref->IsConstant());
  }
}

void FlowGraphAllocator::ProcessOneOutput(BlockEntryInstr* block,
                                          intptr_t pos,
                                          Location* out,
                                          Definition* def,
                                          intptr_t vreg,
                                          bool output_same_as_first_input,
                                          Location* in_ref,
                                          Definition* input,
                                          intptr_t input_vreg,
                                          BitVector* interference_set) {
  ASSERT(out != NULL);
  ASSERT(!out->IsPairLocation());
  ASSERT(def != NULL);
  ASSERT(block != NULL);

  LiveRange* range =
      vreg >= 0 ? GetLiveRange(vreg) : MakeLiveRangeForTemporary();

  // Process output and finalize its liverange.
  if (out->IsMachineRegister()) {
    // Fixed output location. Expected shape of live range:
    //
    //                    i  i' j  j'
    //    register        [--)
    //    output             [-------
    //
    ASSERT(!out->IsRegister() ||
           ((1 << out->reg()) & kDartAvailableCpuRegs) != 0);
    BlockLocation(*out, pos, pos + 1);

    if (range->vreg() == kTempVirtualRegister) return;

    // We need to emit move connecting fixed register with another location
    // that will be allocated for this output's live range.
    // Special case: fixed output followed by a fixed input last use.
    UsePosition* use = range->first_use();

    // If the value has no uses we don't need to allocate it.
    if (use == NULL) return;

    // Connect fixed output to all inputs that immediately follow to avoid
    // allocating an intermediary register.
    for (; use != nullptr; use = use->next()) {
      if (use->pos() == (pos + 1)) {
        // Allocate and then drop this use.
        ASSERT(use->location_slot()->IsUnallocated());
        *(use->location_slot()) = *out;
        range->set_first_use(use->next());
      } else {
        ASSERT(use->pos() > (pos + 1));  // sorted
        break;
      }
    }

    // Shorten live range to the point of definition, this might make the range
    // empty (if the only use immediately follows). If range is not empty add
    // move from a fixed register to an unallocated location.
    range->DefineAt(pos + 1);
    if (range->Start() == range->End()) return;

    MoveOperands* move = AddMoveAt(pos + 1, Location::Any(), *out);
    range->AddHintedUse(pos + 1, move->dest_slot(), out);
  } else if (output_same_as_first_input) {
    ASSERT(in_ref != NULL);
    ASSERT(input != NULL);
    // Output register will contain a value of the first input at instruction's
    // start. Expected shape of live ranges:
    //
    //                 i  i'
    //    input #0   --*
    //    output       [----
    //
    ASSERT(in_ref->Equals(Location::RequiresRegister()) ||
           in_ref->Equals(Location::RequiresFpuRegister()));
    *out = *in_ref;
    // Create move that will copy value between input and output.
    MoveOperands* move =
        AddMoveAt(pos, Location::RequiresRegister(), Location::Any());

    // Add uses to the live range of the input.
    LiveRange* input_range = GetLiveRange(input_vreg);
    input_range->AddUseInterval(block->start_pos(), pos);
    input_range->AddUse(pos, move->src_slot());

    // Shorten output live range to the point of definition and add both input
    // and output uses slots to be filled by allocator.
    range->DefineAt(pos);
    range->AddHintedUse(pos, out, move->src_slot());
    range->AddUse(pos, move->dest_slot());
    range->AddUse(pos, in_ref);

    if ((interference_set != NULL) && (range->vreg() >= 0) &&
        interference_set->Contains(range->vreg())) {
      interference_set->Add(input->ssa_temp_index());
    }
  } else {
    // Normal unallocated location that requires a register. Expected shape of
    // live range:
    //
    //                    i  i'
    //    output          [-------
    //
    ASSERT(out->Equals(Location::RequiresRegister()) ||
           out->Equals(Location::RequiresFpuRegister()));

    // Shorten live range to the point of definition and add use to be filled by
    // allocator.
    range->DefineAt(pos);
    range->AddUse(pos, out);
  }

  AssignSafepoints(def, range);
  CompleteRange(range, def->RegisterKindForResult());
}

// Create and update live ranges corresponding to instruction's inputs,
// temporaries and output.
void FlowGraphAllocator::ProcessOneInstruction(BlockEntryInstr* block,
                                               Instruction* current,
                                               BitVector* interference_set) {
  LocationSummary* locs = current->locs();

  Definition* def = current->AsDefinition();
  if ((def != NULL) && (def->AsConstant() != NULL)) {
    ASSERT(!def->HasPairRepresentation());
    LiveRange* range = (def->ssa_temp_index() != -1)
                           ? GetLiveRange(def->ssa_temp_index())
                           : NULL;

    // Drop definitions of constants that have no uses.
    if ((range == NULL) || (range->first_use() == NULL)) {
      locs->set_out(0, Location::NoLocation());
      return;
    }

    // If this constant has only unconstrained uses convert them all
    // to use the constant directly and drop this definition.
    // TODO(vegorov): improve allocation when we have enough registers to keep
    // constants used in the loop in them.
    if (HasOnlyUnconstrainedUses(range)) {
      ConstantInstr* constant_instr = def->AsConstant();
      range->set_assigned_location(Location::Constant(constant_instr));
      range->set_spill_slot(Location::Constant(constant_instr));
      range->finger()->Initialize(range);
      ConvertAllUses(range);

      locs->set_out(0, Location::NoLocation());
      return;
    }
  }

  const intptr_t pos = GetLifetimePosition(current);
  ASSERT(IsInstructionStartPosition(pos));

  ASSERT(locs->input_count() == current->InputCount());

  // Normalize same-as-first-input output if input is specified as
  // fixed register.
  if (locs->out(0).IsUnallocated() &&
      (locs->out(0).policy() == Location::kSameAsFirstInput)) {
    if (locs->in(0).IsPairLocation()) {
      // Pair input, pair output.
      PairLocation* in_pair = locs->in(0).AsPairLocation();
      ASSERT(in_pair->At(0).IsMachineRegister() ==
             in_pair->At(1).IsMachineRegister());
      if (in_pair->At(0).IsMachineRegister() &&
          in_pair->At(1).IsMachineRegister()) {
        locs->set_out(0, Location::Pair(in_pair->At(0), in_pair->At(1)));
      }
    } else if (locs->in(0).IsMachineRegister()) {
      // Single input, single output.
      locs->set_out(0, locs->in(0));
    }
  }

  const bool output_same_as_first_input =
      locs->out(0).IsUnallocated() &&
      (locs->out(0).policy() == Location::kSameAsFirstInput);

  // Output is same as first input which is a pair.
  if (output_same_as_first_input && locs->in(0).IsPairLocation()) {
    // Make out into a PairLocation.
    locs->set_out(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  }
  // Add uses from the deoptimization environment.
  if (current->env() != NULL) ProcessEnvironmentUses(block, current);

  // Process inputs.
  // Skip the first input if output is specified with kSameAsFirstInput policy,
  // they will be processed together at the very end.
  {
    for (intptr_t j = output_same_as_first_input ? 1 : 0;
         j < locs->input_count(); j++) {
      // Determine if we are dealing with a value pair, and if so, whether
      // the location is the first register or second register.
      Value* input = current->InputAt(j);
      Location* in_ref = locs->in_slot(j);
      RegisterSet* live_registers = NULL;
      if (locs->HasCallOnSlowPath()) {
        live_registers = locs->live_registers();
      }
      if (in_ref->IsPairLocation()) {
        ASSERT(input->definition()->HasPairRepresentation());
        PairLocation* pair = in_ref->AsPairLocation();
        const intptr_t vreg = input->definition()->ssa_temp_index();
        // Each element of the pair is assigned it's own virtual register number
        // and is allocated its own LiveRange.
        ProcessOneInput(block, pos, pair->SlotAt(0), input, vreg,
                        live_registers);
        ProcessOneInput(block, pos, pair->SlotAt(1), input,
                        ToSecondPairVreg(vreg), live_registers);
      } else {
        ProcessOneInput(block, pos, in_ref, input,
                        input->definition()->ssa_temp_index(), live_registers);
      }
    }
  }

  // Process temps.
  for (intptr_t j = 0; j < locs->temp_count(); j++) {
    // Expected shape of live range:
    //
    //              i  i'
    //              [--)
    //

    Location temp = locs->temp(j);
    // We do not support pair locations for temporaries.
    ASSERT(!temp.IsPairLocation());
    if (temp.IsMachineRegister()) {
      ASSERT(!temp.IsRegister() ||
             ((1 << temp.reg()) & kDartAvailableCpuRegs) != 0);
      BlockLocation(temp, pos, pos + 1);
    } else if (temp.IsUnallocated()) {
      LiveRange* range = MakeLiveRangeForTemporary();
      range->AddUseInterval(pos, pos + 1);
      range->AddUse(pos, locs->temp_slot(j));
      CompleteRange(range, RegisterKindFromPolicy(temp));
    } else {
      UNREACHABLE();
    }
  }

// Block all allocatable registers for calls.
  if (locs->always_calls() && !locs->callee_safe_call()) {
    // Expected shape of live range:
    //
    //              i  i'
    //              [--)
    //
    // The stack bitmap describes the position i.
    for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
      BlockLocation(Location::RegisterLocation(static_cast<Register>(reg)), pos,
                    pos + 1);
    }

    for (intptr_t reg = 0; reg < kNumberOfFpuRegisters; reg++) {
      BlockLocation(
          Location::FpuRegisterLocation(static_cast<FpuRegister>(reg)), pos,
          pos + 1);
    }

#if defined(DEBUG)
    // Verify that temps, inputs and output were specified as fixed
    // locations.  Every register is blocked now so attempt to
    // allocate will go on the stack.
    for (intptr_t j = 0; j < locs->temp_count(); j++) {
      ASSERT(!locs->temp(j).IsPairLocation());
      ASSERT(!locs->temp(j).IsUnallocated());
    }

    for (intptr_t j = 0; j < locs->input_count(); j++) {
      if (locs->in(j).IsPairLocation()) {
        PairLocation* pair = locs->in_slot(j)->AsPairLocation();
        ASSERT(!pair->At(0).IsUnallocated() ||
               pair->At(0).policy() == Location::kAny);
        ASSERT(!pair->At(1).IsUnallocated() ||
               pair->At(1).policy() == Location::kAny);
      } else {
        ASSERT(!locs->in(j).IsUnallocated() ||
               locs->in(j).policy() == Location::kAny);
      }
    }

    if (locs->out(0).IsPairLocation()) {
      PairLocation* pair = locs->out_slot(0)->AsPairLocation();
      ASSERT(!pair->At(0).IsUnallocated());
      ASSERT(!pair->At(1).IsUnallocated());
    } else {
      ASSERT(!locs->out(0).IsUnallocated());
    }
#endif
  }

  if (locs->can_call()) {
    safepoints_.Add(current);
  }

  if (def == NULL) {
    ASSERT(locs->out(0).IsInvalid());
    return;
  }

  if (locs->out(0).IsInvalid()) {
    ASSERT(def->ssa_temp_index() < 0);
    return;
  }

  ASSERT(locs->output_count() == 1);
  Location* out = locs->out_slot(0);
  if (out->IsPairLocation()) {
    ASSERT(def->HasPairRepresentation());
    PairLocation* pair = out->AsPairLocation();
    if (output_same_as_first_input) {
      ASSERT(locs->in_slot(0)->IsPairLocation());
      PairLocation* in_pair = locs->in_slot(0)->AsPairLocation();
      Definition* input = current->InputAt(0)->definition();
      ASSERT(input->HasPairRepresentation());
      // Each element of the pair is assigned it's own virtual register number
      // and is allocated its own LiveRange.
      ProcessOneOutput(block, pos,             // BlockEntry, seq.
                       pair->SlotAt(0), def,   // (output) Location, Definition.
                       def->ssa_temp_index(),  // (output) virtual register.
                       true,                   // output mapped to first input.
                       in_pair->SlotAt(0), input,  // (input) Location, Def.
                       input->ssa_temp_index(),    // (input) virtual register.
                       interference_set);
      ProcessOneOutput(
          block, pos, pair->SlotAt(1), def,
          ToSecondPairVreg(def->ssa_temp_index()), true, in_pair->SlotAt(1),
          input, ToSecondPairVreg(input->ssa_temp_index()), interference_set);
    } else {
      // Each element of the pair is assigned it's own virtual register number
      // and is allocated its own LiveRange.
      ProcessOneOutput(block, pos, pair->SlotAt(0), def, def->ssa_temp_index(),
                       false,           // output is not mapped to first input.
                       NULL, NULL, -1,  // First input not needed.
                       interference_set);
      ProcessOneOutput(block, pos, pair->SlotAt(1), def,
                       ToSecondPairVreg(def->ssa_temp_index()), false, NULL,
                       NULL, -1, interference_set);
    }
  } else {
    if (output_same_as_first_input) {
      Location* in_ref = locs->in_slot(0);
      Definition* input = current->InputAt(0)->definition();
      ASSERT(!in_ref->IsPairLocation());
      ProcessOneOutput(block, pos,             // BlockEntry, Instruction, seq.
                       out, def,               // (output) Location, Definition.
                       def->ssa_temp_index(),  // (output) virtual register.
                       true,                   // output mapped to first input.
                       in_ref, input,          // (input) Location, Def.
                       input->ssa_temp_index(),  // (input) virtual register.
                       interference_set);
    } else {
      ProcessOneOutput(block, pos, out, def, def->ssa_temp_index(),
                       false,           // output is not mapped to first input.
                       NULL, NULL, -1,  // First input not needed.
                       interference_set);
    }
  }
}

static ParallelMoveInstr* CreateParallelMoveBefore(Instruction* instr,
                                                   intptr_t pos) {
  ASSERT(pos > 0);
  Instruction* prev = instr->previous();
  ParallelMoveInstr* move = prev->AsParallelMove();
  if ((move == NULL) ||
      (FlowGraphAllocator::GetLifetimePosition(move) != pos)) {
    move = new ParallelMoveInstr();
    prev->LinkTo(move);
    move->LinkTo(instr);
    FlowGraphAllocator::SetLifetimePosition(move, pos);
  }
  return move;
}

static ParallelMoveInstr* CreateParallelMoveAfter(Instruction* instr,
                                                  intptr_t pos) {
  Instruction* next = instr->next();
  if (next->IsParallelMove() &&
      (FlowGraphAllocator::GetLifetimePosition(next) == pos)) {
    return next->AsParallelMove();
  }
  return CreateParallelMoveBefore(next, pos);
}

// Linearize the control flow graph.  The chosen order will be used by the
// linear-scan register allocator.  Number most instructions with a pair of
// numbers representing lifetime positions.  Introduce explicit parallel
// move instructions in the predecessors of join nodes.  The moves are used
// for phi resolution.
void FlowGraphAllocator::NumberInstructions() {
  intptr_t pos = 0;

  // The basic block order is reverse postorder.
  const intptr_t block_count = postorder_.length();
  for (intptr_t i = block_count - 1; i >= 0; i--) {
    BlockEntryInstr* block = postorder_[i];

    instructions_.Add(block);
    block_entries_.Add(block);
    block->set_start_pos(pos);
    SetLifetimePosition(block, pos);
    pos += 2;

    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      // Do not assign numbers to parallel move instructions.
      if (!current->IsParallelMove()) {
        instructions_.Add(current);
        block_entries_.Add(block);
        SetLifetimePosition(current, pos);
        pos += 2;
      }
    }
    block->set_end_pos(pos);
  }

  // Create parallel moves in join predecessors.  This must be done after
  // all instructions are numbered.
  for (intptr_t i = block_count - 1; i >= 0; i--) {
    BlockEntryInstr* block = postorder_[i];

    // For join entry predecessors create phi resolution moves if
    // necessary. They will be populated by the register allocator.
    JoinEntryInstr* join = block->AsJoinEntry();
    if (join != NULL) {
      intptr_t move_count = 0;
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        move_count += it.Current()->HasPairRepresentation() ? 2 : 1;
      }
      for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
        // Insert the move between the last two instructions of the
        // predecessor block (all such blocks have at least two instructions:
        // the block entry and goto instructions.)
        Instruction* last = block->PredecessorAt(i)->last_instruction();
        ASSERT(last->IsGoto());

        ParallelMoveInstr* move = last->AsGoto()->GetParallelMove();

        // Populate the ParallelMove with empty moves.
        for (intptr_t j = 0; j < move_count; j++) {
          move->AddMove(Location::NoLocation(), Location::NoLocation());
        }
      }
    }
  }

  // Prepare some extra information for each loop.
  Zone* zone = flow_graph_.zone();
  const LoopHierarchy& loop_hierarchy = flow_graph_.loop_hierarchy();
  const intptr_t num_loops = loop_hierarchy.num_loops();
  for (intptr_t i = 0; i < num_loops; i++) {
    extra_loop_info_.Add(
        ComputeExtraLoopInfo(zone, loop_hierarchy.headers()[i]->loop_info()));
  }
}

Instruction* FlowGraphAllocator::InstructionAt(intptr_t pos) const {
  return instructions_[pos / 2];
}

BlockEntryInstr* FlowGraphAllocator::BlockEntryAt(intptr_t pos) const {
  return block_entries_[pos / 2];
}

bool FlowGraphAllocator::IsBlockEntry(intptr_t pos) const {
  return IsInstructionStartPosition(pos) && InstructionAt(pos)->IsBlockEntry();
}

void AllocationFinger::Initialize(LiveRange* range) {
  first_pending_use_interval_ = range->first_use_interval();
  first_register_use_ = range->first_use();
  first_register_beneficial_use_ = range->first_use();
  first_hinted_use_ = range->first_use();
}

bool AllocationFinger::Advance(const intptr_t start) {
  UseInterval* a = first_pending_use_interval_;
  while (a != NULL && a->end() <= start)
    a = a->next();
  first_pending_use_interval_ = a;
  return (first_pending_use_interval_ == NULL);
}

Location AllocationFinger::FirstHint() {
  UsePosition* use = first_hinted_use_;

  while (use != NULL) {
    if (use->HasHint()) return use->hint();
    use = use->next();
  }

  return Location::NoLocation();
}

static UsePosition* FirstUseAfter(UsePosition* use, intptr_t after) {
  while ((use != NULL) && (use->pos() < after)) {
    use = use->next();
  }
  return use;
}

UsePosition* AllocationFinger::FirstRegisterUse(intptr_t after) {
  for (UsePosition* use = FirstUseAfter(first_register_use_, after);
       use != NULL; use = use->next()) {
    Location* loc = use->location_slot();
    if (loc->IsUnallocated() &&
        ((loc->policy() == Location::kRequiresRegister) ||
         (loc->policy() == Location::kRequiresFpuRegister))) {
      first_register_use_ = use;
      return use;
    }
  }
  return NULL;
}

UsePosition* AllocationFinger::FirstRegisterBeneficialUse(intptr_t after) {
  for (UsePosition* use = FirstUseAfter(first_register_beneficial_use_, after);
       use != NULL; use = use->next()) {
    Location* loc = use->location_slot();
    if (loc->IsUnallocated() && loc->IsRegisterBeneficial()) {
      first_register_beneficial_use_ = use;
      return use;
    }
  }
  return NULL;
}

UsePosition* AllocationFinger::FirstInterferingUse(intptr_t after) {
  if (IsInstructionEndPosition(after)) {
    // If after is a position at the end of the instruction disregard
    // any use occurring at it.
    after += 1;
  }
  return FirstRegisterUse(after);
}

void AllocationFinger::UpdateAfterSplit(intptr_t first_use_after_split_pos) {
  if ((first_register_use_ != NULL) &&
      (first_register_use_->pos() >= first_use_after_split_pos)) {
    first_register_use_ = NULL;
  }

  if ((first_register_beneficial_use_ != NULL) &&
      (first_register_beneficial_use_->pos() >= first_use_after_split_pos)) {
    first_register_beneficial_use_ = NULL;
  }
}

intptr_t UseInterval::Intersect(UseInterval* other) {
  if (this->start() <= other->start()) {
    if (other->start() < this->end()) return other->start();
  } else if (this->start() < other->end()) {
    return this->start();
  }
  return kIllegalPosition;
}

static intptr_t FirstIntersection(UseInterval* a, UseInterval* u) {
  while (a != NULL && u != NULL) {
    const intptr_t pos = a->Intersect(u);
    if (pos != kIllegalPosition) return pos;

    if (a->start() < u->start()) {
      a = a->next();
    } else {
      u = u->next();
    }
  }

  return kMaxPosition;
}

template <typename PositionType>
PositionType* SplitListOfPositions(PositionType** head,
                                   intptr_t split_pos,
                                   bool split_at_start) {
  PositionType* last_before_split = NULL;
  PositionType* pos = *head;
  if (split_at_start) {
    while ((pos != NULL) && (pos->pos() < split_pos)) {
      last_before_split = pos;
      pos = pos->next();
    }
  } else {
    while ((pos != NULL) && (pos->pos() <= split_pos)) {
      last_before_split = pos;
      pos = pos->next();
    }
  }

  if (last_before_split == NULL) {
    *head = NULL;
  } else {
    last_before_split->set_next(NULL);
  }

  return pos;
}

LiveRange* LiveRange::SplitAt(intptr_t split_pos) {
  if (Start() == split_pos) return this;

  UseInterval* interval = finger_.first_pending_use_interval();
  if (interval == NULL) {
    finger_.Initialize(this);
    interval = finger_.first_pending_use_interval();
  }

  ASSERT(split_pos < End());

  // Corner case. Split position can be inside the a lifetime hole or at its
  // end. We need to start over to find the previous interval.
  if (split_pos <= interval->start()) interval = first_use_interval_;

  UseInterval* last_before_split = NULL;
  while (interval->end() <= split_pos) {
    last_before_split = interval;
    interval = interval->next();
  }

  const bool split_at_start = (interval->start() == split_pos);

  UseInterval* first_after_split = interval;
  if (!split_at_start && interval->Contains(split_pos)) {
    first_after_split =
        new UseInterval(split_pos, interval->end(), interval->next());
    interval->end_ = split_pos;
    interval->next_ = first_after_split;
    last_before_split = interval;
  }

  ASSERT(last_before_split != NULL);
  ASSERT(last_before_split->next() == first_after_split);
  ASSERT(last_before_split->end() <= split_pos);
  ASSERT(split_pos <= first_after_split->start());

  UsePosition* first_use_after_split =
      SplitListOfPositions(&uses_, split_pos, split_at_start);

  SafepointPosition* first_safepoint_after_split =
      SplitListOfPositions(&first_safepoint_, split_pos, split_at_start);

  UseInterval* last_use_interval = (last_before_split == last_use_interval_)
                                       ? first_after_split
                                       : last_use_interval_;
  next_sibling_ = new LiveRange(vreg(), representation(), first_use_after_split,
                                first_after_split, last_use_interval,
                                first_safepoint_after_split, next_sibling_);

  TRACE_ALLOC(THR_Print("  split sibling [%" Pd ", %" Pd ")\n",
                        next_sibling_->Start(), next_sibling_->End()));

  last_use_interval_ = last_before_split;
  last_use_interval_->next_ = NULL;

  if (first_use_after_split != NULL) {
    finger_.UpdateAfterSplit(first_use_after_split->pos());
  }

  return next_sibling_;
}

LiveRange* FlowGraphAllocator::SplitBetween(LiveRange* range,
                                            intptr_t from,
                                            intptr_t to) {
  TRACE_ALLOC(THR_Print("split v%" Pd " [%" Pd ", %" Pd ") between [%" Pd
                        ", %" Pd ")\n",
                        range->vreg(), range->Start(), range->End(), from, to));

  intptr_t split_pos = kIllegalPosition;

  BlockEntryInstr* split_block_entry = BlockEntryAt(to);
  ASSERT(split_block_entry == InstructionAt(to)->GetBlock());

  if (from < GetLifetimePosition(split_block_entry)) {
    // Interval [from, to) spans multiple blocks.

    // If the last block is inside a loop, prefer splitting at the outermost
    // loop's header that follows the definition. Note that, as illustrated
    // below, if the potential split S linearly appears inside a loop, even
    // though it technically does not belong to the natural loop, we still
    // prefer splitting at the header H. Splitting in the "middle" of the loop
    // would disconnect the prefix of the loop from any block X that follows,
    // increasing the chance of "disconnected" allocations.
    //
    //            +--------------------+
    //            v                    |
    //            |loop|          |loop|
    // . . . . . . . . . . . . . . . . . . . . .
    //     def------------use     -----------
    //            ^      ^        ^
    //            H      S        X
    LoopInfo* loop_info = split_block_entry->loop_info();
    if (loop_info == nullptr) {
      const LoopHierarchy& loop_hierarchy = flow_graph_.loop_hierarchy();
      const intptr_t num_loops = loop_hierarchy.num_loops();
      for (intptr_t i = 0; i < num_loops; i++) {
        if (extra_loop_info_[i]->start < to && to < extra_loop_info_[i]->end) {
          // Split loop found!
          loop_info = loop_hierarchy.headers()[i]->loop_info();
          break;
        }
      }
    }
    while ((loop_info != nullptr) &&
           (from < GetLifetimePosition(loop_info->header()))) {
      split_block_entry = loop_info->header();
      loop_info = loop_info->outer();
      TRACE_ALLOC(THR_Print("  move back to loop header B%" Pd " at %" Pd "\n",
                            split_block_entry->block_id(),
                            GetLifetimePosition(split_block_entry)));
    }

    // Split at block's start.
    split_pos = GetLifetimePosition(split_block_entry);
  } else {
    // Interval [from, to) is contained inside a single block.

    // Split at position corresponding to the end of the previous
    // instruction.
    split_pos = ToInstructionStart(to) - 1;
  }

  ASSERT(split_pos != kIllegalPosition);
  ASSERT(from < split_pos);

  return range->SplitAt(split_pos);
}

void FlowGraphAllocator::SpillBetween(LiveRange* range,
                                      intptr_t from,
                                      intptr_t to) {
  ASSERT(from < to);
  TRACE_ALLOC(THR_Print("spill v%" Pd " [%" Pd ", %" Pd ") "
                        "between [%" Pd ", %" Pd ")\n",
                        range->vreg(), range->Start(), range->End(), from, to));
  LiveRange* tail = range->SplitAt(from);

  if (tail->Start() < to) {
    // There is an intersection of tail and [from, to).
    LiveRange* tail_tail = SplitBetween(tail, tail->Start(), to);
    Spill(tail);
    AddToUnallocated(tail_tail);
  } else {
    // No intersection between tail and [from, to).
    AddToUnallocated(tail);
  }
}

void FlowGraphAllocator::SpillAfter(LiveRange* range, intptr_t from) {
  TRACE_ALLOC(THR_Print("spill v%" Pd " [%" Pd ", %" Pd ") after %" Pd "\n",
                        range->vreg(), range->Start(), range->End(), from));

  // When spilling the value inside the loop check if this spill can
  // be moved outside.
  LoopInfo* loop_info = BlockEntryAt(from)->loop_info();
  if (loop_info != nullptr) {
    if ((range->Start() <= loop_info->header()->start_pos()) &&
        RangeHasOnlyUnconstrainedUsesInLoop(range, loop_info->id())) {
      ASSERT(loop_info->header()->start_pos() <= from);
      from = loop_info->header()->start_pos();
      TRACE_ALLOC(
          THR_Print("  moved spill position to loop header %" Pd "\n", from));
    }
  }

  LiveRange* tail = range->SplitAt(from);
  Spill(tail);
}

void FlowGraphAllocator::AllocateSpillSlotFor(LiveRange* range) {
  ASSERT(range->spill_slot().IsInvalid());

  // Compute range start and end.
  LiveRange* last_sibling = range;
  while (last_sibling->next_sibling() != NULL) {
    last_sibling = last_sibling->next_sibling();
  }

  const intptr_t start = range->Start();
  const intptr_t end = last_sibling->End();

  // During fpu register allocation spill slot indices are computed in terms of
  // double (64bit) stack slots. We treat quad stack slot (128bit) as a
  // consecutive pair of two double spill slots.
  // Special care is taken to never allocate the same index to both
  // double and quad spill slots as it complicates disambiguation during
  // parallel move resolution.
  const bool need_quad = (register_kind_ == Location::kFpuRegister) &&
                         ((range->representation() == kUnboxedFloat32x4) ||
                          (range->representation() == kUnboxedInt32x4) ||
                          (range->representation() == kUnboxedFloat64x2));
  const bool need_untagged = (register_kind_ == Location::kRegister) &&
                             ((range->representation() == kUntagged));

  // Search for a free spill slot among allocated: the value in it should be
  // dead and its type should match (e.g. it should not be a part of the quad if
  // we are allocating normal double slot).
  // For CPU registers we need to take reserved slots for try-catch into
  // account.
  intptr_t idx = register_kind_ == Location::kRegister
                     ? flow_graph_.graph_entry()->fixed_slot_count()
                     : 0;
  for (; idx < spill_slots_.length(); idx++) {
    if ((need_quad == quad_spill_slots_[idx]) &&
        (need_untagged == untagged_spill_slots_[idx]) &&
        (spill_slots_[idx] <= start)) {
      break;
    }
  }

  while (idx > spill_slots_.length()) {
    spill_slots_.Add(kMaxPosition);
    quad_spill_slots_.Add(false);
    untagged_spill_slots_.Add(false);
  }

  if (idx == spill_slots_.length()) {
    idx = spill_slots_.length();

    // No free spill slot found. Allocate a new one.
    spill_slots_.Add(0);
    quad_spill_slots_.Add(need_quad);
    untagged_spill_slots_.Add(need_untagged);
    if (need_quad) {  // Allocate two double stack slots if we need quad slot.
      spill_slots_.Add(0);
      quad_spill_slots_.Add(need_quad);
      untagged_spill_slots_.Add(need_untagged);
    }
  }

  // Set spill slot expiration boundary to the live range's end.
  spill_slots_[idx] = end;
  if (need_quad) {
    ASSERT(quad_spill_slots_[idx] && quad_spill_slots_[idx + 1]);
    idx++;  // Use the higher index it corresponds to the lower stack address.
    spill_slots_[idx] = end;
  } else {
    ASSERT(!quad_spill_slots_[idx]);
  }

  // Assign spill slot to the range.
  if (register_kind_ == Location::kRegister) {
    const intptr_t slot_index =
        compiler::target::frame_layout.FrameSlotForVariableIndex(-idx);
    range->set_spill_slot(Location::StackSlot(slot_index, FPREG));
  } else {
    // We use the index of the slot with the lowest address as an index for the
    // FPU register spill slot. In terms of indexes this relation is inverted:
    // so we have to take the highest index.
    const intptr_t slot_idx =
        compiler::target::frame_layout.FrameSlotForVariableIndex(
            -(cpu_spill_slot_count_ + idx * kDoubleSpillFactor +
              (kDoubleSpillFactor - 1)));

    Location location;
    if ((range->representation() == kUnboxedFloat32x4) ||
        (range->representation() == kUnboxedInt32x4) ||
        (range->representation() == kUnboxedFloat64x2)) {
      ASSERT(need_quad);
      location = Location::QuadStackSlot(slot_idx, FPREG);
    } else {
      ASSERT(range->representation() == kUnboxedFloat ||
             range->representation() == kUnboxedDouble);
      location = Location::DoubleStackSlot(slot_idx, FPREG);
    }
    range->set_spill_slot(location);
  }

  spilled_.Add(range);
}

void FlowGraphAllocator::MarkAsObjectAtSafepoints(LiveRange* range) {
  Location spill_slot = range->spill_slot();
  intptr_t stack_index = spill_slot.stack_index();
  if (spill_slot.base_reg() == FPREG) {
    stack_index = -compiler::target::frame_layout.VariableIndexForFrameSlot(
        spill_slot.stack_index());
  }
  ASSERT(stack_index >= 0);
  while (range != NULL) {
    for (SafepointPosition* safepoint = range->first_safepoint();
         safepoint != NULL; safepoint = safepoint->next()) {
      // Mark the stack slot as having an object.
      safepoint->locs()->SetStackBit(stack_index);
    }
    range = range->next_sibling();
  }
}

void FlowGraphAllocator::Spill(LiveRange* range) {
  LiveRange* parent = GetLiveRange(range->vreg());
  if (parent->spill_slot().IsInvalid()) {
    AllocateSpillSlotFor(parent);
    if (range->representation() == kTagged) {
      MarkAsObjectAtSafepoints(parent);
    }
  }
  range->set_assigned_location(parent->spill_slot());
  ConvertAllUses(range);
}

intptr_t FlowGraphAllocator::FirstIntersectionWithAllocated(
    intptr_t reg,
    LiveRange* unallocated) {
  intptr_t intersection = kMaxPosition;
  for (intptr_t i = 0; i < registers_[reg]->length(); i++) {
    LiveRange* allocated = (*registers_[reg])[i];
    if (allocated == NULL) continue;

    UseInterval* allocated_head =
        allocated->finger()->first_pending_use_interval();
    if (allocated_head->start() >= intersection) continue;

    const intptr_t pos = FirstIntersection(
        unallocated->finger()->first_pending_use_interval(), allocated_head);
    if (pos < intersection) intersection = pos;
  }
  return intersection;
}

void ReachingDefs::AddPhi(PhiInstr* phi) {
  if (phi->reaching_defs() == NULL) {
    Zone* zone = flow_graph_.zone();
    phi->set_reaching_defs(
        new (zone) BitVector(zone, flow_graph_.max_virtual_register_number()));

    // Compute initial set reaching defs set.
    bool depends_on_phi = false;
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Definition* input = phi->InputAt(i)->definition();
      if (input->IsPhi()) {
        depends_on_phi = true;
      }
      phi->reaching_defs()->Add(input->ssa_temp_index());
      if (phi->HasPairRepresentation()) {
        phi->reaching_defs()->Add(ToSecondPairVreg(input->ssa_temp_index()));
      }
    }

    // If this phi depends on another phi then we need fix point iteration.
    if (depends_on_phi) phis_.Add(phi);
  }
}

void ReachingDefs::Compute() {
  // Transitively collect all phis that are used by the given phi.
  for (intptr_t i = 0; i < phis_.length(); i++) {
    PhiInstr* phi = phis_[i];

    // Add all phis that affect this phi to the list.
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      PhiInstr* input_phi = phi->InputAt(i)->definition()->AsPhi();
      if (input_phi != NULL) {
        AddPhi(input_phi);
      }
    }
  }

  // Propagate values until fix point is reached.
  bool changed;
  do {
    changed = false;
    for (intptr_t i = 0; i < phis_.length(); i++) {
      PhiInstr* phi = phis_[i];
      for (intptr_t i = 0; i < phi->InputCount(); i++) {
        PhiInstr* input_phi = phi->InputAt(i)->definition()->AsPhi();
        if (input_phi != NULL) {
          if (phi->reaching_defs()->AddAll(input_phi->reaching_defs())) {
            changed = true;
          }
        }
      }
    }
  } while (changed);

  phis_.Clear();
}

BitVector* ReachingDefs::Get(PhiInstr* phi) {
  if (phi->reaching_defs() == NULL) {
    ASSERT(phis_.is_empty());
    AddPhi(phi);
    Compute();
  }
  return phi->reaching_defs();
}

bool FlowGraphAllocator::AllocateFreeRegister(LiveRange* unallocated) {
  intptr_t candidate = kNoRegister;
  intptr_t free_until = 0;

  // If hint is available try hint first.
  // TODO(vegorov): ensure that phis are hinted on the back edge.
  Location hint = unallocated->finger()->FirstHint();
  if (hint.IsMachineRegister()) {
    if (!blocked_registers_[hint.register_code()]) {
      free_until =
          FirstIntersectionWithAllocated(hint.register_code(), unallocated);
      candidate = hint.register_code();
    }

    TRACE_ALLOC(THR_Print("found hint %s for v%" Pd ": free until %" Pd "\n",
                          hint.Name(), unallocated->vreg(), free_until));
  } else {
    for (intptr_t reg = 0; reg < NumberOfRegisters(); ++reg) {
      if (!blocked_registers_[reg] && (registers_[reg]->length() == 0)) {
        candidate = reg;
        free_until = kMaxPosition;
        break;
      }
    }
  }

  ASSERT(0 <= kMaxPosition);
  if (free_until != kMaxPosition) {
    for (intptr_t reg = 0; reg < NumberOfRegisters(); ++reg) {
      if (blocked_registers_[reg] || (reg == candidate)) continue;
      const intptr_t intersection =
          FirstIntersectionWithAllocated(reg, unallocated);
      if (intersection > free_until) {
        candidate = reg;
        free_until = intersection;
        if (free_until == kMaxPosition) break;
      }
    }
  }

  // All registers are blocked by active ranges.
  if (free_until <= unallocated->Start()) return false;

  // We have a very good candidate (either hinted to us or completely free).
  // If we are in a loop try to reduce number of moves on the back edge by
  // searching for a candidate that does not interfere with phis on the back
  // edge.
  LoopInfo* loop_info = BlockEntryAt(unallocated->Start())->loop_info();
  if ((unallocated->vreg() >= 0) && (loop_info != nullptr) &&
      (free_until >= extra_loop_info_[loop_info->id()]->end) &&
      extra_loop_info_[loop_info->id()]->backedge_interference->Contains(
          unallocated->vreg())) {
    GrowableArray<bool> used_on_backedge(number_of_registers_);
    for (intptr_t i = 0; i < number_of_registers_; i++) {
      used_on_backedge.Add(false);
    }

    for (PhiIterator it(loop_info->header()->AsJoinEntry()); !it.Done();
         it.Advance()) {
      PhiInstr* phi = it.Current();
      ASSERT(phi->is_alive());
      const intptr_t phi_vreg = phi->ssa_temp_index();
      LiveRange* range = GetLiveRange(phi_vreg);
      if (range->assigned_location().kind() == register_kind_) {
        const intptr_t reg = range->assigned_location().register_code();
        if (!reaching_defs_.Get(phi)->Contains(unallocated->vreg())) {
          used_on_backedge[reg] = true;
        }
      }
      if (phi->HasPairRepresentation()) {
        const intptr_t second_phi_vreg = ToSecondPairVreg(phi_vreg);
        LiveRange* second_range = GetLiveRange(second_phi_vreg);
        if (second_range->assigned_location().kind() == register_kind_) {
          const intptr_t reg =
              second_range->assigned_location().register_code();
          if (!reaching_defs_.Get(phi)->Contains(unallocated->vreg())) {
            used_on_backedge[reg] = true;
          }
        }
      }
    }

    if (used_on_backedge[candidate]) {
      TRACE_ALLOC(THR_Print("considering %s for v%" Pd
                            ": has interference on the back edge"
                            " {loop [%" Pd ", %" Pd ")}\n",
                            MakeRegisterLocation(candidate).Name(),
                            unallocated->vreg(),
                            extra_loop_info_[loop_info->id()]->start,
                            extra_loop_info_[loop_info->id()]->end));
      for (intptr_t reg = 0; reg < NumberOfRegisters(); ++reg) {
        if (blocked_registers_[reg] || (reg == candidate) ||
            used_on_backedge[reg]) {
          continue;
        }

        const intptr_t intersection =
            FirstIntersectionWithAllocated(reg, unallocated);
        if (intersection >= free_until) {
          candidate = reg;
          free_until = intersection;
          TRACE_ALLOC(THR_Print(
              "found %s for v%" Pd " with no interference on the back edge\n",
              MakeRegisterLocation(candidate).Name(), candidate));
          break;
        }
      }
    }
  }

  TRACE_ALLOC(THR_Print("assigning free register "));
  TRACE_ALLOC(MakeRegisterLocation(candidate).Print());
  TRACE_ALLOC(THR_Print(" to v%" Pd "\n", unallocated->vreg()));

  if (free_until != kMaxPosition) {
    // There was an intersection. Split unallocated.
    TRACE_ALLOC(THR_Print("  splitting at %" Pd "\n", free_until));
    LiveRange* tail = unallocated->SplitAt(free_until);
    AddToUnallocated(tail);
  }

  registers_[candidate]->Add(unallocated);
  unallocated->set_assigned_location(MakeRegisterLocation(candidate));
  return true;
}

bool FlowGraphAllocator::RangeHasOnlyUnconstrainedUsesInLoop(LiveRange* range,
                                                             intptr_t loop_id) {
  if (range->vreg() >= 0) {
    LiveRange* parent = GetLiveRange(range->vreg());
    return parent->HasOnlyUnconstrainedUsesInLoop(loop_id);
  }
  return false;
}

bool FlowGraphAllocator::IsCheapToEvictRegisterInLoop(LoopInfo* loop_info,
                                                      intptr_t reg) {
  const intptr_t loop_start = extra_loop_info_[loop_info->id()]->start;
  const intptr_t loop_end = extra_loop_info_[loop_info->id()]->end;

  for (intptr_t i = 0; i < registers_[reg]->length(); i++) {
    LiveRange* allocated = (*registers_[reg])[i];
    UseInterval* interval = allocated->finger()->first_pending_use_interval();
    if (interval->Contains(loop_start)) {
      if (!RangeHasOnlyUnconstrainedUsesInLoop(allocated, loop_info->id())) {
        return false;
      }
    } else if (interval->start() < loop_end) {
      return false;
    }
  }

  return true;
}

bool FlowGraphAllocator::HasCheapEvictionCandidate(LiveRange* phi_range) {
  ASSERT(phi_range->is_loop_phi());

  BlockEntryInstr* header = BlockEntryAt(phi_range->Start());

  ASSERT(header->IsLoopHeader());
  ASSERT(phi_range->Start() == header->start_pos());

  for (intptr_t reg = 0; reg < NumberOfRegisters(); ++reg) {
    if (blocked_registers_[reg]) continue;
    if (IsCheapToEvictRegisterInLoop(header->loop_info(), reg)) {
      return true;
    }
  }

  return false;
}

void FlowGraphAllocator::AllocateAnyRegister(LiveRange* unallocated) {
  // If a loop phi has no register uses we might still want to allocate it
  // to the register to reduce amount of memory moves on the back edge.
  // This is possible if there is a register blocked by a range that can be
  // cheaply evicted i.e. it has no register beneficial uses inside the
  // loop.
  UsePosition* register_use =
      unallocated->finger()->FirstRegisterUse(unallocated->Start());
  if ((register_use == NULL) &&
      !(unallocated->is_loop_phi() && HasCheapEvictionCandidate(unallocated))) {
    Spill(unallocated);
    return;
  }

  intptr_t candidate = kNoRegister;
  intptr_t free_until = 0;
  intptr_t blocked_at = kMaxPosition;

  for (int reg = 0; reg < NumberOfRegisters(); ++reg) {
    if (blocked_registers_[reg]) continue;
    if (UpdateFreeUntil(reg, unallocated, &free_until, &blocked_at)) {
      candidate = reg;
    }
  }

  const intptr_t register_use_pos =
      (register_use != NULL) ? register_use->pos() : unallocated->Start();
  if (free_until < register_use_pos) {
    // Can't acquire free register. Spill until we really need one.
    ASSERT(unallocated->Start() < ToInstructionStart(register_use_pos));
    SpillBetween(unallocated, unallocated->Start(), register_use->pos());
    return;
  }

  ASSERT(candidate != kNoRegister);

  TRACE_ALLOC(THR_Print("assigning blocked register "));
  TRACE_ALLOC(MakeRegisterLocation(candidate).Print());
  TRACE_ALLOC(THR_Print(" to live range v%" Pd " until %" Pd "\n",
                        unallocated->vreg(), blocked_at));

  if (blocked_at < unallocated->End()) {
    // Register is blocked before the end of the live range.  Split the range
    // at latest at blocked_at position.
    LiveRange* tail =
        SplitBetween(unallocated, unallocated->Start(), blocked_at + 1);
    AddToUnallocated(tail);
  }

  AssignNonFreeRegister(unallocated, candidate);
}

bool FlowGraphAllocator::UpdateFreeUntil(intptr_t reg,
                                         LiveRange* unallocated,
                                         intptr_t* cur_free_until,
                                         intptr_t* cur_blocked_at) {
  intptr_t free_until = kMaxPosition;
  intptr_t blocked_at = kMaxPosition;
  const intptr_t start = unallocated->Start();

  for (intptr_t i = 0; i < registers_[reg]->length(); i++) {
    LiveRange* allocated = (*registers_[reg])[i];

    UseInterval* first_pending_use_interval =
        allocated->finger()->first_pending_use_interval();
    if (first_pending_use_interval->Contains(start)) {
      // This is an active interval.
      if (allocated->vreg() < 0) {
        // This register blocked by an interval that
        // can't be spilled.
        return false;
      }

      UsePosition* use = allocated->finger()->FirstInterferingUse(start);
      if ((use != NULL) && ((ToInstructionStart(use->pos()) - start) <= 1)) {
        // This register is blocked by interval that is used
        // as register in the current instruction and can't
        // be spilled.
        return false;
      }

      const intptr_t use_pos = (use != NULL) ? use->pos() : allocated->End();

      if (use_pos < free_until) free_until = use_pos;
    } else {
      // This is inactive interval.
      const intptr_t intersection = FirstIntersection(
          first_pending_use_interval, unallocated->first_use_interval());
      if (intersection != kMaxPosition) {
        if (intersection < free_until) free_until = intersection;
        if (allocated->vreg() == kNoVirtualRegister) blocked_at = intersection;
      }
    }

    if (free_until <= *cur_free_until) {
      return false;
    }
  }

  ASSERT(free_until > *cur_free_until);
  *cur_free_until = free_until;
  *cur_blocked_at = blocked_at;
  return true;
}

void FlowGraphAllocator::RemoveEvicted(intptr_t reg, intptr_t first_evicted) {
  intptr_t to = first_evicted;
  intptr_t from = first_evicted + 1;
  while (from < registers_[reg]->length()) {
    LiveRange* allocated = (*registers_[reg])[from++];
    if (allocated != NULL) (*registers_[reg])[to++] = allocated;
  }
  registers_[reg]->TruncateTo(to);
}

void FlowGraphAllocator::AssignNonFreeRegister(LiveRange* unallocated,
                                               intptr_t reg) {
  intptr_t first_evicted = -1;
  for (intptr_t i = registers_[reg]->length() - 1; i >= 0; i--) {
    LiveRange* allocated = (*registers_[reg])[i];
    if (allocated->vreg() < 0) continue;  // Can't be evicted.
    if (EvictIntersection(allocated, unallocated)) {
      // If allocated was not spilled convert all pending uses.
      if (allocated->assigned_location().IsMachineRegister()) {
        ASSERT(allocated->End() <= unallocated->Start());
        ConvertAllUses(allocated);
      }
      (*registers_[reg])[i] = NULL;
      first_evicted = i;
    }
  }

  // Remove evicted ranges from the array.
  if (first_evicted != -1) RemoveEvicted(reg, first_evicted);

  registers_[reg]->Add(unallocated);
  unallocated->set_assigned_location(MakeRegisterLocation(reg));
}

bool FlowGraphAllocator::EvictIntersection(LiveRange* allocated,
                                           LiveRange* unallocated) {
  UseInterval* first_unallocated =
      unallocated->finger()->first_pending_use_interval();
  const intptr_t intersection = FirstIntersection(
      allocated->finger()->first_pending_use_interval(), first_unallocated);
  if (intersection == kMaxPosition) return false;

  const intptr_t spill_position = first_unallocated->start();
  UsePosition* use = allocated->finger()->FirstInterferingUse(spill_position);
  if (use == NULL) {
    // No register uses after this point.
    SpillAfter(allocated, spill_position);
  } else {
    const intptr_t restore_position =
        (spill_position < intersection) ? MinPosition(intersection, use->pos())
                                        : use->pos();

    SpillBetween(allocated, spill_position, restore_position);
  }

  return true;
}

MoveOperands* FlowGraphAllocator::AddMoveAt(intptr_t pos,
                                            Location to,
                                            Location from) {
  ASSERT(!IsBlockEntry(pos));

  // Now that the GraphEntry (B0) does no longer have any parameter instructions
  // in it so we should not attempt to add parallel moves to it.
  ASSERT(pos >= kNormalEntryPos);

  ParallelMoveInstr* parallel_move = NULL;
  Instruction* instr = InstructionAt(pos);
  if (auto entry = instr->AsFunctionEntry()) {
    // Parallel moves added to the FunctionEntry will be added after the block
    // entry.
    parallel_move = CreateParallelMoveAfter(entry, pos);
  } else if (IsInstructionStartPosition(pos)) {
    parallel_move = CreateParallelMoveBefore(instr, pos);
  } else {
    parallel_move = CreateParallelMoveAfter(instr, pos);
  }

  return parallel_move->AddMove(to, from);
}

void FlowGraphAllocator::ConvertUseTo(UsePosition* use, Location loc) {
  ASSERT(!loc.IsPairLocation());
  ASSERT(use->location_slot() != NULL);
  Location* slot = use->location_slot();
  ASSERT(slot->IsUnallocated());
  TRACE_ALLOC(THR_Print("  use at %" Pd " converted to ", use->pos()));
  TRACE_ALLOC(loc.Print());
  TRACE_ALLOC(THR_Print("\n"));
  *slot = loc;
}

void FlowGraphAllocator::ConvertAllUses(LiveRange* range) {
  if (range->vreg() == kNoVirtualRegister) return;

  const Location loc = range->assigned_location();
  ASSERT(!loc.IsInvalid());

  TRACE_ALLOC(THR_Print("range [%" Pd ", %" Pd ") "
                        "for v%" Pd " has been allocated to ",
                        range->Start(), range->End(), range->vreg()));
  TRACE_ALLOC(loc.Print());
  TRACE_ALLOC(THR_Print(":\n"));

  for (UsePosition* use = range->first_use(); use != NULL; use = use->next()) {
    ConvertUseTo(use, loc);
  }

  // Add live registers at all safepoints for instructions with slow-path
  // code.
  if (loc.IsMachineRegister()) {
    for (SafepointPosition* safepoint = range->first_safepoint();
         safepoint != NULL; safepoint = safepoint->next()) {
      if (!safepoint->locs()->always_calls()) {
        ASSERT(safepoint->locs()->can_call());
        safepoint->locs()->live_registers()->Add(loc, range->representation());
      }
    }
  }
}

void FlowGraphAllocator::AdvanceActiveIntervals(const intptr_t start) {
  for (intptr_t reg = 0; reg < NumberOfRegisters(); reg++) {
    if (registers_[reg]->is_empty()) continue;

    intptr_t first_evicted = -1;
    for (intptr_t i = registers_[reg]->length() - 1; i >= 0; i--) {
      LiveRange* range = (*registers_[reg])[i];
      if (range->finger()->Advance(start)) {
        ConvertAllUses(range);
        (*registers_[reg])[i] = NULL;
        first_evicted = i;
      }
    }

    if (first_evicted != -1) RemoveEvicted(reg, first_evicted);
  }
}

bool LiveRange::Contains(intptr_t pos) const {
  if (!CanCover(pos)) return false;

  for (UseInterval* interval = first_use_interval_; interval != NULL;
       interval = interval->next()) {
    if (interval->Contains(pos)) {
      return true;
    }
  }

  return false;
}

void FlowGraphAllocator::AssignSafepoints(Definition* defn, LiveRange* range) {
  for (intptr_t i = safepoints_.length() - 1; i >= 0; i--) {
    Instruction* safepoint_instr = safepoints_[i];
    if (safepoint_instr == defn) {
      // The value is not live until after the definition is fully executed,
      // don't assign the safepoint inside the definition itself to
      // definition's liverange.
      continue;
    }

    const intptr_t pos = GetLifetimePosition(safepoint_instr);
    if (range->End() <= pos) break;

    if (range->Contains(pos)) {
      range->AddSafepoint(pos, safepoint_instr->locs());
    }
  }
}

static inline bool ShouldBeAllocatedBefore(LiveRange* a, LiveRange* b) {
  // TODO(vegorov): consider first hint position when ordering live ranges.
  return a->Start() <= b->Start();
}

static void AddToSortedListOfRanges(GrowableArray<LiveRange*>* list,
                                    LiveRange* range) {
  range->finger()->Initialize(range);

  if (list->is_empty()) {
    list->Add(range);
    return;
  }

  for (intptr_t i = list->length() - 1; i >= 0; i--) {
    if (ShouldBeAllocatedBefore(range, (*list)[i])) {
      list->InsertAt(i + 1, range);
      return;
    }
  }
  list->InsertAt(0, range);
}

void FlowGraphAllocator::AddToUnallocated(LiveRange* range) {
  AddToSortedListOfRanges(&unallocated_, range);
}

void FlowGraphAllocator::CompleteRange(LiveRange* range, Location::Kind kind) {
  switch (kind) {
    case Location::kRegister:
      AddToSortedListOfRanges(&unallocated_cpu_, range);
      break;

    case Location::kFpuRegister:
      AddToSortedListOfRanges(&unallocated_xmm_, range);
      break;

    default:
      UNREACHABLE();
  }
}

#if defined(DEBUG)
bool FlowGraphAllocator::UnallocatedIsSorted() {
  for (intptr_t i = unallocated_.length() - 1; i >= 1; i--) {
    LiveRange* a = unallocated_[i];
    LiveRange* b = unallocated_[i - 1];
    if (!ShouldBeAllocatedBefore(a, b)) {
      UNREACHABLE();
      return false;
    }
  }
  return true;
}
#endif

void FlowGraphAllocator::PrepareForAllocation(
    Location::Kind register_kind,
    intptr_t number_of_registers,
    const GrowableArray<LiveRange*>& unallocated,
    LiveRange** blocking_ranges,
    bool* blocked_registers) {
  register_kind_ = register_kind;
  number_of_registers_ = number_of_registers;

  blocked_registers_.Clear();
  registers_.Clear();
  for (intptr_t i = 0; i < number_of_registers_; i++) {
    blocked_registers_.Add(false);
    registers_.Add(new ZoneGrowableArray<LiveRange*>);
  }
  ASSERT(unallocated_.is_empty());
  unallocated_.AddArray(unallocated);

  for (intptr_t reg = 0; reg < number_of_registers; reg++) {
    blocked_registers_[reg] = blocked_registers[reg];
    ASSERT(registers_[reg]->is_empty());

    LiveRange* range = blocking_ranges[reg];
    if (range != NULL) {
      range->finger()->Initialize(range);
      registers_[reg]->Add(range);
    }
  }
}

void FlowGraphAllocator::AllocateUnallocatedRanges() {
#if defined(DEBUG)
  ASSERT(UnallocatedIsSorted());
#endif

  while (!unallocated_.is_empty()) {
    LiveRange* range = unallocated_.RemoveLast();
    const intptr_t start = range->Start();
    TRACE_ALLOC(THR_Print("Processing live range for v%" Pd " "
                          "starting at %" Pd "\n",
                          range->vreg(), start));

    // TODO(vegorov): eagerly spill liveranges without register uses.
    AdvanceActiveIntervals(start);

    if (!AllocateFreeRegister(range)) {
      if (intrinsic_mode_) {
        // No spilling when compiling intrinsics.
        // TODO(fschneider): Handle spilling in intrinsics. For now, the
        // IR has to be built so that there are enough free registers.
        UNREACHABLE();
      }
      AllocateAnyRegister(range);
    }
  }

  // All allocation decisions were done.
  ASSERT(unallocated_.is_empty());

  // Finish allocation.
  AdvanceActiveIntervals(kMaxPosition);
  TRACE_ALLOC(THR_Print("Allocation completed\n"));
}

bool FlowGraphAllocator::TargetLocationIsSpillSlot(LiveRange* range,
                                                   Location target) {
  return GetLiveRange(range->vreg())->spill_slot().Equals(target);
}

static LiveRange* FindCover(LiveRange* parent, intptr_t pos) {
  for (LiveRange* range = parent; range != nullptr;
       range = range->next_sibling()) {
    if (range->CanCover(pos)) {
      return range;
    }
  }
  UNREACHABLE();
  return nullptr;
}

static bool AreLocationsAllTheSame(const GrowableArray<Location>& locs) {
  for (intptr_t j = 1; j < locs.length(); j++) {
    if (!locs[j].Equals(locs[0])) {
      return false;
    }
  }
  return true;
}

// Emit move on the edge from |pred| to |succ|.
static void EmitMoveOnEdge(BlockEntryInstr* succ,
                           BlockEntryInstr* pred,
                           MoveOperands move) {
  Instruction* last = pred->last_instruction();
  if ((last->SuccessorCount() == 1) && !pred->IsGraphEntry()) {
    ASSERT(last->IsGoto());
    last->AsGoto()->GetParallelMove()->AddMove(move.dest(), move.src());
  } else {
    succ->GetParallelMove()->AddMove(move.dest(), move.src());
  }
}

void FlowGraphAllocator::ResolveControlFlow() {
  // Resolve linear control flow between touching split siblings
  // inside basic blocks.
  for (intptr_t vreg = 0; vreg < live_ranges_.length(); vreg++) {
    LiveRange* range = live_ranges_[vreg];
    if (range == NULL) continue;

    while (range->next_sibling() != nullptr) {
      LiveRange* sibling = range->next_sibling();
      TRACE_ALLOC(THR_Print("connecting [%" Pd ", %" Pd ") [", range->Start(),
                            range->End()));
      TRACE_ALLOC(range->assigned_location().Print());
      TRACE_ALLOC(THR_Print("] to [%" Pd ", %" Pd ") [", sibling->Start(),
                            sibling->End()));
      TRACE_ALLOC(sibling->assigned_location().Print());
      TRACE_ALLOC(THR_Print("]\n"));
      if ((range->End() == sibling->Start()) &&
          !TargetLocationIsSpillSlot(range, sibling->assigned_location()) &&
          !range->assigned_location().Equals(sibling->assigned_location()) &&
          !IsBlockEntry(range->End())) {
        AddMoveAt(sibling->Start(), sibling->assigned_location(),
                  range->assigned_location());
      }
      range = sibling;
    }
  }

  // Resolve non-linear control flow across branches.
  // At joins we attempt to sink duplicated moves from predecessors into join
  // itself as long as their source is not blocked by other moves.
  // Moves which are candidates to sinking are collected in the |pending|
  // array and we later compute which one of them we can emit (|can_emit|)
  // at the join itself.
  GrowableArray<Location> src_locs(2);
  GrowableArray<MoveOperands> pending(10);
  BitVector* can_emit = new BitVector(flow_graph_.zone(), 10);
  for (intptr_t i = 1; i < block_order_.length(); i++) {
    BlockEntryInstr* block = block_order_[i];
    BitVector* live = liveness_.GetLiveInSet(block);
    for (BitVector::Iterator it(live); !it.Done(); it.Advance()) {
      LiveRange* range = GetLiveRange(it.Current());
      if (range->next_sibling() == nullptr) {
        // Nothing to connect. The whole range was allocated to the same
        // location.
        TRACE_ALLOC(
            THR_Print("range v%" Pd " has no siblings\n", range->vreg()));
        continue;
      }

      LiveRange* dst_cover = FindCover(range, block->start_pos());
      Location dst = dst_cover->assigned_location();

      TRACE_ALLOC(THR_Print("range v%" Pd
                            " is allocated to %s on entry to B%" Pd
                            " covered by [%" Pd ", %" Pd ")\n",
                            range->vreg(), dst.ToCString(), block->block_id(),
                            dst_cover->Start(), dst_cover->End()));

      if (TargetLocationIsSpillSlot(range, dst)) {
        // Values are eagerly spilled. Spill slot already contains appropriate
        // value.
        TRACE_ALLOC(
            THR_Print("  [no resolution necessary - range is spilled]\n"));
        continue;
      }

      src_locs.Clear();
      for (intptr_t j = 0; j < block->PredecessorCount(); j++) {
        BlockEntryInstr* pred = block->PredecessorAt(j);
        LiveRange* src_cover = FindCover(range, pred->end_pos() - 1);
        Location src = src_cover->assigned_location();
        src_locs.Add(src);

        TRACE_ALLOC(THR_Print("| incoming value in %s on exit from B%" Pd
                              " covered by [%" Pd ", %" Pd ")\n",
                              src.ToCString(), pred->block_id(),
                              src_cover->Start(), src_cover->End()));
      }

      // Check if all source locations are the same for the range. Then
      // we can try to emit a single move at the destination if we can
      // guarantee that source location is available on all incoming edges.
      // (i.e. it is not destroyed by some other move).
      if ((src_locs.length() > 1) && AreLocationsAllTheSame(src_locs)) {
        if (!dst.Equals(src_locs[0])) {
          // We have a non-redundant move which potentially can be performed
          // at the start of block, however we will only be able to check
          // whether or not source location is alive on all incoming edges
          // only when we finish processing all live-in values.
          pending.Add(MoveOperands(dst, src_locs[0]));
        }

        // Next incoming value.
        continue;
      }

      for (intptr_t j = 0; j < block->PredecessorCount(); j++) {
        if (dst.Equals(src_locs[j])) {
          // Redundant move.
          continue;
        }

        EmitMoveOnEdge(block, block->PredecessorAt(j), {dst, src_locs[j]});
      }
    }

    // For each pending move we need to check if it can be emitted into the
    // destination block (prerequisite for that is that predecessors should
    // not destroy the value in the Goto move).
    if (pending.length() > 0) {
      if (can_emit->length() < pending.length()) {
        can_emit = new BitVector(flow_graph_.zone(), pending.length());
      }
      can_emit->SetAll();

      // Set to |true| when we discover more blocked pending moves and
      // need to run another run through pending moves to propagate that.
      bool changed = false;

      // Process all pending moves and check if any move in the predecessor
      // blocks then by overwriting their source.
      for (intptr_t j = 0; j < pending.length(); j++) {
        Location src = pending[j].src();
        for (intptr_t p = 0; p < block->PredecessorCount(); p++) {
          BlockEntryInstr* pred = block->PredecessorAt(p);
          for (auto move :
               pred->last_instruction()->AsGoto()->GetParallelMove()->moves()) {
            if (!move->IsRedundant() && move->dest().Equals(src)) {
              can_emit->Remove(j);
              changed = true;
              break;
            }
          }
        }
      }

      // Check if newly discovered blocked moves block any other pending moves.
      while (changed) {
        changed = false;
        for (intptr_t j = 0; j < pending.length(); j++) {
          if (can_emit->Contains(j)) {
            for (intptr_t k = 0; k < pending.length(); k++) {
              if (!can_emit->Contains(k) &&
                  pending[k].dest().Equals(pending[j].src())) {
                can_emit->Remove(j);
                changed = true;
                break;
              }
            }
          }
        }
      }

      // Emit pending moves either in the successor block or in predecessors
      // (if they are blocked).
      for (intptr_t j = 0; j < pending.length(); j++) {
        const auto& move = pending[j];
        if (can_emit->Contains(j)) {
          block->GetParallelMove()->AddMove(move.dest(), move.src());
        } else {
          for (intptr_t p = 0; p < block->PredecessorCount(); p++) {
            EmitMoveOnEdge(block, block->PredecessorAt(p), move);
          }
        }
      }

      pending.Clear();
    }
  }

  // Eagerly spill values.
  // TODO(vegorov): if value is spilled on the cold path (e.g. by the call)
  // this will cause spilling to occur on the fast path (at the definition).
  for (intptr_t i = 0; i < spilled_.length(); i++) {
    LiveRange* range = spilled_[i];
    if (!range->assigned_location().Equals(range->spill_slot())) {
      AddMoveAt(range->Start() + 1, range->spill_slot(),
                range->assigned_location());
    }
  }
}

static Representation RepresentationForRange(Representation definition_rep) {
  if (definition_rep == kUnboxedInt64) {
    // kUnboxedInt64 is split into two ranges, each of which are kUntagged.
    return kUntagged;
  } else if (definition_rep == kUnboxedUint32) {
    // kUnboxedUint32 is untagged.
    return kUntagged;
  }
  return definition_rep;
}

void FlowGraphAllocator::CollectRepresentations() {
  // Constants.
  GraphEntryInstr* graph_entry = flow_graph_.graph_entry();
  auto initial_definitions = graph_entry->initial_definitions();
  for (intptr_t i = 0; i < initial_definitions->length(); ++i) {
    Definition* def = (*initial_definitions)[i];
    value_representations_[def->ssa_temp_index()] =
        RepresentationForRange(def->representation());
    ASSERT(!def->HasPairRepresentation());
  }

  for (BlockIterator it = flow_graph_.reverse_postorder_iterator(); !it.Done();
       it.Advance()) {
    BlockEntryInstr* block = it.Current();

    if (auto entry = block->AsBlockEntryWithInitialDefs()) {
      initial_definitions = entry->initial_definitions();
      for (intptr_t i = 0; i < initial_definitions->length(); ++i) {
        Definition* def = (*initial_definitions)[i];
        value_representations_[def->ssa_temp_index()] =
            RepresentationForRange(def->representation());
        if (def->HasPairRepresentation()) {
          value_representations_[ToSecondPairVreg(def->ssa_temp_index())] =
              RepresentationForRange(def->representation());
        }
      }
    } else if (auto join = block->AsJoinEntry()) {
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        ASSERT(phi != NULL && phi->ssa_temp_index() >= 0);
        value_representations_[phi->ssa_temp_index()] =
            RepresentationForRange(phi->representation());
        if (phi->HasPairRepresentation()) {
          value_representations_[ToSecondPairVreg(phi->ssa_temp_index())] =
              RepresentationForRange(phi->representation());
        }
      }
    }

    // Normal instructions.
    for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
         instr_it.Advance()) {
      Definition* def = instr_it.Current()->AsDefinition();
      if ((def != NULL) && (def->ssa_temp_index() >= 0)) {
        const intptr_t vreg = def->ssa_temp_index();
        value_representations_[vreg] =
            RepresentationForRange(def->representation());
        if (def->HasPairRepresentation()) {
          value_representations_[ToSecondPairVreg(vreg)] =
              RepresentationForRange(def->representation());
        }
      }
    }
  }
}

void FlowGraphAllocator::AllocateRegisters() {
  CollectRepresentations();

  liveness_.Analyze();

  NumberInstructions();

  BuildLiveRanges();

  if (FLAG_print_ssa_liveranges && CompilerState::ShouldTrace()) {
    const Function& function = flow_graph_.function();
    THR_Print("-- [before ssa allocator] ranges [%s] ---------\n",
              function.ToFullyQualifiedCString());
    PrintLiveRanges();
    THR_Print("----------------------------------------------\n");

    THR_Print("-- [before ssa allocator] ir [%s] -------------\n",
              function.ToFullyQualifiedCString());
    if (FLAG_support_il_printer) {
#ifndef PRODUCT
      FlowGraphPrinter printer(flow_graph_, true);
      printer.PrintBlocks();
#endif
    }
    THR_Print("----------------------------------------------\n");
  }

  PrepareForAllocation(Location::kRegister, kNumberOfCpuRegisters,
                       unallocated_cpu_, cpu_regs_, blocked_cpu_registers_);
  AllocateUnallocatedRanges();
  // GraphEntryInstr::fixed_slot_count() stack slots are reserved for catch
  // entries. When allocating a spill slot, AllocateSpillSlotFor() accounts for
  // these reserved slots and allocates spill slots on top of them.
  // However, if there are no spill slots allocated, we still need to reserve
  // slots for catch entries in the spill area.
  cpu_spill_slot_count_ = Utils::Maximum(
      spill_slots_.length(), flow_graph_.graph_entry()->fixed_slot_count());
  spill_slots_.Clear();
  quad_spill_slots_.Clear();
  untagged_spill_slots_.Clear();

  PrepareForAllocation(Location::kFpuRegister, kNumberOfFpuRegisters,
                       unallocated_xmm_, fpu_regs_, blocked_fpu_registers_);
  AllocateUnallocatedRanges();
  ResolveControlFlow();

  GraphEntryInstr* entry = block_order_[0]->AsGraphEntry();
  ASSERT(entry != NULL);
  intptr_t double_spill_slot_count = spill_slots_.length() * kDoubleSpillFactor;
  entry->set_spill_slot_count(cpu_spill_slot_count_ + double_spill_slot_count);

  if (FLAG_print_ssa_liveranges && CompilerState::ShouldTrace()) {
    const Function& function = flow_graph_.function();

    THR_Print("-- [after ssa allocator] ranges [%s] ---------\n",
              function.ToFullyQualifiedCString());
    PrintLiveRanges();
    THR_Print("----------------------------------------------\n");

    THR_Print("-- [after ssa allocator] ir [%s] -------------\n",
              function.ToFullyQualifiedCString());
    if (FLAG_support_il_printer) {
#ifndef PRODUCT
      FlowGraphPrinter printer(flow_graph_, true);
      printer.PrintBlocks();
#endif
    }
    THR_Print("----------------------------------------------\n");
  }
}

}  // namespace dart
