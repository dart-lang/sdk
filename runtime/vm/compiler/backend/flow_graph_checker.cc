// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)
#if defined(DEBUG)

#include "vm/compiler/backend/flow_graph_checker.h"

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/loops.h"

namespace dart {

// Returns true if block is a predecessor of succ.
static bool IsPred(BlockEntryInstr* block, BlockEntryInstr* succ) {
  for (intptr_t i = 0, n = succ->PredecessorCount(); i < n; ++i) {
    if (succ->PredecessorAt(i) == block) {
      return true;
    }
  }
  return false;
}

// Returns true if block is a successor of pred.
static bool IsSucc(BlockEntryInstr* block, BlockEntryInstr* pred) {
  Instruction* last = pred->last_instruction();
  for (intptr_t i = 0, n = last->SuccessorCount(); i < n; ++i) {
    if (last->SuccessorAt(i) == block) {
      return true;
    }
  }
  return false;
}

// Returns true if dom directly dominates block.
static bool IsDirectlyDominated(BlockEntryInstr* block, BlockEntryInstr* dom) {
  for (intptr_t i = 0, n = dom->dominated_blocks().length(); i < n; ++i) {
    if (dom->dominated_blocks()[i] == block) {
      return true;
    }
  }
  return false;
}

// Returns true if instruction appears on def's use list.
static bool IsInDefUseList(Definition* def, Instruction* instruction) {
  for (Value* use = def->input_use_list(); use != nullptr;
       use = use->next_use()) {
    if (use->instruction() == instruction) {
      return true;
    }
  }
  return false;
}

// Returns true if instruction forces control flow.
static bool IsControlFlow(Instruction* instruction) {
  return instruction->IsBranch() || instruction->IsGoto() ||
         instruction->IsIndirectGoto() || instruction->IsReturn() ||
         instruction->IsThrow() || instruction->IsReThrow() ||
         instruction->IsStop() || instruction->IsTailCall();
}

void FlowGraphChecker::VisitBlocks() {
  const GrowableArray<BlockEntryInstr*>& preorder = flow_graph_->preorder();
  const GrowableArray<BlockEntryInstr*>& postorder = flow_graph_->postorder();
  const GrowableArray<BlockEntryInstr*>& rev_postorder =
      flow_graph_->reverse_postorder();

  // Make sure lengths match.
  const intptr_t block_count = preorder.length();
  ASSERT(block_count == postorder.length());
  ASSERT(block_count == rev_postorder.length());

  // Make sure postorder has true reverse.
  for (intptr_t i = 0; i < block_count; ++i) {
    ASSERT(postorder[i] == rev_postorder[block_count - i - 1]);
  }

  // Iterate over all basic blocks.
  const intptr_t max_block_id = flow_graph_->max_block_id();
  for (BlockIterator it = flow_graph_->reverse_postorder_iterator(); !it.Done();
       it.Advance()) {
    BlockEntryInstr* block = it.Current();
    ASSERT(block->block_id() <= max_block_id);
    // Make sure ordering is consistent.
    ASSERT(block->preorder_number() <= block_count);
    ASSERT(block->postorder_number() <= block_count);
    ASSERT(preorder[block->preorder_number()] == block);
    ASSERT(postorder[block->postorder_number()] == block);
    // Make sure predecessors and successors agree.
    Instruction* last = block->last_instruction();
    for (intptr_t i = 0, n = last->SuccessorCount(); i < n; ++i) {
      ASSERT(IsPred(block, last->SuccessorAt(i)));
    }
    for (intptr_t i = 0, n = block->PredecessorCount(); i < n; ++i) {
      ASSERT(IsSucc(block, block->PredecessorAt(i)));
    }
    // Make sure dominance relations agree.
    for (intptr_t i = 0, n = block->dominated_blocks().length(); i < n; ++i) {
      ASSERT(block->dominated_blocks()[i]->dominator() == block);
    }
    if (block->dominator() != nullptr) {
      ASSERT(IsDirectlyDominated(block, block->dominator()));
    }
    // Visit all instructions in this block.
    VisitInstructions(block);
  }

  // Flow graph built-in verification.
  // TODO(ajcbik): migrate actual code into checker too?
  ASSERT(flow_graph_->VerifyUseLists());
}

void FlowGraphChecker::VisitInstructions(BlockEntryInstr* block) {
  // To avoid excessive runtimes, skip the instructions check if there
  // are many definitions (as happens in e.g. an initialization block).
  if (flow_graph_->current_ssa_temp_index() > 10000) {
    return;
  }
  // Give all visitors quick access.
  current_block_ = block;
  // Visit phis in join.
  if (auto join_entry = block->AsJoinEntry()) {
    for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
      PhiInstr* phi = it.Current();
      // Make sure block lookup agrees.
      ASSERT(phi->GetBlock() == join_entry);
      // Visit phi as instruction.
      VisitInstruction(phi);
    }
  }
  // Visit regular instructions.
  Instruction* last = block->last_instruction();
  ASSERT((last == block) == block->IsGraphEntry());
  Instruction* prev = block;
  ASSERT(prev->previous() == nullptr);
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* instruction = it.Current();
    // Make sure block lookup agrees (scan in scan).
    ASSERT(instruction->GetBlock() == block);
    // Make sure linked list agrees.
    ASSERT(prev->next() == instruction);
    ASSERT(instruction->previous() == prev);
    prev = instruction;
    // Make sure control flow makes sense.
    ASSERT(IsControlFlow(instruction) == (instruction == last));
    // Perform instruction specific checks.
    VisitInstruction(instruction);
  }
  ASSERT(prev == last);
  // Make sure loop information, when up-to-date, agrees.
  if (flow_graph_->loop_hierarchy_ != nullptr) {
    for (LoopInfo* loop = block->loop_info(); loop != nullptr;
         loop = loop->outer()) {
      ASSERT(loop->Contains(block));
    }
  }
}

