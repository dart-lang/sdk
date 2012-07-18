// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_allocator.h"

#include "vm/bit_vector.h"
#include "vm/intermediate_language.h"
#include "vm/il_printer.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"

namespace dart {

DEFINE_FLAG(bool, print_ssa_liveness, false,
            "Print liveness for ssa variables.");
DEFINE_FLAG(bool, trace_ssa_allocator, false,
            "Trace register allocation over SSA.");

#ifdef DEBUG
#define TRACE_ALLOC(m) do {                     \
    if (FLAG_trace_ssa_allocator) OS::Print m ; \
  } while (0)
#else
#define TRACE_ALLOC(m)
#endif


static const intptr_t kNoVirtualRegister = -1;
static const intptr_t kTempVirtualRegister = -2;
static UseInterval* const kPermanentlyBlocked =
  reinterpret_cast<UseInterval*>(-1);
static const intptr_t kIllegalPosition = -1;
static const intptr_t kMaxPosition = 0x7FFFFFFF;


FlowGraphAllocator::FlowGraphAllocator(
  const GrowableArray<BlockEntryInstr*>& block_order,
  FlowGraphBuilder* builder)
  : builder_(builder),
    block_order_(block_order),
    postorder_(builder->postorder_block_entries()),
    live_out_(block_order.length()),
    kill_(block_order.length()),
    live_in_(block_order.length()),
    vreg_count_(builder->current_ssa_temp_index()),
    live_ranges_(builder->current_ssa_temp_index()) {
  for (intptr_t i = 0; i < vreg_count_; i++) live_ranges_.Add(NULL);

  for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
    cpu_regs_[reg] = NULL;
  }

  cpu_regs_[CTX] = kPermanentlyBlocked;
  if (TMP != kNoRegister) {
    cpu_regs_[TMP] = kPermanentlyBlocked;
  }
  cpu_regs_[SPREG] = kPermanentlyBlocked;
  cpu_regs_[FPREG] = kPermanentlyBlocked;
}


void FlowGraphAllocator::ComputeInitialSets() {
  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];

    BitVector* kill = kill_[i];
    BitVector* live_in = live_in_[i];

    if (block->IsJoinEntry()) {
      JoinEntryInstr* join = block->AsJoinEntry();
      if (join->phis() != NULL) {
        for (intptr_t j = 0; j < join->phis()->length(); j++) {
          PhiInstr* phi = (*join->phis())[j];
          if (phi == NULL) continue;
          kill->Add(phi->ssa_temp_index());

          for (intptr_t k = 0; k < phi->InputCount(); k++) {
            Value* val = phi->InputAt(k);
            if (val->IsUse()) {
              BlockEntryInstr* pred = block->PredecessorAt(k);
              const intptr_t use = val->AsUse()->definition()->ssa_temp_index();
              live_out_[pred->postorder_number()]->Add(use);
            }
          }
        }
      }
    }

    // TODO(vegorov): iterate backwards.
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      for (intptr_t j = 0; j < current->InputCount(); j++) {
        Value* input = current->InputAt(j);
        if (input->IsUse()) {
          const intptr_t use = input->AsUse()->definition()->ssa_temp_index();
          if (!kill->Contains(use)) live_in->Add(use);
        }
      }

      // Add uses from the deoptimization environment.
      if (current->env() != NULL) {
        const GrowableArray<Value*>& values = current->env()->values();
        for (intptr_t j = 0; j < values.length(); j++) {
          Value* val = values[j];
          if (val->IsUse()) {
            const intptr_t use = val->AsUse()->definition()->ssa_temp_index();
            if (!kill->Contains(use)) live_in->Add(use);
          }
        }
      }

      Definition* current_def = current->AsDefinition();
      if ((current_def != NULL) && (current_def->ssa_temp_index() >= 0)) {
        kill->Add(current_def->ssa_temp_index());
      }
    }
  }

  // Update initial live_in sets to match live_out sets. Has to be
  // done in a separate path because of backwards branches.
  for (intptr_t i = 0; i < block_count; i++) {
    UpdateLiveIn(postorder_[i]);
  }
}


