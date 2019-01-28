// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)
#if defined(DEBUG)

#include "vm/compiler/backend/flow_graph_checker.h"

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"

namespace dart {

FlowGraphChecker::FlowGraphChecker(FlowGraph* flow_graph)
    : flow_graph_(flow_graph) {}

static bool IsPred(BlockEntryInstr* block, BlockEntryInstr* succ) {
  for (intptr_t i = 0; i < succ->PredecessorCount(); ++i) {
    if (succ->PredecessorAt(i) == block) {
      return true;
    }
  }
  return false;
}

static bool IsSucc(BlockEntryInstr* block, BlockEntryInstr* pred) {
  Instruction* last = pred->last_instruction();
  for (intptr_t i = 0; i < last->SuccessorCount(); ++i) {
    if (last->SuccessorAt(i) == block) {
      return true;
    }
  }
  return false;
}

static bool IsDominated(BlockEntryInstr* block, BlockEntryInstr* dom) {
  for (intptr_t i = 0; i < dom->dominated_blocks().length(); ++i) {
    if (dom->dominated_blocks()[i] == block) {
      return true;
    }
  }
  return false;
}

void FlowGraphChecker::CheckBasicBlocks() {
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
  // const intptr_t max_block_id = flow_graph_->max_block_id();
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    // Re-enable this if possible
    // https://github.com/dart-lang/sdk/issues/35789
    // ASSERT(block->block_id() <= max_block_id);
    // Make sure ordering is consistent.
    ASSERT(block->preorder_number() <= block_count);
    ASSERT(block->postorder_number() <= block_count);
    ASSERT(preorder[block->preorder_number()] == block);
    ASSERT(postorder[block->postorder_number()] == block);
    // Make sure predecessors and successors agree.
    Instruction* last = block->last_instruction();
    for (intptr_t i = 0; i < last->SuccessorCount(); ++i) {
      ASSERT(IsPred(block, last->SuccessorAt(i)));
    }
    for (intptr_t i = 0; i < block->PredecessorCount(); ++i) {
      ASSERT(IsSucc(block, block->PredecessorAt(i)));
    }
    // Make sure dominance relations agree.
    const intptr_t num_dom = block->dominated_blocks().length();
    for (intptr_t i = 0; i < num_dom; ++i) {
      ASSERT(block->dominated_blocks()[i]->dominator() == block);
    }
    if (block->dominator() != nullptr) {
      ASSERT(IsDominated(block, block->dominator()));
    }
    // Visit all instructions in this block.
    CheckInstructions(block);
  }
}

void FlowGraphChecker::CheckInstructions(BlockEntryInstr* block) {
  Instruction* prev = block;
  for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
       instr_it.Advance()) {
    Instruction* instruction = instr_it.Current();
    // Make sure linked list agrees.
    ASSERT(prev->next() == instruction);
    ASSERT(instruction->previous() == prev);
    prev = instruction;
  }
}

// Main entry point of graph checker.
void FlowGraphChecker::Check() {
  ASSERT(flow_graph_ != nullptr);
  CheckBasicBlocks();
}

}  // namespace dart

#endif  // defined(DEBUG)
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