void FlowGraphChecker::VisitInstruction(Instruction* instruction) {
  // Make sure all inputs are properly defined by something that
  // dominates the use that is not a Phi instruction (note that the
  // proper dominance relation on the input values of Phis are checked
  // by the Phi visitor below). Also verify some graph sanity.
  for (intptr_t i = 0, n = instruction->InputCount(); i < n; ++i) {
    Definition* def = instruction->InputAt(i)->definition();
    bool test_def = def->HasSSATemp();
    if (def->IsPhi()) {
      // Phis are never linked into graph.
      ASSERT(def->next() == nullptr);
      ASSERT(def->previous() == nullptr);
    } else if (def->IsConstant() || def->IsParameter() ||
               def->IsSpecialParameter()) {
      test_def = false;
    } else {
      ASSERT(def->next() != nullptr);
      ASSERT(def->previous() != nullptr);
    }
    if (test_def) {
      ASSERT(IsInDefUseList(def, instruction));  // proper def-use
      ASSERT(instruction->IsPhi() ||
             instruction->IsMaterializeObject() ||  // does not have dominance
             instruction->IsDominatedBy(def));
    }
  }
  // Visit specific instructions (definitions and anything with Visit()).
  if (auto def = instruction->AsDefinition()) {
    VisitDefinition(def);
  }
  instruction->Accept(this);
}

void FlowGraphChecker::VisitDefinition(Definition* def) {
  // Make sure each outgoing use is dominated by this def, or is a
  // Phi instruction (note that the proper dominance relation on
  // the input values of Phis are checked by the Phi visitor below).
  // Also verify some graph sanity.
  for (Value* use = def->input_use_list(); use != nullptr;
       use = use->next_use()) {
    ASSERT(use->definition() == def);  // proper use-def
    Instruction* use_instr = use->instruction();
    ASSERT(use_instr != nullptr);
    if (use_instr->IsPhi()) {
      ASSERT(use_instr->next() == nullptr);
      ASSERT(use_instr->previous() == nullptr);
      ASSERT(use_instr->GetBlock()->IsJoinEntry());
    } else {
      ASSERT(IsControlFlow(use_instr) || use_instr->next() != nullptr);
      ASSERT(use_instr->previous() != nullptr);
      ASSERT(use_instr->IsMaterializeObject() ||  // does not have dominance
             use_instr->IsDominatedBy(def));
    }
  }
}

void FlowGraphChecker::VisitConstant(ConstantInstr* constant) {
  const Object& value = constant->value();
  if (value.IsSmi()) {
    const int64_t smi_value = Integer::Cast(value).AsInt64Value();
    ASSERT(kSmiMin <= smi_value);
    ASSERT(smi_value <= kSmiMax);
  }
  // TODO(ajcbik): Is this a property we eventually want (all constants
  // generated by utility that queries pool and put in the graph entry
  // when seen first)? The inliner still creates some direct constants.
  // ASSERT(constant->GetBlock() == flow_graph_->graph_entry());
}

void FlowGraphChecker::VisitPhi(PhiInstr* phi) {
  // Phis are never linked into graph.
  ASSERT(phi->next() == nullptr);
  ASSERT(phi->previous() == nullptr);
  // Make sure each incoming input value of a Phi is dominated
  // on the corresponding incoming edge, as defined by order.
  ASSERT(phi->InputCount() == current_block_->PredecessorCount());
  for (intptr_t i = 0, n = phi->InputCount(); i < n; ++i) {
    Definition* input_def = phi->InputAt(i)->definition();
    BlockEntryInstr* edge = current_block_->PredecessorAt(i);
    ASSERT(input_def->IsConstant() ||  // some constants are in initial defs
           edge->last_instruction()->IsDominatedBy(input_def));
  }
}

void FlowGraphChecker::VisitGoto(GotoInstr* jmp) {
  ASSERT(jmp->SuccessorCount() == 1);
}

void FlowGraphChecker::VisitIndirectGoto(IndirectGotoInstr* jmp) {
  ASSERT(jmp->SuccessorCount() >= 1);
}

void FlowGraphChecker::VisitBranch(BranchInstr* branch) {
  ASSERT(branch->SuccessorCount() == 2);
}

// Main entry point of graph checker.
void FlowGraphChecker::Check() {
  ASSERT(flow_graph_ != nullptr);
  VisitBlocks();
}

}  // namespace dart

#endif  // defined(DEBUG)
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