bool FlowGraphAllocator::UpdateLiveOut(BlockEntryInstr* instr) {
  BitVector* live_out = live_out_[instr->postorder_number()];
  bool changed = false;
  Instruction* last = instr->last_instruction();
  ASSERT(last != NULL);
  for (intptr_t i = 0; i < last->SuccessorCount(); i++) {
    BlockEntryInstr* succ = last->SuccessorAt(i);
    ASSERT(succ != NULL);
    if (live_out->AddAll(live_in_[succ->postorder_number()])) {
      changed = true;
    }
  }
  return changed;
}


bool FlowGraphAllocator::UpdateLiveIn(BlockEntryInstr* instr) {
  BitVector* live_out = live_out_[instr->postorder_number()];
  BitVector* kill = kill_[instr->postorder_number()];
  BitVector* live_in = live_in_[instr->postorder_number()];
  return live_in->KillAndAdd(kill, live_out);
}


void FlowGraphAllocator::ComputeLiveInAndLiveOutSets() {
  const intptr_t block_count = postorder_.length();
  bool changed;
  do {
    changed = false;

    for (intptr_t i = 0; i < block_count; i++) {
      BlockEntryInstr* block = postorder_[i];

      // Live-in set depends only on kill set which does not
      // change in this loop and live-out set.  If live-out
      // set does not change there is no need to recompute
      // live-in set.
      if (UpdateLiveOut(block) && UpdateLiveIn(block)) {
        changed = true;
      }
    }
  } while (changed);
}


void FlowGraphAllocator::AnalyzeLiveness() {
  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    live_out_.Add(new BitVector(vreg_count_));
    kill_.Add(new BitVector(vreg_count_));
    live_in_.Add(new BitVector(vreg_count_));
  }

  ComputeInitialSets();
  ComputeLiveInAndLiveOutSets();
}


static void PrintBitVector(const char* tag, BitVector* v) {
  OS::Print("%s:", tag);
  for (BitVector::Iterator it(v); !it.Done(); it.Advance()) {
    OS::Print(" %d", it.Current());
  }
  OS::Print("\n");
}


void FlowGraphAllocator::DumpLiveness() {
  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];
    OS::Print("block @%d -> ", block->block_id());

    Instruction* last = block->last_instruction();
    for (intptr_t j = 0; j < last->SuccessorCount(); j++) {
      BlockEntryInstr* succ = last->SuccessorAt(j);
      OS::Print(" @%d", succ->block_id());
    }
    OS::Print("\n");

    PrintBitVector("  live out", live_out_[i]);
    PrintBitVector("  kill", kill_[i]);
    PrintBitVector("  live in", live_in_[i]);
  }
}


void UseInterval::Print() {
  OS::Print("  [%d, %d) uses {", start_, end_);
  for (UsePosition* use_pos = uses_;
       use_pos != NULL && use_pos->pos() <= end();
       use_pos = use_pos->next()) {
    if (use_pos != uses_) OS::Print(", ");
    OS::Print("%d", use_pos->pos());
  }
  OS::Print("}\n");
}


void UseInterval::AddUse(Instruction* instr,
                         intptr_t pos,
                         Location* location_slot) {
  ASSERT((start_ <= pos) && (pos <= end_));
  ASSERT((instr == NULL) || (instr->lifetime_position() == pos));
  if ((uses_ != NULL) && (uses_->pos() == pos)) {
    if ((location_slot == NULL) || (uses_->location_slot() == location_slot)) {
      return;
    } else if ((uses_->location_slot() == NULL) && (instr == NULL)) {
      uses_->set_location_slot(location_slot);
      return;
    }
  }
  uses_ = new UsePosition(instr, pos, uses_, location_slot);
}


void LiveRange::Print() {
  OS::Print("vreg %d live intervals:\n", vreg_);
  for (UseInterval* interval = head_;
       interval != NULL;
       interval = interval->next_) {
    interval->Print();
  }
}


void LiveRange::AddUseInterval(intptr_t start, intptr_t end) {
  if ((head_ != NULL) && (head_->start_ == end)) {
    head_->start_ = start;
    return;
  }

  head_ = new UseInterval(vreg_, start, end, head_);
}


