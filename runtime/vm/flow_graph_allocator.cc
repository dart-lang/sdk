// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_allocator.h"

#include "vm/bit_vector.h"
#include "vm/intermediate_language.h"
#include "vm/flow_graph_compiler.h"

namespace dart {

DEFINE_FLAG(bool, print_ssa_liveness, false,
            "Print liveness for ssa variables.");

FlowGraphAllocator::FlowGraphAllocator(
  const GrowableArray<BlockEntryInstr*>& postorder,
  intptr_t max_ssa_temp_index)
  : live_out_(postorder.length()),
    kill_(postorder.length()),
    live_in_(postorder.length()),
    postorder_(postorder),
    vreg_count_(max_ssa_temp_index) {
}


void FlowGraphAllocator::ResolveConstraints() {
  // TODO(fschneider): Resolve register constraints.
}


static intptr_t ToVirtualRegister(Instruction* instr) {
  const Definition* def = instr->AsDefinition();
  return (def == NULL) ? -1 : def->ssa_temp_index();
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

          const intptr_t def = ToVirtualRegister(phi);
          if (def >= 0) kill->Add(def);

          for (intptr_t k = 0; k < phi->InputCount(); k++) {
            Value* val = phi->InputAt(k);
            if (!val->IsUse()) continue;
            const intptr_t use = ToVirtualRegister(val->AsUse()->definition());
            if (use >= 0) {
              BlockEntryInstr* pred = block->PredecessorAt(k);
              live_out_[pred->postorder_number()]->Add(use);
            }
          }
        }
      }
    }

    Instruction* current = block->StraightLineSuccessor();
    // TODO(vegorov): iterate backwards.
    while ((current != NULL) && !current->IsBlockEntry()) {
      for (intptr_t j = 0; j < current->InputCount(); j++) {
        Value* input = current->InputAt(j);
        if (!input->IsUse()) continue;
        const intptr_t use = ToVirtualRegister(input->AsUse()->definition());
        if ((use >= 0) && !kill->Contains(use)) live_in->Add(use);
      }

      const intptr_t def = ToVirtualRegister(current);
      if (def >= 0) kill->Add(def);

      current = current->StraightLineSuccessor();
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

  if (FLAG_print_ssa_liveness) {
    DumpLiveness();
  }
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


}  // namespace dart
