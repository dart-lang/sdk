// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_allocator.h"

#include "vm/bit_vector.h"
#include "vm/intermediate_language.h"
#include "vm/il_printer.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_compiler.h"
#include "vm/parser.h"

namespace dart {

DEFINE_FLAG(bool, print_ssa_liveness, false,
            "Print liveness for ssa variables.");
DEFINE_FLAG(bool, trace_ssa_allocator, false,
            "Trace register allocation over SSA.");
DEFINE_FLAG(bool, print_ssa_liveranges, false,
            "Print live ranges after allocation.");

#if defined(DEBUG)
#define TRACE_ALLOC(statement)                                                 \
  do {                                                                         \
    if (FLAG_trace_ssa_allocator) statement;                                   \
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
// (kPairOfTagged or kPairOfUnboxedDouble) use two virtual register names.
// At SSA index allocation time each definition reserves two SSA indexes,
// the second index is only used for pairs. This function maps from the first
// SSA index to the second.
static intptr_t ToSecondPairVreg(intptr_t vreg) {
  // Map vreg to its pair vreg.
  return vreg + kPairVirtualRegisterOffset;
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


FlowGraphAllocator::FlowGraphAllocator(const FlowGraph& flow_graph)
  : flow_graph_(flow_graph),
    reaching_defs_(flow_graph),
    value_representations_(flow_graph.max_virtual_register_number()),
    block_order_(flow_graph.reverse_postorder()),
    postorder_(flow_graph.postorder()),
    liveness_(flow_graph),
    vreg_count_(flow_graph.max_virtual_register_number()),
    live_ranges_(flow_graph.max_virtual_register_number()),
    cpu_regs_(),
    fpu_regs_(),
    blocked_cpu_registers_(),
    blocked_fpu_registers_(),
    number_of_registers_(0),
    registers_(),
    blocked_registers_(),
    cpu_spill_slot_count_(0) {
  for (intptr_t i = 0; i < vreg_count_; i++) {
    live_ranges_.Add(NULL);
  }
  for (intptr_t i = 0; i < vreg_count_; i++) {
    value_representations_.Add(kNoRepresentation);
  }

  // All registers are marked as "not blocked" (array initialized to false).
  // Mark the unavailable ones as "blocked" (true).
  for (intptr_t i = 0; i < kFirstFreeCpuRegister; i++) {
    blocked_cpu_registers_[i] = true;
  }
  for (intptr_t i = kLastFreeCpuRegister + 1; i < kNumberOfCpuRegisters; i++) {
    blocked_cpu_registers_[i] = true;
  }
  blocked_cpu_registers_[CTX] = true;
  if (TMP != kNoRegister) {
    blocked_cpu_registers_[TMP] = true;
  }
  if (TMP2 != kNoRegister) {
    blocked_cpu_registers_[TMP2] = true;
  }
  if (PP != kNoRegister) {
    blocked_cpu_registers_[PP] = true;
  }
  blocked_cpu_registers_[SPREG] = true;
  blocked_cpu_registers_[FPREG] = true;

  // FpuTMP is used as scratch by optimized code and parallel move resolver.
  blocked_fpu_registers_[FpuTMP] = true;
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
      current->InitializeLocationSummary(Isolate::Current(), true);  // opt
      LocationSummary* locs = current->locs();

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
        for (Environment::DeepIterator env_it(current->env());
             !env_it.Done();
             env_it.Advance()) {
          Definition* defn = env_it.CurrentValue()->definition();
          if (defn->IsMaterializeObject()) {
            // MaterializeObject instruction is not in the graph.
            // Treat its inputs as part of the environment.
            for (intptr_t i = 0; i < defn->InputCount(); i++) {
              if (!defn->InputAt(i)->BindsToConstant()) {
                intptr_t idx = defn->InputAt(i)->definition()->ssa_temp_index();
                live_in->Add(idx);
              }
            }
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
        // TODO(johnmccutchan): Fix handling of PhiInstr with PairLocation.
        PhiInstr* phi = it.Current();
        ASSERT(phi != NULL);
        kill->Add(phi->ssa_temp_index());
        live_in->Remove(phi->ssa_temp_index());

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
        }
      }
    } else if (block->IsCatchBlockEntry()) {
      // Process initial definitions.
      CatchBlockEntryInstr* catch_entry = block->AsCatchBlockEntry();
      for (intptr_t i = 0;
           i < catch_entry->initial_definitions()->length();
           i++) {
        Definition* def = (*catch_entry->initial_definitions())[i];
        const intptr_t vreg = def->ssa_temp_index();
        kill_[catch_entry->postorder_number()]->Add(vreg);
        live_in_[catch_entry->postorder_number()]->Remove(vreg);
      }
    }
  }

  // Process initial definitions, ie, constants and incoming parameters.
  for (intptr_t i = 0; i < graph_entry_->initial_definitions()->length(); i++) {
    Definition* def = (*graph_entry_->initial_definitions())[i];
    const intptr_t vreg = def->ssa_temp_index();
    kill_[graph_entry_->postorder_number()]->Add(vreg);
    live_in_[graph_entry_->postorder_number()]->Remove(vreg);
  }
}


void LiveRange::AddUse(intptr_t pos, Location* location_slot) {
  ASSERT(location_slot != NULL);
  ASSERT((first_use_interval_->start_ <= pos) &&
         (pos <= first_use_interval_->end_));
  if ((uses_ != NULL) &&
      (uses_->pos() == pos) &&
      (uses_->location_slot() == location_slot)) {
    return;
  }
  uses_ = new UsePosition(pos, uses_, location_slot);
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
  AddUse(pos, location_slot);
  uses_->set_hint(hint);
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
    // cover the the block from the start to the last use in the block.
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

  OS::Print("  live range v%" Pd " [%" Pd ", %" Pd ") in ", vreg(),
                                                            Start(),
                                                            End());
  assigned_location().Print();
  if (spill_slot_.HasStackIndex()) {
    intptr_t stack_slot = spill_slot_.stack_index();
    OS::Print(" allocated spill slot: %" Pd "", stack_slot);
  }
  OS::Print("\n");

  SafepointPosition* safepoint = first_safepoint();
  while (safepoint != NULL) {
    OS::Print("    Safepoint [%" Pd "]: ", safepoint->pos());
    safepoint->locs()->stack_bitmap()->Print();
    OS::Print("\n");
    safepoint = safepoint->next();
  }

  UsePosition* use_pos = uses_;
  for (UseInterval* interval = first_use_interval_;
       interval != NULL;
       interval = interval->next()) {
    OS::Print("    use interval [%" Pd ", %" Pd ")\n",
              interval->start(),
              interval->end());
    while ((use_pos != NULL) && (use_pos->pos() <= interval->end())) {
      OS::Print("      use at %" Pd "", use_pos->pos());
      if (use_pos->location_slot() != NULL) {
        OS::Print(" as ");
        use_pos->location_slot()->Print();
      }
      OS::Print("\n");
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


// Returns true if all uses of the given range inside the given loop
// have Any allocation policy.
static bool HasOnlyUnconstrainedUsesInLoop(LiveRange* range,
                                           BlockInfo* loop_header) {
  const intptr_t boundary = loop_header->last_block()->end_pos();

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
  for (intptr_t i = 0; i < (block_count - 1); i++) {
    BlockEntryInstr* block = postorder_[i];

    BlockInfo* block_info = BlockInfoAt(block->start_pos());

    // For every SSA value that is live out of this block, create an interval
    // that covers the whole block.  It will be shortened if we encounter a
    // definition of this value in this block.
    for (BitVector::Iterator it(liveness_.GetLiveOutSetAt(i));
         !it.Done();
         it.Advance()) {
      LiveRange* range = GetLiveRange(it.Current());
      range->AddUseInterval(block->start_pos(), block->end_pos());
    }

    BlockInfo* loop_header = block_info->loop_header();
    if ((loop_header != NULL) && (loop_header->last_block() == block)) {
      current_interference_set =
          new BitVector(flow_graph_.max_virtual_register_number());
      ASSERT(loop_header->backedge_interference() == NULL);
      // All values flowing into the loop header are live at the back-edge and
      // can interfere with phi moves.
      current_interference_set->AddAll(
          liveness_.GetLiveInSet(loop_header->entry()));
      loop_header->set_backedge_interference(
          current_interference_set);
    }

    // Connect outgoing phi-moves that were created in NumberInstructions
    // and find last instruction that contributes to liveness.
    Instruction* current = ConnectOutgoingPhiMoves(block,
                                                   current_interference_set);

    // Now process all instructions in reverse order.
    while (current != block) {
      // Skip parallel moves that we insert while processing instructions.
      if (!current->IsParallelMove()) {
        ProcessOneInstruction(block, current, current_interference_set);
      }
      current = current->previous();
    }


    // Check if any values live into the loop can be spilled for free.
    if (block_info->is_loop_header()) {
      current_interference_set = NULL;
      for (BitVector::Iterator it(liveness_.GetLiveInSetAt(i));
           !it.Done();
           it.Advance()) {
        LiveRange* range = GetLiveRange(it.Current());
        if (HasOnlyUnconstrainedUsesInLoop(range, block_info)) {
          range->MarkHasOnlyUnconstrainedUsesInLoop(block_info->loop_id());
        }
      }
    }

    if (block->IsJoinEntry()) {
      ConnectIncomingPhiMoves(block->AsJoinEntry());
    } else if (block->IsCatchBlockEntry()) {
      // Process initial definitions.
      CatchBlockEntryInstr* catch_entry = block->AsCatchBlockEntry();
      for (intptr_t i = 0;
           i < catch_entry->initial_definitions()->length();
           i++) {
        Definition* defn = (*catch_entry->initial_definitions())[i];
        LiveRange* range = GetLiveRange(defn->ssa_temp_index());
        range->DefineAt(catch_entry->start_pos());  // Defined at block entry.
        ProcessInitialDefinition(defn, range, catch_entry);
      }
      // Block the two fixed registers used by CatchBlockEntryInstr from the
      // block start to until the end of the instruction so that they are
      // preserved.
      intptr_t start = catch_entry->start_pos();
      BlockLocation(Location::RegisterLocation(kExceptionObjectReg),
                    start,
                    ToInstructionEnd(start));
      BlockLocation(Location::RegisterLocation(kStackTraceObjectReg),
                    start,
                    ToInstructionEnd(start));
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


void FlowGraphAllocator::ProcessInitialDefinition(Definition* defn,
                                                  LiveRange* range,
                                                  BlockEntryInstr* block) {
  // Save the range end because it may change below.
  intptr_t range_end = range->End();
  if (defn->IsParameter()) {
    ParameterInstr* param = defn->AsParameter();
    // Assert that copied and non-copied parameters are mutually exclusive.
    // This might change in the future and, if so, the index will be wrong.
    ASSERT((flow_graph_.num_copied_params() == 0) ||
           (flow_graph_.num_non_copied_params() == 0));
    // Slot index for the leftmost copied parameter is 0.
    intptr_t slot_index = param->index();
    // Slot index for the rightmost fixed parameter is -1.
    slot_index -= flow_graph_.num_non_copied_params();

    range->set_assigned_location(Location::StackSlot(slot_index));
    range->set_spill_slot(Location::StackSlot(slot_index));
  } else {
    ConstantInstr* constant = defn->AsConstant();
    ASSERT(constant != NULL);
    range->set_assigned_location(Location::Constant(constant->value()));
    range->set_spill_slot(Location::Constant(constant->value()));
  }
  AssignSafepoints(defn, range);
  range->finger()->Initialize(range);
  UsePosition* use =
      range->finger()->FirstRegisterBeneficialUse(block->start_pos());
  if (use != NULL) {
    LiveRange* tail =
        SplitBetween(range, block->start_pos(), use->pos());
    // Parameters and constants are tagged, so allocated to CPU registers.
    CompleteRange(tail, Location::kRegister);
  }
  ConvertAllUses(range);
  if (defn->IsParameter() && (range->spill_slot().stack_index() >= 0)) {
    // Parameters above the frame pointer consume spill slots and are marked
    // in stack maps.
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


static Location::Kind RegisterKindForResult(Instruction* instr) {
  if ((instr->representation() == kUnboxedDouble) ||
      (instr->representation() == kUnboxedFloat32x4) ||
      (instr->representation() == kUnboxedInt32x4) ||
      (instr->representation() == kUnboxedFloat64x2) ||
      (instr->representation() == kPairOfUnboxedDouble)) {
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
    BlockEntryInstr* block, BitVector* interfere_at_backedge) {
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
  const intptr_t pos = goto_instr->lifetime_position();

  JoinEntryInstr* join = goto_instr->successor();
  ASSERT(join != NULL);

  // Search for the index of the current block in the predecessors of
  // the join.
  const intptr_t pred_idx = join->IndexOfPredecessor(block);

  // Record the corresponding phi input use for each phi.
  intptr_t move_idx = 0;
  for (PhiIterator it(join); !it.Done(); it.Advance()) {
    // TODO(johnmccutchan): Fix handling of PhiInstr with PairLocation.
    PhiInstr* phi = it.Current();
    Value* val = phi->InputAt(pred_idx);
    MoveOperands* move = parallel_move->MoveOperandsAt(move_idx);

    ConstantInstr* constant = val->definition()->AsConstant();
    if (constant != NULL) {
      move->set_src(Location::Constant(constant->value()));
      move_idx++;
      continue;
    }

    // Expected shape of live ranges:
    //
    //                 g  g'
    //      value    --*
    //

    const intptr_t vreg = val->definition()->ssa_temp_index();
    LiveRange* range = GetLiveRange(vreg);
    if (interfere_at_backedge != NULL) interfere_at_backedge->Add(vreg);

    range->AddUseInterval(block->start_pos(), pos);
    range->AddHintedUse(pos, move->src_slot(), move->dest_slot());

    move->set_src(Location::PrefersRegister());
    move_idx++;
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
  const bool is_loop_header = BlockInfoAt(join->start_pos())->is_loop_header();
  intptr_t move_idx = 0;
  for (PhiIterator it(join); !it.Done(); it.Advance()) {
    // TODO(johnmccutchan): Fix handling of PhiInstr with PairLocation.
    PhiInstr* phi = it.Current();
    ASSERT(phi != NULL);
    const intptr_t vreg = phi->ssa_temp_index();
    ASSERT(vreg >= 0);

    // Expected shape of live range:
    //
    //                 B
    //      phi        [--------
    //
    LiveRange* range = GetLiveRange(vreg);
    range->DefineAt(pos);  // Shorten live range.

    if (is_loop_header) range->mark_loop_phi();

    for (intptr_t pred_idx = 0; pred_idx < phi->InputCount(); pred_idx++) {
      BlockEntryInstr* pred = join->PredecessorAt(pred_idx);
      GotoInstr* goto_instr = pred->last_instruction()->AsGoto();
      ASSERT((goto_instr != NULL) && (goto_instr->HasParallelMove()));
      MoveOperands* move =
          goto_instr->parallel_move()->MoveOperandsAt(move_idx);
      move->set_dest(Location::PrefersRegister());
      range->AddUse(pos, move->dest_slot());
    }

    // All phi resolution moves are connected. Phi's live range is
    // complete.
    AssignSafepoints(phi, range);

    CompleteRange(range, RegisterKindForResult(phi));

    move_idx++;
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
    const intptr_t use_pos = current->lifetime_position() + 1;

    Location* locations =
        Isolate::Current()->current_zone()->Alloc<Location>(env->Length());

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
        locations[i] = Location::Constant(constant->value());
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
  Location* locations =
      Isolate::Current()->current_zone()->Alloc<Location>(mat->InputCount());

  for (intptr_t i = 0; i < mat->InputCount(); ++i) {
    Definition* def = mat->InputAt(i)->definition();

    ConstantInstr* constant = def->AsConstant();
    if (constant != NULL) {
      locations[i] = Location::Constant(constant->value());
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
    } else {
      locations[i] = Location::Any();
      LiveRange* range = GetLiveRange(def->ssa_temp_index());
      range->AddUseInterval(block_start_pos, use_pos);
      range->AddUse(use_pos, &locations[i]);
    }
  }

  mat->set_locations(locations);
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
    MoveOperands* move =
        AddMoveAt(pos - 1, *in_ref, Location::Any());
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
      MoveOperands* move = AddMoveAt(pos,
                                     Location::RequiresRegister(),
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

  LiveRange* range = vreg >= 0 ?
      GetLiveRange(vreg) : MakeLiveRangeForTemporary();

  // Process output and finalize its liverange.
  if (out->IsMachineRegister()) {
    // Fixed output location. Expected shape of live range:
    //
    //                    i  i' j  j'
    //    register        [--)
    //    output             [-------
    //
    BlockLocation(*out, pos, pos + 1);

    if (range->vreg() == kTempVirtualRegister) return;

    // We need to emit move connecting fixed register with another location
    // that will be allocated for this output's live range.
    // Special case: fixed output followed by a fixed input last use.
    UsePosition* use = range->first_use();

    // If the value has no uses we don't need to allocate it.
    if (use == NULL) return;

    if (use->pos() == (pos + 1)) {
      ASSERT(use->location_slot()->IsUnallocated());
      *(use->location_slot()) = *out;

      // Remove first use. It was allocated.
      range->set_first_use(range->first_use()->next());
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

    // TODO(johnmccutchan): Without this I get allocated a register instead
    // of an FPU register. Figure out why.

    *out = *in_ref;
    // Create move that will copy value between input and output.
    MoveOperands* move = AddMoveAt(pos,
                                   Location::RequiresRegister(),
                                   Location::Any());

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

    if ((interference_set != NULL) &&
        (range->vreg() >= 0) &&
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
  CompleteRange(range, RegisterKindForResult(def));
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
    LiveRange* range = (def->ssa_temp_index() != -1) ?
        GetLiveRange(def->ssa_temp_index()) : NULL;

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
      const Object& value = def->AsConstant()->value();
      range->set_assigned_location(Location::Constant(value));
      range->set_spill_slot(Location::Constant(value));
      range->finger()->Initialize(range);
      ConvertAllUses(range);

      locs->set_out(0, Location::NoLocation());
      return;
    }
  }

  const intptr_t pos = current->lifetime_position();
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
         j < locs->input_count();
         j++) {
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
        ProcessOneInput(block, pos, pair->SlotAt(0),
                        input, vreg, live_registers);
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

  // Block all allocatable registers for calls and record the stack bitmap.
  if (locs->always_calls()) {
    // Expected shape of live range:
    //
    //              i  i'
    //              [--)
    //
    // The stack bitmap describes the position i.
    for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
      BlockLocation(Location::RegisterLocation(static_cast<Register>(reg)),
                    pos,
                    pos + 1);
    }

    for (intptr_t reg = 0; reg < kNumberOfFpuRegisters; reg++) {
      BlockLocation(
          Location::FpuRegisterLocation(static_cast<FpuRegister>(reg)),
          pos,
          pos + 1);
    }


#if defined(DEBUG)
    // Verify that temps, inputs and output were specified as fixed
    // locations.  Every register is blocked now so attempt to
    // allocate will not succeed.
    for (intptr_t j = 0; j < locs->temp_count(); j++) {
      ASSERT(!locs->temp(j).IsPairLocation());
      ASSERT(!locs->temp(j).IsUnallocated());
    }

    for (intptr_t j = 0; j < locs->input_count(); j++) {
      if (locs->in(j).IsPairLocation()) {
        PairLocation* pair = locs->in_slot(j)->AsPairLocation();
        ASSERT(!pair->At(0).IsUnallocated());
        ASSERT(!pair->At(1).IsUnallocated());
      } else {
        ASSERT(!locs->in(j).IsUnallocated());
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
      ProcessOneOutput(block, pos,  // BlockEntry, seq.
                       pair->SlotAt(0), def,  // (output) Location, Definition.
                       def->ssa_temp_index(),  // (output) virtual register.
                       true,  // output mapped to first input.
                       in_pair->SlotAt(0), input,  // (input) Location, Def.
                       input->ssa_temp_index(),  // (input) virtual register.
                       interference_set);
      ProcessOneOutput(block, pos,
                       pair->SlotAt(1), def,
                       ToSecondPairVreg(def->ssa_temp_index()),
                       true,
                       in_pair->SlotAt(1), input,
                       ToSecondPairVreg(input->ssa_temp_index()),
                       interference_set);
    } else {
      // Each element of the pair is assigned it's own virtual register number
      // and is allocated its own LiveRange.
      ProcessOneOutput(block, pos,
                       pair->SlotAt(0), def,
                       def->ssa_temp_index(),
                       false,            // output is not mapped to first input.
                       NULL, NULL, -1,   // First input not needed.
                       interference_set);
      ProcessOneOutput(block, pos,
                       pair->SlotAt(1), def,
                       ToSecondPairVreg(def->ssa_temp_index()),
                       false,
                       NULL, NULL, -1,
                       interference_set);
    }
  } else {
    if (output_same_as_first_input) {
      Location* in_ref = locs->in_slot(0);
      Definition* input = current->InputAt(0)->definition();
      ASSERT(!in_ref->IsPairLocation());
      ProcessOneOutput(block, pos,  // BlockEntry, Instruction, seq.
                       out, def,  // (output) Location, Definition.
                       def->ssa_temp_index(),  // (output) virtual register.
                       true,  // output mapped to first input.
                       in_ref, input,  // (input) Location, Def.
                       input->ssa_temp_index(),  // (input) virtual register.
                       interference_set);
    } else {
      ProcessOneOutput(block, pos,
                       out, def,
                       def->ssa_temp_index(),
                       false,            // output is not mapped to first input.
                       NULL, NULL, -1,   // First input not needed.
                       interference_set);
    }
  }
}


static ParallelMoveInstr* CreateParallelMoveBefore(Instruction* instr,
                                                   intptr_t pos) {
  ASSERT(pos > 0);
  Instruction* prev = instr->previous();
  ParallelMoveInstr* move = prev->AsParallelMove();
  if ((move == NULL) || (move->lifetime_position() != pos)) {
    move = new ParallelMoveInstr();
    prev->LinkTo(move);
    move->LinkTo(instr);
    move->set_lifetime_position(pos);
  }
  return move;
}


static ParallelMoveInstr* CreateParallelMoveAfter(Instruction* instr,
                                                  intptr_t pos) {
  Instruction* next = instr->next();
  if (next->IsParallelMove() && (next->lifetime_position() == pos)) {
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
    BlockInfo* info = new BlockInfo(block);

    instructions_.Add(block);
    block_info_.Add(info);
    block->set_start_pos(pos);
    block->set_lifetime_position(pos);
    pos += 2;

    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      // Do not assign numbers to parallel move instructions.
      if (!current->IsParallelMove()) {
        instructions_.Add(current);
        block_info_.Add(info);
        current->set_lifetime_position(pos);
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
    if ((join != NULL) &&
        (join->phis() != NULL) &&
        !join->phis()->is_empty()) {
      const intptr_t phi_count = join->phis()->length();
      for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
        // Insert the move between the last two instructions of the
        // predecessor block (all such blocks have at least two instructions:
        // the block entry and goto instructions.)
        Instruction* last = block->PredecessorAt(i)->last_instruction();
        ASSERT(last->IsGoto());

        ParallelMoveInstr* move = last->AsGoto()->GetParallelMove();

        // Populate the ParallelMove with empty moves.
        for (intptr_t j = 0; j < phi_count; j++) {
          move->AddMove(Location::NoLocation(), Location::NoLocation());
        }
      }
    }
  }
}


// Discover structural (reducible) loops nesting structure.
void FlowGraphAllocator::DiscoverLoops() {
  // This algorithm relies on the assumption that we emit blocks in reverse
  // postorder, so postorder number can be used to identify loop nesting.
  //
  // TODO(vegorov): consider using a generic algorithm to correctly discover
  // both headers of reducible and irreducible loops.
  BlockInfo* current_loop = NULL;

  intptr_t loop_id = 0;  // All loop headers have a unique id.

  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];
    GotoInstr* goto_instr = block->last_instruction()->AsGoto();
    if (goto_instr != NULL) {
      JoinEntryInstr* successor = goto_instr->successor();
      if (successor->postorder_number() > i) {
        // This is back-edge.
        BlockInfo* successor_info = BlockInfoAt(successor->lifetime_position());
        ASSERT(successor_info->entry() == successor);
        if (!successor_info->is_loop_header() &&
            ((current_loop == NULL) ||
             (current_loop->entry()->postorder_number() >
                  successor_info->entry()->postorder_number()))) {
          ASSERT(successor_info != current_loop);

          successor_info->mark_loop_header();
          successor_info->set_loop_id(loop_id++);
          successor_info->set_last_block(block);
          // For loop header loop information points to the outer loop.
          successor_info->set_loop(current_loop);
          current_loop = successor_info;
        }
      }
    }

    if (current_loop != NULL) {
      BlockInfo* current_info = BlockInfoAt(block->lifetime_position());
      if (current_info == current_loop) {
        ASSERT(current_loop->is_loop_header());
        current_loop = current_info->loop();
      } else {
        current_info->set_loop(current_loop);
      }
    }
  }
}


Instruction* FlowGraphAllocator::InstructionAt(intptr_t pos) const {
  return instructions_[pos / 2];
}


BlockInfo* FlowGraphAllocator::BlockInfoAt(intptr_t pos) const {
  return block_info_[pos / 2];
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
  while (a != NULL && a->end() <= start) a = a->next();
  first_pending_use_interval_ = a;
  if (first_pending_use_interval_ == NULL) {
    return true;
  }
  return false;
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
       use != NULL;
       use = use->next()) {
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
       use != NULL;
       use = use->next()) {
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
    // any use occuring at it.
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


LiveRange* LiveRange::MakeTemp(intptr_t pos, Location* location_slot) {
  UNREACHABLE();
  return NULL;
}


template<typename PositionType>
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
    first_after_split = new UseInterval(split_pos,
                                        interval->end(),
                                        interval->next());
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

  UseInterval* last_use_interval = (last_before_split == last_use_interval_) ?
    first_after_split : last_use_interval_;
  next_sibling_ = new LiveRange(vreg(),
                                representation(),
                                first_use_after_split,
                                first_after_split,
                                last_use_interval,
                                first_safepoint_after_split,
                                next_sibling_);

  TRACE_ALLOC(OS::Print("  split sibling [%" Pd ", %" Pd ")\n",
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
  TRACE_ALLOC(OS::Print("split v%" Pd " [%" Pd ", %" Pd
                        ") between [%" Pd ", %" Pd ")\n",
                        range->vreg(), range->Start(), range->End(), from, to));

  intptr_t split_pos = kIllegalPosition;

  BlockInfo* split_block = BlockInfoAt(to);
  if (from < split_block->entry()->lifetime_position()) {
    // Interval [from, to) spans multiple blocks.

    // If last block is inside a loop prefer splitting at outermost loop's
    // header.
    BlockInfo* loop_header = split_block->loop();
    while ((loop_header != NULL) &&
           (from < loop_header->entry()->lifetime_position())) {
      split_block = loop_header;
      loop_header = loop_header->loop();
    }

    // Split at block's start.
    split_pos = split_block->entry()->lifetime_position();
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
  TRACE_ALLOC(OS::Print("spill v%" Pd " [%" Pd ", %" Pd ") "
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
  TRACE_ALLOC(OS::Print("spill v%" Pd " [%" Pd ", %" Pd ") after %" Pd "\n",
                        range->vreg(), range->Start(), range->End(), from));

  // When spilling the value inside the loop check if this spill can
  // be moved outside.
  BlockInfo* block_info = BlockInfoAt(from);
  if (block_info->is_loop_header() || (block_info->loop() != NULL)) {
    BlockInfo* loop_header =
        block_info->is_loop_header() ? block_info : block_info->loop();

    if ((range->Start() <= loop_header->entry()->start_pos()) &&
        RangeHasOnlyUnconstrainedUsesInLoop(range, loop_header->loop_id())) {
      ASSERT(loop_header->entry()->start_pos() <= from);
      from = loop_header->entry()->start_pos();
      TRACE_ALLOC(OS::Print("  moved spill position to loop header %" Pd "\n",
                            from));
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
       (range->representation() == kUnboxedInt32x4)   ||
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

  if (idx == spill_slots_.length()) {
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
    range->set_spill_slot(Location::StackSlot(idx));
  } else {
    // We use the index of the slot with the lowest address as an index for the
    // FPU register spill slot. In terms of indexes this relation is inverted:
    // so we have to take the highest index.
    const intptr_t slot_idx = cpu_spill_slot_count_ +
        idx * kDoubleSpillFactor + (kDoubleSpillFactor - 1);

    Location location;
    if ((range->representation() == kUnboxedFloat32x4) ||
        (range->representation() == kUnboxedInt32x4) ||
        (range->representation() == kUnboxedFloat64x2)) {
      ASSERT(need_quad);
      location = Location::QuadStackSlot(slot_idx);
    } else {
      ASSERT((range->representation() == kUnboxedDouble));
      location = Location::DoubleStackSlot(slot_idx);
    }
    range->set_spill_slot(location);
  }

  spilled_.Add(range);
}


void FlowGraphAllocator::MarkAsObjectAtSafepoints(LiveRange* range) {
  intptr_t stack_index = range->spill_slot().stack_index();
  ASSERT(stack_index >= 0);

  while (range != NULL) {
    for (SafepointPosition* safepoint = range->first_safepoint();
         safepoint != NULL;
         safepoint = safepoint->next()) {
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
    intptr_t reg, LiveRange* unallocated) {
  intptr_t intersection = kMaxPosition;
  for (intptr_t i = 0; i < registers_[reg]->length(); i++) {
    LiveRange* allocated = (*registers_[reg])[i];
    if (allocated == NULL) continue;

    UseInterval* allocated_head =
        allocated->finger()->first_pending_use_interval();
    if (allocated_head->start() >= intersection) continue;

    const intptr_t pos = FirstIntersection(
        unallocated->finger()->first_pending_use_interval(),
        allocated_head);
    if (pos < intersection) intersection = pos;
  }
  return intersection;
}


void ReachingDefs::AddPhi(PhiInstr* phi) {
  // TODO(johnmccutchan): Fix handling of PhiInstr with PairLocation.
  if (phi->reaching_defs() == NULL) {
    phi->set_reaching_defs(
        new BitVector(flow_graph_.max_virtual_register_number()));

    // Compute initial set reaching defs set.
    bool depends_on_phi = false;
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Definition* input = phi->InputAt(i)->definition();
      if (input->IsPhi()) {
        depends_on_phi = true;
      }
      phi->reaching_defs()->Add(input->ssa_temp_index());
    }

    // If this phi depends on another phi then we need fix point iteration.
    if (depends_on_phi) phis_.Add(phi);
  }
}


void ReachingDefs::Compute() {
  // Transitively collect all phis that are used by the given phi.
  for (intptr_t i = 0; i < phis_.length(); i++) {
    // TODO(johnmccutchan): Fix handling of PhiInstr with PairLocation.
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
      free_until = FirstIntersectionWithAllocated(hint.register_code(),
                                                  unallocated);
      candidate = hint.register_code();
    }

    TRACE_ALLOC(OS::Print("found hint %s for v%" Pd ": free until %" Pd "\n",
                          hint.Name(),
                          unallocated->vreg(),
                          free_until));
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
  BlockInfo* loop_header = BlockInfoAt(unallocated->Start())->loop_header();
  if ((unallocated->vreg() >= 0) &&
      (loop_header != NULL) &&
      (free_until >= loop_header->last_block()->end_pos()) &&
      loop_header->backedge_interference()->Contains(unallocated->vreg())) {
    GrowableArray<bool> used_on_backedge(number_of_registers_);
    for (intptr_t i = 0; i < number_of_registers_; i++) {
      used_on_backedge.Add(false);
    }

    for (PhiIterator it(loop_header->entry()->AsJoinEntry());
         !it.Done();
         it.Advance()) {
      // TODO(johnmccutchan): Fix handling of PhiInstr with PairLocation.
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
    }

    if (used_on_backedge[candidate]) {
      TRACE_ALLOC(OS::Print(
          "considering %s for v%" Pd ": has interference on the back edge"
          " {loop [%" Pd ", %" Pd ")}\n",
          MakeRegisterLocation(candidate).Name(),
          unallocated->vreg(),
          loop_header->entry()->start_pos(),
          loop_header->last_block()->end_pos()));
      for (intptr_t reg = 0; reg < NumberOfRegisters(); ++reg) {
        if (blocked_registers_[reg] ||
            (reg == candidate) ||
            used_on_backedge[reg]) {
          continue;
        }

        const intptr_t intersection =
            FirstIntersectionWithAllocated(reg, unallocated);
        if (intersection >= free_until) {
          candidate = reg;
          free_until = intersection;
          TRACE_ALLOC(OS::Print(
              "found %s for v%" Pd " with no interference on the back edge\n",
              MakeRegisterLocation(candidate).Name(),
              candidate));
          break;
        }
      }
    }
  }

  TRACE_ALLOC(OS::Print("assigning free register "));
  TRACE_ALLOC(MakeRegisterLocation(candidate).Print());
  TRACE_ALLOC(OS::Print(" to v%" Pd "\n", unallocated->vreg()));

  if (free_until != kMaxPosition) {
    // There was an intersection. Split unallocated.
    TRACE_ALLOC(OS::Print("  splitting at %" Pd "\n", free_until));
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


bool FlowGraphAllocator::IsCheapToEvictRegisterInLoop(BlockInfo* loop,
                                                      intptr_t reg) {
  const intptr_t loop_start = loop->entry()->start_pos();
  const intptr_t loop_end = loop->last_block()->end_pos();

  for (intptr_t i = 0; i < registers_[reg]->length(); i++) {
    LiveRange* allocated = (*registers_[reg])[i];

    UseInterval* interval = allocated->finger()->first_pending_use_interval();
    if (interval->Contains(loop_start)) {
      if (!RangeHasOnlyUnconstrainedUsesInLoop(allocated, loop->loop_id())) {
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

  BlockInfo* loop_header = BlockInfoAt(phi_range->Start());
  ASSERT(loop_header->is_loop_header());
  ASSERT(phi_range->Start() == loop_header->entry()->start_pos());

  for (intptr_t reg = 0; reg < NumberOfRegisters(); ++reg) {
    if (blocked_registers_[reg]) continue;
    if (IsCheapToEvictRegisterInLoop(loop_header, reg)) {
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
      (register_use != NULL) ? register_use->pos()
                             : unallocated->Start();
  if (free_until < register_use_pos) {
    // Can't acquire free register. Spill until we really need one.
    ASSERT(unallocated->Start() < ToInstructionStart(register_use_pos));
    SpillBetween(unallocated, unallocated->Start(), register_use->pos());
    return;
  }

  ASSERT(candidate != kNoRegister);

  TRACE_ALLOC(OS::Print("assigning blocked register "));
  TRACE_ALLOC(MakeRegisterLocation(candidate).Print());
  TRACE_ALLOC(OS::Print(" to live range v%" Pd " until %" Pd "\n",
                        unallocated->vreg(), blocked_at));

  if (blocked_at < unallocated->End()) {
    // Register is blocked before the end of the live range.  Split the range
    // at latest at blocked_at position.
    LiveRange* tail = SplitBetween(unallocated,
                                   unallocated->Start(),
                                   blocked_at + 1);
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

      UsePosition* use =
          allocated->finger()->FirstInterferingUse(start);
      if ((use != NULL) && ((ToInstructionStart(use->pos()) - start) <= 1)) {
        // This register is blocked by interval that is used
        // as register in the current instruction and can't
        // be spilled.
        return false;
      }

      const intptr_t use_pos = (use != NULL) ? use->pos()
                                             : allocated->End();

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
      allocated->finger()->first_pending_use_interval(),
      first_unallocated);
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

  Instruction* instr = InstructionAt(pos);

  ParallelMoveInstr* parallel_move = NULL;
  if (IsInstructionStartPosition(pos)) {
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
  TRACE_ALLOC(OS::Print("  use at %" Pd " converted to ", use->pos()));
  TRACE_ALLOC(loc.Print());
  TRACE_ALLOC(OS::Print("\n"));
  *slot = loc;
}


void FlowGraphAllocator::ConvertAllUses(LiveRange* range) {
  if (range->vreg() == kNoVirtualRegister) return;

  const Location loc = range->assigned_location();
  ASSERT(!loc.IsInvalid());

  TRACE_ALLOC(OS::Print("range [%" Pd ", %" Pd ") "
                        "for v%" Pd " has been allocated to ",
                        range->Start(), range->End(), range->vreg()));
  TRACE_ALLOC(loc.Print());
  TRACE_ALLOC(OS::Print(":\n"));

  for (UsePosition* use = range->first_use(); use != NULL; use = use->next()) {
    ConvertUseTo(use, loc);
  }

  // Add live registers at all safepoints for instructions with slow-path
  // code.
  if (loc.IsMachineRegister()) {
    for (SafepointPosition* safepoint = range->first_safepoint();
         safepoint != NULL;
         safepoint = safepoint->next()) {
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

  for (UseInterval* interval = first_use_interval_;
       interval != NULL;
       interval = interval->next()) {
    if (interval->Contains(pos)) {
      return true;
    }
  }

  return false;
}


void FlowGraphAllocator::AssignSafepoints(Definition* defn,
                                          LiveRange* range) {
  for (intptr_t i = safepoints_.length() - 1; i >= 0; i--) {
    Instruction* safepoint_instr = safepoints_[i];
    if (safepoint_instr == defn) {
      // The value is not live until after the definition is fully executed,
      // don't assign the safepoint inside the definition itself to
      // definition's liverange.
      continue;
    }

    const intptr_t pos = safepoint_instr->lifetime_position();
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
    TRACE_ALLOC(OS::Print("Processing live range for v%" Pd " "
                          "starting at %" Pd "\n",
                          range->vreg(),
                          start));

    // TODO(vegorov): eagerly spill liveranges without register uses.
    AdvanceActiveIntervals(start);

    if (!AllocateFreeRegister(range)) {
      AllocateAnyRegister(range);
    }
  }

  // All allocation decisions were done.
  ASSERT(unallocated_.is_empty());

  // Finish allocation.
  AdvanceActiveIntervals(kMaxPosition);
  TRACE_ALLOC(OS::Print("Allocation completed\n"));
}


bool FlowGraphAllocator::TargetLocationIsSpillSlot(LiveRange* range,
                                                   Location target) {
  if (target.IsStackSlot() ||
      target.IsDoubleStackSlot() ||
      target.IsConstant()) {
    ASSERT(GetLiveRange(range->vreg())->spill_slot().Equals(target));
    return true;
  }
  return false;
}


void FlowGraphAllocator::ConnectSplitSiblings(LiveRange* parent,
                                              BlockEntryInstr* source_block,
                                              BlockEntryInstr* target_block) {
  TRACE_ALLOC(OS::Print("Connect v%" Pd " on the edge B%" Pd " -> B%" Pd "\n",
                        parent->vreg(),
                        source_block->block_id(),
                        target_block->block_id()));
  if (parent->next_sibling() == NULL) {
    // Nothing to connect. The whole range was allocated to the same location.
    TRACE_ALLOC(OS::Print("range v%" Pd " has no siblings\n", parent->vreg()));
    return;
  }

  const intptr_t source_pos = source_block->end_pos() - 1;
  ASSERT(IsInstructionEndPosition(source_pos));

  const intptr_t target_pos = target_block->start_pos();

  Location target;
  Location source;

#if defined(DEBUG)
  LiveRange* source_cover = NULL;
  LiveRange* target_cover = NULL;
#endif

  LiveRange* range = parent;
  while ((range != NULL) && (source.IsInvalid() || target.IsInvalid())) {
    if (range->CanCover(source_pos)) {
      ASSERT(source.IsInvalid());
      source = range->assigned_location();
#if defined(DEBUG)
      source_cover = range;
#endif
    }
    if (range->CanCover(target_pos)) {
      ASSERT(target.IsInvalid());
      target = range->assigned_location();
#if defined(DEBUG)
      target_cover = range;
#endif
    }

    range = range->next_sibling();
  }

  TRACE_ALLOC(OS::Print("connecting v%" Pd " between [%" Pd ", %" Pd ") {%s} "
                        "to [%" Pd ", %" Pd ") {%s}\n",
                        parent->vreg(),
                        source_cover->Start(),
                        source_cover->End(),
                        source.Name(),
                        target_cover->Start(),
                        target_cover->End(),
                        target.Name()));

  // Siblings were allocated to the same register.
  if (source.Equals(target)) return;

  // Values are eagerly spilled. Spill slot already contains appropriate value.
  if (TargetLocationIsSpillSlot(parent, target)) {
    return;
  }

  Instruction* last = source_block->last_instruction();
  if ((last->SuccessorCount() == 1) && !source_block->IsGraphEntry()) {
    ASSERT(last->IsGoto());
    last->AsGoto()->GetParallelMove()->AddMove(target, source);
  } else {
    target_block->GetParallelMove()->AddMove(target, source);
  }
}


void FlowGraphAllocator::ResolveControlFlow() {
  // Resolve linear control flow between touching split siblings
  // inside basic blocks.
  for (intptr_t vreg = 0; vreg < live_ranges_.length(); vreg++) {
    LiveRange* range = live_ranges_[vreg];
    if (range == NULL) continue;

    while (range->next_sibling() != NULL) {
      LiveRange* sibling = range->next_sibling();
      TRACE_ALLOC(OS::Print("connecting [%" Pd ", %" Pd ") [",
                            range->Start(), range->End()));
      TRACE_ALLOC(range->assigned_location().Print());
      TRACE_ALLOC(OS::Print("] to [%" Pd ", %" Pd ") [",
                            sibling->Start(), sibling->End()));
      TRACE_ALLOC(sibling->assigned_location().Print());
      TRACE_ALLOC(OS::Print("]\n"));
      if ((range->End() == sibling->Start()) &&
          !TargetLocationIsSpillSlot(range, sibling->assigned_location()) &&
          !range->assigned_location().Equals(sibling->assigned_location()) &&
          !IsBlockEntry(range->End())) {
        AddMoveAt(sibling->Start(),
                  sibling->assigned_location(),
                  range->assigned_location());
      }
      range = sibling;
    }
  }

  // Resolve non-linear control flow across branches.
  for (intptr_t i = 1; i < block_order_.length(); i++) {
    BlockEntryInstr* block = block_order_[i];
    BitVector* live = liveness_.GetLiveInSet(block);
    for (BitVector::Iterator it(live); !it.Done(); it.Advance()) {
      LiveRange* range = GetLiveRange(it.Current());
      for (intptr_t j = 0; j < block->PredecessorCount(); j++) {
        ConnectSplitSiblings(range, block->PredecessorAt(j), block);
      }
    }
  }

  // Eagerly spill values.
  // TODO(vegorov): if value is spilled on the cold path (e.g. by the call)
  // this will cause spilling to occur on the fast path (at the definition).
  for (intptr_t i = 0; i < spilled_.length(); i++) {
    LiveRange* range = spilled_[i];
    if (range->assigned_location().IsStackSlot() ||
        range->assigned_location().IsDoubleStackSlot() ||
        range->assigned_location().IsConstant()) {
      ASSERT(range->assigned_location().Equals(range->spill_slot()));
    } else {
      AddMoveAt(range->Start() + 1,
                range->spill_slot(),
                range->assigned_location());
    }
  }
}


static Representation RepresentationForRange(Representation definition_rep) {
  if (definition_rep == kUnboxedMint) {
    // kUnboxedMint is split into two ranges, each of which are kUntagged.
    return kUntagged;
  } else if (definition_rep == kUnboxedUint32) {
    // kUnboxedUint32 is untagged.
    return kUntagged;
  }
  return definition_rep;
}


void FlowGraphAllocator::CollectRepresentations() {
  // Parameters.
  GraphEntryInstr* graph_entry = flow_graph_.graph_entry();
  for (intptr_t i = 0; i < graph_entry->initial_definitions()->length(); ++i) {
    Definition* def = (*graph_entry->initial_definitions())[i];
    value_representations_[def->ssa_temp_index()] =
        RepresentationForRange(def->representation());
    ASSERT(!def->HasPairRepresentation());
  }

  for (BlockIterator it = flow_graph_.reverse_postorder_iterator();
       !it.Done();
       it.Advance()) {
    BlockEntryInstr* block = it.Current();

    // Catch entry.
    if (block->IsCatchBlockEntry()) {
      CatchBlockEntryInstr* catch_entry = block->AsCatchBlockEntry();
      for (intptr_t i = 0;
           i < catch_entry->initial_definitions()->length();
           ++i) {
        Definition* def = (*catch_entry->initial_definitions())[i];
        ASSERT(!def->HasPairRepresentation());
        value_representations_[def->ssa_temp_index()] =
            RepresentationForRange(def->representation());
      }
    }
    // Phis.
    if (block->IsJoinEntry()) {
      JoinEntryInstr* join = block->AsJoinEntry();
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        // TODO(johnmccutchan): Fix handling of PhiInstr with PairLocation.
        PhiInstr* phi = it.Current();
        if ((phi != NULL) && (phi->ssa_temp_index() >= 0)) {
          ASSERT(!phi->HasPairRepresentation());
          value_representations_[phi->ssa_temp_index()] =
              RepresentationForRange(phi->representation());
        }
      }
    }
    // Normal instructions.
    for (ForwardInstructionIterator instr_it(block);
         !instr_it.Done();
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

  DiscoverLoops();

  BuildLiveRanges();

  if (FLAG_print_ssa_liveness) {
    liveness_.Dump();
  }

  if (FLAG_print_ssa_liveranges) {
    const Function& function = flow_graph_.parsed_function().function();

    OS::Print("-- [before ssa allocator] ranges [%s] ---------\n",
              function.ToFullyQualifiedCString());
    PrintLiveRanges();
    OS::Print("----------------------------------------------\n");

    OS::Print("-- [before ssa allocator] ir [%s] -------------\n",
              function.ToFullyQualifiedCString());
    FlowGraphPrinter printer(flow_graph_, true);
    printer.PrintBlocks();
    OS::Print("----------------------------------------------\n");
  }

  PrepareForAllocation(Location::kRegister,
                       kNumberOfCpuRegisters,
                       unallocated_cpu_,
                       cpu_regs_,
                       blocked_cpu_registers_);
  AllocateUnallocatedRanges();

  cpu_spill_slot_count_ = spill_slots_.length();
  spill_slots_.Clear();
  quad_spill_slots_.Clear();
  untagged_spill_slots_.Clear();

  PrepareForAllocation(Location::kFpuRegister,
                       kNumberOfFpuRegisters,
                       unallocated_xmm_,
                       fpu_regs_,
                       blocked_fpu_registers_);
  AllocateUnallocatedRanges();

  ResolveControlFlow();

  GraphEntryInstr* entry = block_order_[0]->AsGraphEntry();
  ASSERT(entry != NULL);
  intptr_t double_spill_slot_count = spill_slots_.length() * kDoubleSpillFactor;
  entry->set_spill_slot_count(cpu_spill_slot_count_ + double_spill_slot_count);

  if (FLAG_print_ssa_liveranges) {
    const Function& function = flow_graph_.parsed_function().function();

    OS::Print("-- [after ssa allocator] ranges [%s] ---------\n",
              function.ToFullyQualifiedCString());
    PrintLiveRanges();
    OS::Print("----------------------------------------------\n");

    OS::Print("-- [after ssa allocator] ir [%s] -------------\n",
              function.ToFullyQualifiedCString());
    FlowGraphPrinter printer(flow_graph_, true);
    printer.PrintBlocks();
    OS::Print("----------------------------------------------\n");
  }
}


}  // namespace dart