void LiveRange::DefineAt(Instruction* instr, intptr_t pos, Location* loc) {
  if (head_ != NULL) {
    ASSERT(head_->start_ <= pos);
    head_->start_ = pos;
  } else {
    // Definition without a use.
    head_ = new UseInterval(vreg_, pos, pos + 1, NULL);
  }
  head_->AddUse(instr, pos, loc);
}


// TODO(vegorov): encode use_at_start vs. use_at_end in the location itself?
void LiveRange::UseAt(Instruction* instr,
                      intptr_t def, intptr_t use,
                      bool use_at_end,
                      Location* loc) {
  if (head_ == NULL || head_->start_ != def) {
    AddUseInterval(def, use + (use_at_end ? 1 : 0));
  }
  head_->AddUse(instr, use, loc);
}


LiveRange* FlowGraphAllocator::GetLiveRange(intptr_t vreg) {
  if (live_ranges_[vreg] == NULL) {
    live_ranges_[vreg] = new LiveRange(vreg);
  }
  return live_ranges_[vreg];
}


void FlowGraphAllocator::BlockLocation(Location loc, intptr_t pos) {
  ASSERT(loc.IsRegister());
  const Register reg = loc.reg();
  UseInterval* last = cpu_regs_[reg];
  if (last == kPermanentlyBlocked) return;
  if ((last != NULL) && (last->start() == pos)) return;
  cpu_regs_[reg] = new UseInterval(kNoVirtualRegister, pos, pos + 1, last);
}


void FlowGraphAllocator::Define(Instruction* instr,
                                intptr_t pos,
                                intptr_t vreg,
                                Location* loc) {
  LiveRange* range = GetLiveRange(vreg);
  ASSERT(loc != NULL);
  if (loc->IsRegister()) {
    BlockLocation(*loc, pos);
    range->DefineAt(instr, pos + 1, loc);
  } else if (loc->IsUnallocated()) {
    range->DefineAt(instr, pos, loc);
  } else {
    UNREACHABLE();
  }

  AddToUnallocated(range->head());
}


void FlowGraphAllocator::UseValue(Instruction* instr,
                                  intptr_t def_pos,
                                  intptr_t use_pos,
                                  intptr_t vreg,
                                  Location* loc,
                                  bool use_at_end) {
  LiveRange* range = GetLiveRange(vreg);
  if (loc == NULL) {
    range->UseAt(NULL, def_pos, use_pos, true, loc);
  } else if (loc->IsRegister()) {
    // We have a fixed use.
    BlockLocation(*loc, use_pos);
    range->UseAt(instr, def_pos, use_pos, false, loc);
  } else if (loc->IsUnallocated()) {
    ASSERT(loc->policy() == Location::kRequiresRegister);
    range->UseAt(use_at_end ? NULL : instr, def_pos, use_pos, use_at_end, loc);
  }
}


static void PrintChain(UseInterval* chain) {
  if (chain == kPermanentlyBlocked) {
    OS::Print("  not for allocation\n");
    return;
  }

  while (chain != NULL) {
    chain->Print();
    chain = chain->next();
  }
}


void FlowGraphAllocator::PrintLiveRanges() {
  for (intptr_t i = 0; i < unallocated_.length(); i++) {
    OS::Print("unallocated chain for vr%d\n", unallocated_[i]->vreg());
    PrintChain(unallocated_[i]);
  }

  for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
    OS::Print("blocking chain for %s\n",
              Location::RegisterLocation(static_cast<Register>(reg)).Name());
    PrintChain(cpu_regs_[reg]);
  }
}


