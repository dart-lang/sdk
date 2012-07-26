// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_allocator.h"

#include "vm/bit_vector.h"
#include "vm/intermediate_language.h"
#include "vm/il_printer.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/parser.h"

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
static const intptr_t kIllegalPosition = -1;
static const intptr_t kMaxPosition = 0x7FFFFFFF;


static intptr_t MinPosition(intptr_t a, intptr_t b) {
  return (a < b) ? a : b;
}


static bool IsParallelMovePosition(intptr_t pos) {
  return (pos & 1) == 0;
}


static bool IsInstructionPosition(intptr_t pos) {
  return (pos & 1) == 1;
}


static intptr_t ToParallelMove(intptr_t pos) {
  return (pos & ~1);
}

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
    live_ranges_(builder->current_ssa_temp_index()),
    cpu_regs_(),
    blocked_cpu_regs_() {
  for (intptr_t i = 0; i < vreg_count_; i++) live_ranges_.Add(NULL);

  blocked_cpu_regs_[CTX] = true;
  if (TMP != kNoRegister) {
    blocked_cpu_regs_[TMP] = true;
  }
  blocked_cpu_regs_[SPREG] = true;
  blocked_cpu_regs_[FPREG] = true;
}


void FlowGraphAllocator::ComputeInitialSets() {
  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];

    BitVector* kill = kill_[i];
    BitVector* live_in = live_in_[i];

    // Iterate backwards starting at the last instruction.
    for (BackwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();

      // Handle definitions.
      Definition* current_def = current->AsDefinition();
      if ((current_def != NULL) && current_def->HasSSATemp()) {
        kill->Add(current_def->ssa_temp_index());
        live_in->Remove(current_def->ssa_temp_index());
      }

      // Handle uses.
      for (intptr_t j = 0; j < current->InputCount(); j++) {
        Value* input = current->InputAt(j);
        if (input->IsUse()) {
          const intptr_t use = input->AsUse()->definition()->ssa_temp_index();
          live_in->Add(use);
        }
      }

      // Add uses from the deoptimization environment.
      if (current->env() != NULL) {
        const GrowableArray<Value*>& values = current->env()->values();
        for (intptr_t j = 0; j < values.length(); j++) {
          Value* val = values[j];
          if (val->IsUse()) {
            const intptr_t use = val->AsUse()->definition()->ssa_temp_index();
            live_in->Add(use);
          }
        }
      }
    }

    // Handle phis.
    if (block->IsJoinEntry()) {
      JoinEntryInstr* join = block->AsJoinEntry();
      if (join->phis() != NULL) {
        for (intptr_t j = 0; j < join->phis()->length(); j++) {
          PhiInstr* phi = (*join->phis())[j];
          if (phi == NULL) continue;
          kill->Add(phi->ssa_temp_index());
          live_in->Remove(phi->ssa_temp_index());

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
  }

  // Process incoming parameters.
  GraphEntryInstr* graph_entry = postorder_[block_count - 1]->AsGraphEntry();
  for (intptr_t i = 0; i < graph_entry->start_env()->values().length(); i++) {
    Value* val = graph_entry->start_env()->values()[i];
    if (val->IsUse()) {
      const intptr_t vreg = val->AsUse()->definition()->ssa_temp_index();
      kill_[0]->Add(vreg);
      live_in_[0]->Remove(vreg);
    }
  }

  // Update initial live_in sets to match live_out sets. Has to be
  // done in a separate path because of backwards branches.
  for (intptr_t i = 0; i < block_count; i++) {
    UpdateLiveIn(*postorder_[i]);
  }
}


bool FlowGraphAllocator::UpdateLiveOut(const BlockEntryInstr& instr) {
  BitVector* live_out = live_out_[instr.postorder_number()];
  bool changed = false;
  Instruction* last = instr.last_instruction();
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


bool FlowGraphAllocator::UpdateLiveIn(const BlockEntryInstr& instr) {
  BitVector* live_out = live_out_[instr.postorder_number()];
  BitVector* kill = kill_[instr.postorder_number()];
  BitVector* live_in = live_in_[instr.postorder_number()];
  return live_in->KillAndAdd(kill, live_out);
}


void FlowGraphAllocator::ComputeLiveInAndLiveOutSets() {
  const intptr_t block_count = postorder_.length();
  bool changed;
  do {
    changed = false;

    for (intptr_t i = 0; i < block_count; i++) {
      const BlockEntryInstr& block = *postorder_[i];

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


void LiveRange::AddUse(intptr_t pos, Location* location_slot) {
  ASSERT((first_use_interval_->start_ <= pos) &&
         (pos <= first_use_interval_->end_));
  if ((uses_ != NULL) && (uses_->pos() == pos)) {
    if ((location_slot == NULL) || (uses_->location_slot() == location_slot)) {
      return;
    } else if (uses_->location_slot() == NULL) {
      uses_->set_location_slot(location_slot);
      return;
    }
  }
  uses_ = new UsePosition(pos, uses_, location_slot);
}


void LiveRange::AddUseInterval(intptr_t start, intptr_t end) {
  ASSERT(start < end);

  // Live ranges are being build by visiting instructions in post-order.
  // This implies that use intervals will be perpended in a monotonically
  // decreasing order.
  if (first_use_interval() != NULL) {
    // If the first use interval and the use interval we are adding
    // touch then we can just extend the first interval to cover their
    // union.
    if (start >= first_use_interval()->start()) {
      // The only case when we can add intervals with start greater than
      // start of an already created interval is BlockLocation.
      ASSERT((start == first_use_interval()->start()) ||
             (vreg() == kNoVirtualRegister));
      ASSERT(end <= first_use_interval()->end());
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
    live_ranges_[vreg] = new LiveRange(vreg);
  }
  return live_ranges_[vreg];
}


void FlowGraphAllocator::BlockLocation(Location loc,
                                       intptr_t from,
                                       intptr_t to) {
  ASSERT(loc.IsRegister());
  const Register reg = loc.reg();
  if (blocked_cpu_regs_[reg]) return;
  if (cpu_regs_[reg].length() == 0) {
    cpu_regs_[reg].Add(new LiveRange(kNoVirtualRegister));
  }
  cpu_regs_[reg][0]->AddUseInterval(from, to);
}


void LiveRange::Print() {
  OS::Print("  live range v%d [%d, %d)\n", vreg(), Start(), End());
  UsePosition* use_pos = uses_;
  for (UseInterval* interval = first_use_interval_;
       interval != NULL;
       interval = interval->next()) {
    OS::Print("    use interval [%d, %d)\n",
              interval->start(),
              interval->end());
    while ((use_pos != NULL) && (use_pos->pos() <= interval->end())) {
      OS::Print("      use at %d as %s\n",
                use_pos->pos(),
                (use_pos->location_slot() == NULL)
                ? "-" : use_pos->location_slot()->Name());
      use_pos = use_pos->next();
    }
  }

  if (next_sibling() != NULL) {
    next_sibling()->Print();
  }
}


void FlowGraphAllocator::PrintLiveRanges() {
  for (intptr_t i = 0; i < unallocated_.length(); i++) {
    unallocated_[i]->Print();
  }

  for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
    if (blocked_cpu_regs_[reg]) continue;
    if (cpu_regs_[reg].length() == 0) continue;

    ASSERT(cpu_regs_[reg].length() == 1);
    OS::Print("blocking live range for %s\n",
              Location::RegisterLocation(static_cast<Register>(reg)).Name());
    cpu_regs_[reg][0]->Print();
  }
}


void FlowGraphAllocator::BuildLiveRanges() {
  NumberInstructions();

  const intptr_t block_count = postorder_.length();
  ASSERT(postorder_[block_count - 1]->IsGraphEntry());
  for (intptr_t i = 0; i < (block_count - 1); i++) {
    BlockEntryInstr* block = postorder_[i];

    // For every SSA value that is live out of this block, create an interval
    // that covers the whole block.  It will be shortened if we encounter a
    // definition of this value in this block.
    for (BitVector::Iterator it(live_out_[i]); !it.Done(); it.Advance()) {
      LiveRange* range = GetLiveRange(it.Current());
      range->AddUseInterval(block->start_pos(), block->end_pos());
    }

    // Connect outgoing phi-moves that were created in NumberInstructions
    // and find last instruction that contributes to liveness.
    Instruction* current = ConnectOutgoingPhiMoves(block);

    // Now process all instructions in reverse order.
    while (current != block) {
      // Skip parallel moves that we insert while processing instructions.
      if (!current->IsParallelMove()) {
        ProcessOneInstruction(block, current);
      }
      current = current->previous();
    }

    ConnectIncomingPhiMoves(block);
  }

  // Process incoming parameters.
  const intptr_t fixed_parameters_count =
      builder_->parsed_function().function().num_fixed_parameters();

  GraphEntryInstr* graph_entry = postorder_[block_count - 1]->AsGraphEntry();
  for (intptr_t i = 0; i < graph_entry->start_env()->values().length(); i++) {
    Value* val = graph_entry->start_env()->values()[i];
    if (val->IsUse()) {
      ParameterInstr* param = val->AsUse()->definition()->AsParameter();

      LiveRange* range = GetLiveRange(param->ssa_temp_index());
      range->AddUseInterval(graph_entry->start_pos(), graph_entry->end_pos());
      range->DefineAt(graph_entry->start_pos());

      // Slot index for the rightmost parameter is -1.
      const intptr_t slot_index = param->index() - fixed_parameters_count;
      range->set_assigned_location(Location::StackSlot(slot_index));

      range->finger()->Initialize(range);
      UsePosition* use = range->finger()->FirstRegisterBeneficialUse(
          graph_entry->start_pos());
      if (use != NULL) {
        LiveRange* tail = SplitBetween(range,
                                       graph_entry->start_pos(),
                                       use->pos());
        AddToUnallocated(tail);
      }
      ConvertAllUses(range);
    }
  }
}

//
// When describing shape of live ranges in comments below we are going to use
// the following notation:
//
//    B  block entry
//    g  goto instruction
//    m  parallel move
//    i  any other instruction
//
//    -  body of a use interval
//    [  start of a use interval
//    )  end of a use interval
//    *  use
//
// For example diagram
//
//           m i
//  value  --*-)
//
// can be read as: use interval for value starts somewhere before parallel move
// and extends until currently processed instruction, there is a use of value
// at a position of the parallel move.
//

Instruction* FlowGraphAllocator::ConnectOutgoingPhiMoves(
    BlockEntryInstr* block) {
  Instruction* last = block->last_instruction();

  GotoInstr* goto_instr = last->AsGoto();
  if (goto_instr == NULL) return last;

  // If we have a parallel move here then the successor block must be a
  // join with phis.  The phi inputs contribute uses to each predecessor
  // block (and the phi outputs contribute definitions in the successor
  // block).
  ParallelMoveInstr* parallel_move = goto_instr->previous()->AsParallelMove();
  if (parallel_move == NULL) return goto_instr->previous();

  // All uses are recorded at the position of parallel move preceding goto.
  const intptr_t pos = goto_instr->lifetime_position() - 1;
  ASSERT((pos >= 0) && IsParallelMovePosition(pos));

  JoinEntryInstr* join = goto_instr->successor();
  ASSERT(join != NULL);

  // Search for the index of the current block in the predecessors of
  // the join.
  const intptr_t pred_idx = join->IndexOfPredecessor(block);

  // Record the corresponding phi input use for each phi.
  ZoneGrowableArray<PhiInstr*>* phis = join->phis();
  intptr_t move_idx = 0;
  for (intptr_t phi_idx = 0; phi_idx < phis->length(); phi_idx++) {
    PhiInstr* phi = (*phis)[phi_idx];
    if (phi == NULL) continue;

    Value* val = phi->InputAt(pred_idx);
    MoveOperands* move = parallel_move->MoveOperandsAt(move_idx);
    if (val->IsUse()) {
      // Expected shape of live ranges:
      //
      //                 m  g
      //      value    --*
      //

      LiveRange* range = GetLiveRange(
          val->AsUse()->definition()->ssa_temp_index());

      range->AddUseInterval(block->start_pos(), pos);
      range->AddUse(pos, move->src_slot());

      move->set_src(Location::PrefersRegister());
    } else {
      ASSERT(val->IsConstant());
      move->set_src(Location::Constant(val->AsConstant()->value()));
    }
    move_idx++;
  }

  // Begin backward iteration with the instruction before the parallel
  // move.
  return parallel_move->previous();
}


void FlowGraphAllocator::ConnectIncomingPhiMoves(BlockEntryInstr* block) {
  // If this block is a join we need to add destinations of phi
  // resolution moves to phi's live range so that register allocator will
  // fill them with moves.
  JoinEntryInstr* join = block->AsJoinEntry();
  if (join == NULL) return;

  // All uses are recorded at the start position in the block.
  const intptr_t pos = join->start_pos();

  ZoneGrowableArray<PhiInstr*>* phis = join->phis();
  if (phis != NULL) {
    intptr_t move_idx = 0;
    for (intptr_t phi_idx = 0; phi_idx < phis->length(); phi_idx++) {
      PhiInstr* phi = (*phis)[phi_idx];
      if (phi == NULL) continue;

      const intptr_t vreg = phi->ssa_temp_index();
      ASSERT(vreg != -1);

      // Expected shape of live range:
      //
      //                 B
      //      phi        [--------
      //
      LiveRange* range = GetLiveRange(vreg);
      range->DefineAt(pos);  // Shorten live range.

      for (intptr_t pred_idx = 0; pred_idx < phi->InputCount(); pred_idx++) {
        BlockEntryInstr* pred = block->PredecessorAt(pred_idx);
        ASSERT(pred->last_instruction()->IsGoto());
        Instruction* move_instr = pred->last_instruction()->previous();
        ASSERT(move_instr->IsParallelMove());

        MoveOperands* move =
            move_instr->AsParallelMove()->MoveOperandsAt(move_idx);
        move->set_dest(Location::PrefersRegister());
        range->AddUse(pos, move->dest_slot());
      }

      // All phi resolution moves are connected. Phi's live range is
      // complete.
      AddToUnallocated(range);

      move_idx++;
    }
  }
}


// Create and update live ranges corresponding to instruction's inputs,
// temporaries and output.
void FlowGraphAllocator::ProcessOneInstruction(BlockEntryInstr* block,
                                               Instruction* current) {
  const intptr_t pos = current->lifetime_position();
  ASSERT(IsInstructionPosition(pos));

  LocationSummary* locs = current->locs();

  // TODO(vegorov): number of inputs must match number of input locations.
  if (locs->input_count() != current->InputCount()) {
    builder_->Bailout("ssa allocator: number of input locations mismatch");
  }

  // Normalize same-as-first-input output if input is specified as
  // fixed register.
  if (locs->out().IsUnallocated() &&
      (locs->out().policy() == Location::kSameAsFirstInput) &&
      (locs->in(0).IsRegister())) {
    locs->set_out(locs->in(0));
  }

  const bool output_same_as_first_input =
      locs->out().IsUnallocated() &&
      (locs->out().policy() == Location::kSameAsFirstInput);

  // Add uses from the deoptimization environment.
  if (current->env() != NULL) {
    // Any value mentioned in the deoptimization environment should survive
    // until the end of instruction but it does not need to be in the register.
    // Expected shape of live range:
    //
    //                 m  i  m
    //      value    -----*--)
    //

    Environment* env = current->env();
    const GrowableArray<Value*>& values = env->values();

    for (intptr_t j = 0; j < values.length(); j++) {
      Value* val = values[j];
      if (val->IsUse()) {
        env->AddLocation(Location::Any());
        const intptr_t vreg = val->AsUse()->definition()->ssa_temp_index();

        LiveRange* range = GetLiveRange(vreg);
        range->AddUseInterval(block->start_pos(), pos + 1);
        range->AddUse(pos, env->LocationSlotAt(j));
      } else {
        ASSERT(val->IsConstant());
        env->AddLocation(Location::NoLocation());
      }
    }
  }

  // Process inputs.
  // Skip the first input if output is specified with kSameAsFirstInput policy,
  // they will be processed together at the very end.
  for (intptr_t j = output_same_as_first_input ? 1 : 0;
       j < current->InputCount();
       j++) {
    Value* input = current->InputAt(j);
    ASSERT(input->IsUse());  // Can not be a constant currently.
    const intptr_t vreg = input->AsUse()->definition()->ssa_temp_index();
    LiveRange* range = GetLiveRange(vreg);

    Location* in_ref = locs->in_slot(j);

    if (in_ref->IsRegister()) {
      // Input is expected in a fixed register. Expected shape of
      // live ranges:
      //
      //                 m  i  m
      //      value    --*
      //      register   [-----)
      //
      MoveOperands* move =
          AddMoveAt(pos - 1, *in_ref, Location::PrefersRegister());
      BlockLocation(*in_ref, pos - 1, pos + 1);
      range->AddUseInterval(block->start_pos(), pos - 1);
      range->AddUse(pos - 1, move->src_slot());
    } else {
      // Normal unallocated input. Expected shape of
      // live ranges:
      //
      //                 m  i  m
      //      value    -----*--)
      //
      ASSERT(in_ref->IsUnallocated());
      range->AddUseInterval(block->start_pos(), pos + 1);
      range->AddUse(pos, in_ref);
    }
  }

  // Process temps.
  for (intptr_t j = 0; j < locs->temp_count(); j++) {
    // Expected shape of live range:
    //
    //           m  i  m
    //              [--)
    //

    Location temp = locs->temp(j);
    if (temp.IsRegister()) {
      BlockLocation(temp, pos, pos + 1);
    } else if (temp.IsUnallocated()) {
      LiveRange* range = new LiveRange(kTempVirtualRegister);
      range->AddUseInterval(pos, pos + 1);
      range->AddUse(pos, locs->temp_slot(j));
      AddToUnallocated(range);
    } else {
      UNREACHABLE();
    }
  }

  // Block all allocatable registers for calls.
  if (locs->is_call()) {
    // Expected shape of live range:
    //
    //           m  i  m
    //              [--)
    //

    for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
      BlockLocation(Location::RegisterLocation(static_cast<Register>(reg)),
                    pos,
                    pos + 1);
    }

#ifdef DEBUG
    // Verify that temps, inputs and output were specified as fixed
    // locations.  Every register is blocked now so attempt to
    // allocate will not succeed.
    for (intptr_t j = 0; j < locs->temp_count(); j++) {
      ASSERT(!locs->temp(j).IsUnallocated());
    }

    for (intptr_t j = 0; j < locs->input_count(); j++) {
      ASSERT(!locs->in(j).IsUnallocated());
    }

    ASSERT(!locs->out().IsUnallocated());
#endif
  }

  Definition* def = current->AsDefinition();
  if (def == NULL) {
    ASSERT(locs->out().IsInvalid());
    return;
  }

  if (locs->out().IsInvalid()) {
    ASSERT(def->ssa_temp_index() < 0);
    return;
  }

  // We might have a definition without use.  We do not assign SSA index to
  // such definitions.
  LiveRange* range = (def->ssa_temp_index() >= 0) ?
      GetLiveRange(def->ssa_temp_index()) :
      new LiveRange(kTempVirtualRegister);
  Location* out = locs->out_slot();

  // Process output and finalize its liverange.
  if (out->IsRegister()) {
    // Fixed output location. Expected shape of live range:
    //
    //                 m  i  m
    //    register        [--)
    //    output             [-------
    //
    BlockLocation(*out, pos, pos + 1);

    if (range->vreg() == kTempVirtualRegister) return;

    // We need to emit move connecting fixed register with another location
    // that will be allocated for this output's live range.
    // Special case: fixed output followed by a fixed input last use.
    UsePosition* use = range->first_use();
    if (use->pos() == (pos + 1)) {
      // We have a use position on the parallel move.
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

    MoveOperands* move = AddMoveAt(pos + 1, Location::PrefersRegister(), *out);
    range->AddUse(pos + 1, move->dest_slot());
  } else if (output_same_as_first_input) {
    // Output register will contain a value of the first input at instruction's
    // start. Expected shape of live ranges:
    //
    //                 m  i  m
    //    input #0   --*
    //    output       [--*----
    //
    ASSERT(locs->in_slot(0)->Equals(Location::RequiresRegister()));

    // Create move that will copy value between input and output.
    locs->set_out(Location::RequiresRegister());
    MoveOperands* move = AddMoveAt(pos - 1,
                                   Location::RequiresRegister(),
                                   Location::PrefersRegister());

    // Add uses to the live range of the input.
    Value* input = current->InputAt(0);
    ASSERT(input->IsUse());  // Can not be a constant currently.
    LiveRange* input_range = GetLiveRange(
      input->AsUse()->definition()->ssa_temp_index());
    input_range->AddUseInterval(block->start_pos(), pos - 1);
    input_range->AddUse(pos - 1, move->src_slot());

    // Shorten output live range to the point of definition and add both input
    // and output uses slots to be filled by allocator.
    range->DefineAt(pos - 1);
    range->AddUse(pos - 1, out);
    range->AddUse(pos - 1, move->dest_slot());
    range->AddUse(pos, locs->in_slot(0));
  } else {
    // Normal unallocated location that requires a register. Expected shape of
    // live range:
    //
    //                 m  i  m
    //    output          [-------
    //
    ASSERT(out->IsUnallocated() &&
           (out->policy() == Location::kRequiresRegister));

    // Shorten live range to the point of definition and add use to be filled by
    // allocator.
    range->DefineAt(pos);
    range->AddUse(pos, out);
  }

  AddToUnallocated(range);
}


static ParallelMoveInstr* CreateParallelMoveBefore(Instruction* instr,
                                                   intptr_t pos) {
  ASSERT(pos > 0);
  Instruction* prev = instr->previous();
  ParallelMoveInstr* move = prev->AsParallelMove();
  if ((move == NULL) || (move->lifetime_position() != pos)) {
    move = new ParallelMoveInstr();
    move->set_next(prev->next());
    prev->set_next(move);
    move->next()->set_previous(move);
    move->set_previous(prev);
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

    instructions_.Add(block);
    block->set_start_pos(pos);
    block->set_lifetime_position(pos + 1);
    pos += 2;

    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      // Do not assign numbers to parallel move instructions.
      if (!current->IsParallelMove()) {
        instructions_.Add(current);
        current->set_lifetime_position(pos + 1);
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
    if ((join != NULL) && (join->phi_count() > 0)) {
      const intptr_t phi_count = join->phi_count();
      for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
        // Insert the move between the last two instructions of the
        // predecessor block (all such blocks have at least two instructions:
        // the block entry and goto instructions.)
        Instruction* last = block->PredecessorAt(i)->last_instruction();
        ParallelMoveInstr* move =
          CreateParallelMoveBefore(last, last->lifetime_position() - 1);

        // Populate the ParallelMove with empty moves.
        for (intptr_t j = 0; j < phi_count; j++) {
          move->AddMove(Location::NoLocation(), Location::NoLocation());
        }
      }
    }
  }
}


Instruction* FlowGraphAllocator::InstructionAt(intptr_t pos) const {
  return instructions_[pos / 2];
}


bool FlowGraphAllocator::IsBlockEntry(intptr_t pos) const {
  return InstructionAt(pos)->IsBlockEntry();
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
    if ((loc != NULL) &&
        loc->IsUnallocated() &&
        (loc->policy() == Location::kRequiresRegister)) {
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
    if ((loc != NULL) &&
        (loc->IsRegister() ||
         (loc->IsUnallocated() && loc->IsRegisterBeneficial()))) {
      first_register_beneficial_use_ = use;
      return use;
    }
  }
  return NULL;
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


LiveRange* LiveRange::SplitAt(intptr_t split_pos) {
  if (Start() == split_pos) return this;

  // Ranges can only be connected by parallel moves.
  split_pos = ToParallelMove(split_pos);

  UseInterval* interval = finger_.first_pending_use_interval();
  ASSERT(interval->start() < split_pos);

  // Corner case. We need to start over to find previous interval.
  if (interval->start() == split_pos) interval = first_use_interval_;

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

  ASSERT(last_before_split->next() == first_after_split);
  ASSERT(last_before_split->end() <= split_pos);
  ASSERT(split_pos <= first_after_split->start());

  UsePosition* last_use_before_split = NULL;
  UsePosition* use = uses_;
  if (split_at_start) {
    while ((use != NULL) && (use->pos() < split_pos)) {
      last_use_before_split = use;
      use = use->next();
    }
  } else {
    while ((use != NULL) && (use->pos() <= split_pos)) {
      last_use_before_split = use;
      use = use->next();
    }
  }
  UsePosition* first_use_after_split = use;

  if (last_use_before_split == NULL) {
    uses_ = NULL;
  } else {
    last_use_before_split->set_next(NULL);
  }

  UseInterval* last_use_interval = (last_before_split == last_use_interval_) ?
    first_after_split : last_use_interval_;
  next_sibling_ = new LiveRange(vreg(),
                                first_use_after_split,
                                first_after_split,
                                last_use_interval,
                                next_sibling_);

  TRACE_ALLOC(("  split sibling [%d, %d)\n",
               next_sibling_->Start(), next_sibling_->End()));

  // Split sibling can only start at a parallel move.
  ASSERT(IsParallelMovePosition(next_sibling_->Start()));

  last_use_interval_ = last_before_split;
  last_use_interval_->next_ = NULL;
  return next_sibling_;
}


LiveRange* FlowGraphAllocator::SplitBetween(LiveRange* range,
                                            intptr_t from,
                                            intptr_t to) {
  // TODO(vegorov): select optimal split position based on loop structure.
  TRACE_ALLOC(("split %d [%d, %d) between [%d, %d)\n",
               range->vreg(), range->Start(), range->End(), from, to));
  return range->SplitAt(to);
}


void FlowGraphAllocator::SpillBetween(LiveRange* range,
                                      intptr_t from,
                                      intptr_t to) {
  ASSERT(from < to);
  TRACE_ALLOC(("spill %d [%d, %d) between [%d, %d)\n",
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
  TRACE_ALLOC(("spill %d [%d, %d) after %d\n",
               range->vreg(), range->Start(), range->End(), from));
  LiveRange* tail = range->SplitAt(from);
  Spill(tail);
}


intptr_t FlowGraphAllocator::AllocateSpillSlotFor(LiveRange* range) {
  for (intptr_t i = 0; i < spill_slots_.length(); i++) {
    if (spill_slots_[i] <= range->Start()) {
      return i;
    }
  }
  spill_slots_.Add(0);
  return spill_slots_.length() - 1;
}


void FlowGraphAllocator::Spill(LiveRange* range) {
  const intptr_t spill_index = AllocateSpillSlotFor(range);
  ASSERT(spill_slots_[spill_index] <= range->Start());
  spill_slots_[spill_index] = range->End();
  range->set_assigned_location(Location::StackSlot(spill_index));
  ConvertAllUses(range);
}


intptr_t FlowGraphAllocator::FirstIntersectionWithAllocated(
  Register reg, LiveRange* unallocated) {
  intptr_t intersection = kMaxPosition;
  for (intptr_t i = 0; i < cpu_regs_[reg].length(); i++) {
    LiveRange* allocated = cpu_regs_[reg][i];
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



bool FlowGraphAllocator::AllocateFreeRegister(LiveRange* unallocated) {
  Register candidate = kNoRegister;
  intptr_t free_until = 0;

  // If hint is available try hint first.
  // TODO(vegorov): ensure that phis are hinted on the back edge.
  Location hint = unallocated->finger()->FirstHint();
  if (!hint.IsInvalid()) {
    ASSERT(hint.IsRegister());

    if (!blocked_cpu_regs_[hint.reg()]) {
      free_until = FirstIntersectionWithAllocated(hint.reg(), unallocated);
      candidate = hint.reg();
    }

    TRACE_ALLOC(("found hint %s for %d: free until %d\n",
                 hint.Name(), unallocated->vreg(), free_until));
  }

  if (free_until != kMaxPosition) {
    for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; ++reg) {
      if (!blocked_cpu_regs_[reg] && cpu_regs_[reg].length() == 0) {
        candidate = static_cast<Register>(reg);
        free_until = kMaxPosition;
        break;
      }
    }
  }

  ASSERT(0 <= kMaxPosition);
  if (free_until != kMaxPosition) {
    for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; ++reg) {
      if (blocked_cpu_regs_[reg] || (reg == candidate)) continue;

      const intptr_t intersection =
        FirstIntersectionWithAllocated(static_cast<Register>(reg), unallocated);

      if (intersection > free_until) {
        candidate = static_cast<Register>(reg);
        free_until = intersection;
        if (free_until == kMaxPosition) break;
      }
    }
  }

  if (free_until != kMaxPosition) free_until = ToParallelMove(free_until);

  // All registers are blocked by active ranges.
  if (free_until <= unallocated->Start()) return false;

  TRACE_ALLOC(("assigning free register %s to %d\n",
               Location::RegisterLocation(candidate).Name(),
               unallocated->vreg()));

  if (free_until != kMaxPosition) {
    // There was an intersection. Split unallocated.
    TRACE_ALLOC(("  splitting at %d\n", free_until));
    LiveRange* tail = unallocated->SplitAt(free_until);
    AddToUnallocated(tail);
  }

  cpu_regs_[candidate].Add(unallocated);
  unallocated->set_assigned_location(Location::RegisterLocation(candidate));

  return true;
}


void FlowGraphAllocator::AllocateAnyRegister(LiveRange* unallocated) {
  UsePosition* register_use =
      unallocated->finger()->FirstRegisterUse(unallocated->Start());
  if (register_use == NULL) {
    Spill(unallocated);
    return;
  }

  Register candidate = kNoRegister;
  intptr_t free_until = 0;
  intptr_t blocked_at = kMaxPosition;

  for (int reg = 0; reg < kNumberOfCpuRegisters; ++reg) {
    if (blocked_cpu_regs_[reg]) continue;
    if (UpdateFreeUntil(static_cast<Register>(reg),
                        unallocated,
                        &free_until,
                        &blocked_at)) {
      candidate = static_cast<Register>(reg);
    }
  }

  if (free_until < register_use->pos()) {
    // Can't acquire free register. Spill until we really need one.
    ASSERT(unallocated->Start() < ToParallelMove(register_use->pos()));
    SpillBetween(unallocated, unallocated->Start(), register_use->pos());
    return;
  }

  if (blocked_at < unallocated->End()) {
    LiveRange* tail = SplitBetween(unallocated,
                                   unallocated->Start(),
                                   blocked_at);
    AddToUnallocated(tail);
  }

  AssignNonFreeRegister(unallocated, candidate);
}


bool FlowGraphAllocator::UpdateFreeUntil(Register reg,
                                         LiveRange* unallocated,
                                         intptr_t* cur_free_until,
                                         intptr_t* cur_blocked_at) {
  intptr_t free_until = kMaxPosition;
  intptr_t blocked_at = kMaxPosition;
  const intptr_t start = unallocated->Start();

  for (intptr_t i = 0; i < cpu_regs_[reg].length(); i++) {
    LiveRange* allocated = cpu_regs_[reg][i];

    UseInterval* first_pending_use_interval =
        allocated->finger()->first_pending_use_interval();
    if (first_pending_use_interval->Contains(start)) {
      // This is an active interval.
      if (allocated->vreg() <= 0) {
        // This register blocked by an interval that
        // can't be spilled.
        return false;
      }

      const UsePosition* use =
        allocated->finger()->FirstRegisterBeneficialUse(unallocated->Start());

      if ((use != NULL) && ((use->pos() - start) <= 1)) {
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


void FlowGraphAllocator::RemoveEvicted(Register reg, intptr_t first_evicted) {
  intptr_t to = first_evicted;
  intptr_t from = first_evicted + 1;
  while (from < cpu_regs_[reg].length()) {
    LiveRange* allocated = cpu_regs_[reg][from++];
    if (allocated != NULL) cpu_regs_[reg][to++] = allocated;
  }
  cpu_regs_[reg].TruncateTo(to);
}


void FlowGraphAllocator::AssignNonFreeRegister(LiveRange* unallocated,
                                               Register reg) {
  TRACE_ALLOC(("assigning blocked register %s to live range %d\n",
               Location::RegisterLocation(reg).Name(),
               unallocated->vreg()));

  intptr_t first_evicted = -1;
  for (intptr_t i = cpu_regs_[reg].length() - 1; i >= 0; i--) {
    LiveRange* allocated = cpu_regs_[reg][i];
    if (allocated->vreg() < 0) continue;  // Can't be evicted.
    if (EvictIntersection(allocated, unallocated)) {
      ASSERT(allocated->End() <= unallocated->Start());
      ConvertAllUses(allocated);
      cpu_regs_[reg][i] = NULL;
      first_evicted = i;
    }
  }

  // Remove evicted ranges from the array.
  if (first_evicted != -1) RemoveEvicted(reg, first_evicted);

  cpu_regs_[reg].Add(unallocated);
  unallocated->set_assigned_location(Location::RegisterLocation(reg));
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
  UsePosition* use = allocated->finger()->FirstRegisterUse(spill_position);
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
  ASSERT(IsParallelMovePosition(pos));
  Instruction* instr = InstructionAt(pos);
  ASSERT(!instr->IsBlockEntry());
  return CreateParallelMoveBefore(instr, pos)->AddMove(to, from);
}


void FlowGraphAllocator::ConvertUseTo(UsePosition* use, Location loc) {
  ASSERT(use->location_slot() != NULL);
  Location* slot = use->location_slot();
  ASSERT(slot->IsUnallocated());
  ASSERT((slot->policy() == Location::kRequiresRegister) ||
         (slot->policy() == Location::kPrefersRegister) ||
         (slot->policy() == Location::kAny));
  TRACE_ALLOC(("  use at %d converted to %s\n", use->pos(), loc.Name()));
  *slot = loc;
}


void FlowGraphAllocator::ConvertAllUses(LiveRange* range) {
  if (range->vreg() == kNoVirtualRegister) return;
  TRACE_ALLOC(("range [%d, %d) for v%d has been allocated to %s:\n",
               range->Start(),
               range->End(),
               range->vreg(),
               range->assigned_location().Name()));
  ASSERT(!range->assigned_location().IsInvalid());
  const Location loc = range->assigned_location();
  for (UsePosition* use = range->first_use(); use != NULL; use = use->next()) {
    ConvertUseTo(use, loc);
  }
}


void FlowGraphAllocator::AdvanceActiveIntervals(const intptr_t start) {
  for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
    if (cpu_regs_[reg].is_empty()) continue;

    intptr_t first_evicted = -1;
    for (intptr_t i = cpu_regs_[reg].length() - 1; i >= 0; i--) {
      LiveRange* range = cpu_regs_[reg][i];
      if (range->finger()->Advance(start)) {
        ConvertAllUses(range);
        cpu_regs_[reg][i] = NULL;
        first_evicted = i;
      }
    }

    if (first_evicted != -1) {
      RemoveEvicted(static_cast<Register>(reg), first_evicted);
    }
  }
}


static inline bool ShouldBeAllocatedBefore(LiveRange* a, LiveRange* b) {
  return a->Start() <= b->Start();
}


void FlowGraphAllocator::AddToUnallocated(LiveRange* range) {
  range->finger()->Initialize(range);

  if (unallocated_.is_empty()) {
    unallocated_.Add(range);
    return;
  }

  for (intptr_t i = unallocated_.length() - 1; i >= 0; i--) {
    if (ShouldBeAllocatedBefore(range, unallocated_[i])) {
      unallocated_.InsertAt(i + 1, range);
      return;
    }
  }
  unallocated_.InsertAt(0, range);
}


#ifdef DEBUG
bool FlowGraphAllocator::UnallocatedIsSorted() {
  for (intptr_t i = unallocated_.length() - 1; i >= 1; i--) {
    LiveRange* a = unallocated_[i];
    LiveRange* b = unallocated_[i - 1];
    if (!ShouldBeAllocatedBefore(a, b)) return false;
  }
  return true;
}
#endif


void FlowGraphAllocator::AllocateCPURegisters() {
#ifdef DEBUG
  ASSERT(UnallocatedIsSorted());
#endif

  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    if (cpu_regs_[i].length() == 1) {
      LiveRange* range = cpu_regs_[i][0];
      range->finger()->Initialize(range);
    }
  }

  while (!unallocated_.is_empty()) {
    LiveRange* range = unallocated_.Last();
    unallocated_.RemoveLast();
    const intptr_t start = range->Start();
    TRACE_ALLOC(("Processing live range for vreg %d starting at %d\n",
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
  TRACE_ALLOC(("Allocation completed\n"));
}


void FlowGraphAllocator::ConnectSplitSiblings(LiveRange* range,
                                              BlockEntryInstr* source_block,
                                              BlockEntryInstr* target_block) {
  if (range->next_sibling() == NULL) {
    // Nothing to connect. The whole range was allocated to the same location.
    TRACE_ALLOC(("range %d has no siblings\n", range->vreg()));
    return;
  }

  const intptr_t source_pos = source_block->end_pos() - 1;
  ASSERT(IsInstructionPosition(source_pos));

  const intptr_t target_pos = target_block->start_pos();

  Location target;
  Location source;

#ifdef DEBUG
  LiveRange* source_cover = NULL;
  LiveRange* target_cover = NULL;
#endif

  while ((range != NULL) && (source.IsInvalid() || target.IsInvalid())) {
    if (range->CanCover(source_pos)) {
      ASSERT(source.IsInvalid());
      source = range->assigned_location();
#ifdef DEBUG
      source_cover = range;
#endif
    }
    if (range->CanCover(target_pos)) {
      ASSERT(target.IsInvalid());
      target = range->assigned_location();
#ifdef DEBUG
      target_cover = range;
#endif
    }

    range = range->next_sibling();
  }

  TRACE_ALLOC(("connecting [%d, %d) [%s] to [%d, %d) [%s]\n",
               source_cover->Start(), source_cover->End(), source.Name(),
               target_cover->Start(), target_cover->End(), target.Name()));

  // Siblings were allocated to the same register.
  if (source.Equals(target)) return;

  Instruction* last = source_block->last_instruction();
  if (last->SuccessorCount() == 1) {
    CreateParallelMoveBefore(last, last->lifetime_position() - 1)->
      AddMove(target, source);
  } else {
    CreateParallelMoveAfter(target_block, target_block->start_pos())->
      AddMove(target, source);
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
      if ((range->End() == sibling->Start()) &&
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
    BitVector* live = live_in_[block->postorder_number()];
    for (BitVector::Iterator it(live); !it.Done(); it.Advance()) {
      LiveRange* range = GetLiveRange(it.Current());
      for (intptr_t j = 0; j < block->PredecessorCount(); j++) {
        ConnectSplitSiblings(range, block->PredecessorAt(j), block);
      }
    }
  }
}


void FlowGraphAllocator::AllocateRegisters() {
  AnalyzeLiveness();

  BuildLiveRanges();

  if (FLAG_print_ssa_liveness) {
    DumpLiveness();
  }

  if (FLAG_trace_ssa_allocator) {
    PrintLiveRanges();
  }

  AllocateCPURegisters();

  ResolveControlFlow();

  GraphEntryInstr* entry = block_order_[0]->AsGraphEntry();
  ASSERT(entry != NULL);
  entry->set_spill_slot_count(spill_slots_.length());

  if (FLAG_trace_ssa_allocator) {
    OS::Print("-- ir after allocation -------------------------\n");
    FlowGraphPrinter printer(Function::Handle(), block_order_, true);
    printer.PrintBlocks();
  }
}


}  // namespace dart