void FlowGraphAllocator::BuildLiveRanges() {
  NumberInstructions();

  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];

    // For every SSA value that is live out of this block create an interval
    // that covers the hole block.  It will be shortened if we encounter a
    // definition of this value in this block.
    for (BitVector::Iterator it(live_out_[i]); !it.Done(); it.Advance()) {
      LiveRange* range = GetLiveRange(it.Current());
      range->AddUseInterval(block->start_pos(), block->end_pos());
    }

    // Position corresponding to the beginning of the last instruction in the
    // block.
    intptr_t pos = block->end_pos() - 1;
    Instruction* current = block->last_instruction();

    // Goto instructions do not contribute liveness information.
    GotoInstr* goto_instr = current->AsGoto();
    if (goto_instr != NULL) {
      current = current->previous();
      // If we have a parallel move here then the successor block must be a
      // join with phis.  The phi inputs contribute uses to each predecessor
      // block (and the phi outputs contribute definitions in the successor
      // block).
      //
      // We record those uses at the end of the instruction preceding the
      // parallel move.  This position is 'pos', because we do not assign
      // instruction numbers to parallel moves.
      ParallelMoveInstr* parallel_move = current->AsParallelMove();
      if (parallel_move != NULL) {
        JoinEntryInstr* join = goto_instr->successor();
        ASSERT(join != NULL);

        // Search for the index of the current block in the predecessors of
        // the join.
        // TODO(kmillikin): record the predecessor index in the goto when
        // building the predecessor list to avoid this search.
        intptr_t pred_idx = 0;
        for (; pred_idx < join->PredecessorCount(); pred_idx++) {
          if (join->PredecessorAt(pred_idx) == block) break;
        }
        ASSERT(pred_idx < join->PredecessorCount());

        // Record the corresponding phi input use for each phi.
        ZoneGrowableArray<PhiInstr*>* phis = join->phis();
        for (intptr_t move_idx = 0; move_idx < phis->length(); move_idx++) {
          PhiInstr* phi = (*phis)[move_idx];
          if (phi == NULL) continue;

          Value* val = phi->InputAt(pred_idx);
          MoveOperands move = parallel_move->moves()[move_idx];
          if (val->IsUse()) {
            const intptr_t virtual_register =
                val->AsUse()->definition()->ssa_temp_index();
            Location* slot = move.src_slot();
            *slot = Location::RequiresRegister();
            GetLiveRange(virtual_register)->head()->AddUse(NULL, pos, slot);
          } else {
            ASSERT(val->IsConstant());
            move.set_src(Location::Constant(val->AsConstant()->value()));
          }
        }

        // Begin backward iteration with the instruction before the parallel
        // move.
        current = current->previous();
      }
    }

    // Now process all instructions in reverse order.
    --pos;  // 'pos' is now the start position for the current instruction.
    while (current != block) {
      LocationSummary* locs = current->locs();

      const bool output_same_as_first_input =
        locs->out().IsUnallocated() &&
        locs->out().policy() == Location::kSameAsFirstInput;

      // TODO(vegorov): number of inputs should match number of input locations.
      // TODO(vegorov): generic support for writable registers?
      for (intptr_t j = 0; j < current->InputCount(); j++) {
        Value* input = current->InputAt(j);
        if (input->IsUse()) {
          const intptr_t use = input->AsUse()->definition()->ssa_temp_index();

          Location* in_ref = (j < locs->input_count()) ?
            locs->in_slot(j) : NULL;
          const bool use_at_end = (j > 0) || (in_ref == NULL) ||
            !output_same_as_first_input;
          UseValue(current, block->start_pos(), pos, use, in_ref, use_at_end);
        }
      }

      // Add uses from the deoptimization environment.
      // TODO(vegorov): these uses should _not_ require register but for now
      // they do because we don't support spilling at all.
      if (current->env() != NULL) {
        const GrowableArray<Value*>& values = current->env()->values();
        GrowableArray<Location>* locations = current->env()->locations();

        for (intptr_t j = 0; j < values.length(); j++) {
          Value* val = values[j];
          if (val->IsUse()) {
            locations->Add(Location::RequiresRegister());
            const intptr_t use = val->AsUse()->definition()->ssa_temp_index();
            UseValue(current,
                     block->start_pos(),
                     pos,
                     use,
                     &(*locations)[j],
                     true);
          } else {
            locations->Add(Location::NoLocation());
          }
        }
      }

      // Process temps.
      for (intptr_t j = 0; j < locs->temp_count(); j++) {
        Location temp = locs->temp(j);
        if (temp.IsRegister()) {
          BlockLocation(temp, pos);
        } else if (temp.IsUnallocated()) {
          UseInterval* temp_interval = new UseInterval(
            kTempVirtualRegister, pos, pos + 1, NULL);
          temp_interval->AddUse(NULL, pos, locs->temp_slot(j));
          AddToUnallocated(temp_interval);
        } else {
          UNREACHABLE();
        }
      }

      // Block all allocatable registers for calls.
      if (locs->is_call()) {
        for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
          BlockLocation(Location::RegisterLocation(static_cast<Register>(reg)),
                        pos);
        }
      }

      if (locs->out().IsRegister()) {
        builder_->Bailout("ssa allocator: fixed outputs are not supported");
      }

      Definition* def = current->AsDefinition();
      if ((def != NULL) && (def->ssa_temp_index() >= 0)) {
        Define(output_same_as_first_input ? current : NULL,
               pos,
               def->ssa_temp_index(),
               locs->out_slot());
      }

      current = current->previous();
      pos -= 2;
    }

    // If this block is a join we need to add destinations of phi
    // resolution moves to phi's live range so that register allocator will
    // fill them with moves.
    if (block->IsJoinEntry() && block->AsJoinEntry()->phis() != NULL) {
      ZoneGrowableArray<PhiInstr*>* phis = block->AsJoinEntry()->phis();

      intptr_t move_idx = 0;
      for (intptr_t j = 0; j < phis->length(); j++) {
        PhiInstr* phi = (*phis)[j];
        if (phi == NULL) continue;

        const intptr_t def = phi->ssa_temp_index();
        ASSERT(def != -1);

        LiveRange* range = GetLiveRange(def);
        range->DefineAt(NULL, pos, NULL);
        UseInterval* interval = GetLiveRange(def)->head();

        for (intptr_t k = 0; k < phi->InputCount(); k++) {
          BlockEntryInstr* pred = block->PredecessorAt(k);
          ASSERT(pred->last_instruction()->IsParallelMove());

          Location* slot = pred->last_instruction()->AsParallelMove()->
            moves()[move_idx].dest_slot();
          *slot = Location::RequiresRegister();
          interval->AddUse(NULL, pos, slot);
        }

        // All phi resolution moves are connected. Phi's live range is complete.
        AddToUnallocated(interval);

        move_idx++;
      }
    }
  }
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
    block->set_start_pos(pos);
    block->set_lifetime_position(pos);
    pos += 2;
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      // Do not assign numbers to parallel moves or goto instructions.
      if (!current->IsParallelMove() && !current->IsGoto()) {
        current->set_lifetime_position(pos);
        pos += 2;
      }
    }
    block->set_end_pos(pos);

    // For join entry predecessors create phi resolution moves if
    // necessary. They will be populated by the register allocator.
    JoinEntryInstr* join = block->AsJoinEntry();
    if ((join != NULL) && (join->phi_count() > 0)) {
      const intptr_t phi_count = join->phi_count();
      for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
        ParallelMoveInstr* move = new ParallelMoveInstr();
        // Populate the ParallelMove with empty moves.
        for (intptr_t j = 0; j < phi_count; j++) {
          move->AddMove(Location::NoLocation(), Location::NoLocation());
        }

        // Insert the move between the last two instructions of the
        // predecessor block (all such blocks have at least two instructions:
        // the block entry and goto instructions.)
        BlockEntryInstr* pred = block->PredecessorAt(i);
        Instruction* next = pred->last_instruction();
        Instruction* previous = next->previous();
        ASSERT(next->IsGoto());
        ASSERT(!previous->IsParallelMove());
        previous->set_next(move);
        move->set_previous(previous);
        move->set_next(next);
        next->set_previous(move);
      }
    }
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
      a = a->next_allocated();
    } else {
      u = u->next();
    }
  }

  return kMaxPosition;
}


static Location LookAheadForHint(UseInterval* interval) {
  UsePosition* use = interval->first_use();

  while (use != NULL) {
    if (use->HasHint()) return use->hint();
    use = use->next();
  }

  return Location::NoLocation();
}


bool FlowGraphAllocator::AllocateFreeRegister(UseInterval* unallocated) {
  Register candidate = kNoRegister;
  intptr_t free_until = 0;

  // If hint is available try hint first.
  // TODO(vegorov): ensure that phis are hinted on the backedge.
  Location hint = LookAheadForHint(unallocated);
  if (!hint.IsInvalid()) {
    ASSERT(hint.IsRegister());

    if (cpu_regs_[hint.reg()] != kPermanentlyBlocked) {
      free_until = FirstIntersection(cpu_regs_[hint.reg()], unallocated);
      candidate = hint.reg();
    }

    TRACE_ALLOC(("found hint %s for %d: free until %d\n",
                 hint.Name(), unallocated->vreg(), free_until));
  }

  if (free_until != kMaxPosition) {
    for (int reg = 0; reg < kNumberOfCpuRegisters; ++reg) {
      if (cpu_regs_[reg] == NULL) {
        candidate = static_cast<Register>(reg);
        free_until = kMaxPosition;
        break;
      }
    }
  }

  ASSERT(0 <= kMaxPosition);
  if (free_until != kMaxPosition) {
    for (int reg = 0; reg < kNumberOfCpuRegisters; ++reg) {
      if (cpu_regs_[reg] == kPermanentlyBlocked) continue;
      if (reg == candidate) continue;

      const intptr_t pos = FirstIntersection(cpu_regs_[reg], unallocated);

      if (pos > free_until) {
        candidate = static_cast<Register>(reg);
        free_until = pos;
        if (free_until == kMaxPosition) break;
      }
    }
  }

  // All registers are blocked by active ranges.
  if (free_until <= unallocated->start()) return false;

  AssignFreeRegister(unallocated, candidate);
  return true;
}


UseInterval* UseInterval::Split(intptr_t pos) {
  if (pos == start()) return this;
  ASSERT(Contains(pos));
  UseInterval* tail = new UseInterval(vreg(), pos, end(), next());

  UsePosition* use = uses_;
  while (use != NULL && use->pos() <= pos) {
    use = use->next();
  }

  tail->uses_ = use;

  end_ = pos;

  return tail;
}


void FlowGraphAllocator::AssignFreeRegister(UseInterval* unallocated,
                                            Register reg) {
  TRACE_ALLOC(("assigning free register %s to %d\n",
               Location::RegisterLocation(reg).Name(),
               unallocated->vreg()));

  UseInterval* a = cpu_regs_[reg];
  if (a == NULL) {
    // Register is completely free.
    cpu_regs_[reg] = unallocated;
    return;
  }

  UseInterval* u = unallocated;
  ASSERT(u->start() < a->start());  // Register is free.
  cpu_regs_[reg] = u;
  if (u->next() == NULL || u->next()->start() >= a->start()) {
    u->set_next_allocated(a);
  }

  while (a != NULL && u != NULL) {
    const intptr_t pos = a->Intersect(u);
    if (pos != kIllegalPosition) {
      // TODO(vegorov): split live ranges might require control flow resolution
      // which is not implemented yet.
      builder_->Bailout("ssa allocator: control flow resolution required");

      TRACE_ALLOC(("  splitting at %d\n", pos));
      // Reached intersection
      UseInterval* tail = u->Split(pos);
      AddToUnallocated(tail);
      ASSERT(tail == u || u->next_allocated() == a);
      return;
    }

    if (a->start() < u->start()) {
      if (a->next_allocated() == NULL) {
        a->set_next_allocated(u);
        break;
      }

      UseInterval* next = a->next_allocated();
      if (next->start() > u->start()) {
        a->set_next_allocated(u);
        u->set_next_allocated(next);
      }

      a = next;
    } else {
      UseInterval* next = u->next();

      if (next == NULL || next->start() >= a->start()) {
        u->set_next_allocated(a);
      }
      u = next;
    }
  }
}


static void InsertMoveBefore(Instruction* instr, Location to, Location from) {
  Instruction* prev = instr->previous();
  ParallelMoveInstr* move = prev->AsParallelMove();
  if (move == NULL) {
    move = new ParallelMoveInstr();
    move->set_next(prev->next());
    prev->set_next(move);
    move->next()->set_previous(move);
    move->set_previous(prev);
  }
  move->AddMove(to, from);
}


void UsePosition::AssignLocation(Location loc) {
  if (location_slot_ == NULL) return;

  if (location_slot_->IsUnallocated()) {
    if (location_slot_->policy() == Location::kSameAsFirstInput) {
      Instruction* instr = this->instr();
      LocationSummary* locs = instr->locs();
      if (!locs->in(0).IsUnallocated()) {
        InsertMoveBefore(instr, loc, locs->in(0));
      }
      locs->set_in(0, loc);
    }
    TRACE_ALLOC(("  use at %d converted to %s\n", pos(), loc.Name()));
    *location_slot_ = loc;
  } else if (location_slot_->IsRegister()) {
    InsertMoveBefore(this->instr(), *location_slot_, loc);
  }
}


void FlowGraphAllocator::FinalizeInterval(UseInterval* interval, Location loc) {
  if (interval->vreg() == kNoVirtualRegister) return;

  TRACE_ALLOC(("assigning location %s to interval [%d, %d)\n", loc.Name(),
               interval->start(), interval->end()));

  for (UsePosition* use = interval->first_use();
       use != NULL && use->pos() <= interval->end();
       use = use->next()) {
    use->AssignLocation(loc);
  }
}


void FlowGraphAllocator::AdvanceActiveIntervals(const intptr_t start) {
  for (int reg = 0; reg < kNumberOfCpuRegisters; reg++) {
    if (cpu_regs_[reg] == NULL) continue;
    if (cpu_regs_[reg] == kPermanentlyBlocked) continue;

    UseInterval* a = cpu_regs_[reg];
    while (a != NULL && a->end() <= start) {
      FinalizeInterval(a,
                       Location::RegisterLocation(static_cast<Register>(reg)));
      a = a->next_allocated();
    }

    cpu_regs_[reg] = a;
  }
}


static inline bool ShouldBeAllocatedBefore(UseInterval* a, UseInterval* b) {
  return a->start() <= b->start();
}


void FlowGraphAllocator::AddToUnallocated(UseInterval* chain) {
  if (unallocated_.is_empty()) {
    unallocated_.Add(chain);
    return;
  }

  for (intptr_t i = unallocated_.length() - 1; i >= 0; i--) {
    if (ShouldBeAllocatedBefore(chain, unallocated_[i])) {
      unallocated_.InsertAt(i + 1, chain);
      return;
    }
  }
  unallocated_.InsertAt(0, chain);
}


bool FlowGraphAllocator::UnallocatedIsSorted() {
  for (intptr_t i = unallocated_.length() - 1; i >= 1; i--) {
    UseInterval* a = unallocated_[i];
    UseInterval* b = unallocated_[i - 1];
    if (!ShouldBeAllocatedBefore(a, b)) return false;
  }
  return true;
}


void FlowGraphAllocator::AllocateCPURegisters() {
  ASSERT(UnallocatedIsSorted());

  while (!unallocated_.is_empty()) {
    UseInterval* range = unallocated_.Last();
    unallocated_.RemoveLast();
    const intptr_t start = range->start();
    TRACE_ALLOC(("Processing interval chain for vreg %d starting at %d\n",
                 range->vreg(),
                 start));

    // TODO(vegorov): eagerly spill liveranges without register uses.
    AdvanceActiveIntervals(start);

    if (!AllocateFreeRegister(range)) {
      builder_->Bailout("ssa allocator: spilling required");
      return;
    }
  }

  // All allocation decisions were done.
  ASSERT(unallocated_.is_empty());

  // Finish allocation.
  AdvanceActiveIntervals(kMaxPosition);
  TRACE_ALLOC(("Allocation completed\n"));
}


void FlowGraphAllocator::AllocateRegisters() {
  GraphEntryInstr* entry = block_order_[0]->AsGraphEntry();
  ASSERT(entry != NULL);

  for (intptr_t i = 0; i < entry->start_env()->values().length(); i++) {
    if (entry->start_env()->values()[i]->IsUse()) {
      builder_->Bailout("ssa allocator: unsupported start environment");
    }
  }

  AnalyzeLiveness();

  BuildLiveRanges();

  if (FLAG_print_ssa_liveness) {
    DumpLiveness();
  }

  if (FLAG_trace_ssa_allocator) {
    PrintLiveRanges();
  }

  AllocateCPURegisters();

  if (FLAG_trace_ssa_allocator) {
    OS::Print("-- ir after allocation -------------------------\n");
    FlowGraphPrinter printer(Function::Handle(), block_order_, true);
    printer.PrintBlocks();
  }
}


}  // namespace dart
