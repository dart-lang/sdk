// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/block_scheduler.h"

#include "vm/allocation.h"
#include "vm/code_patcher.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/jit/compiler.h"

namespace dart {

static intptr_t GetEdgeCount(const Array& edge_counters, intptr_t edge_id) {
  if (!FLAG_reorder_basic_blocks) {
    // Assume everything was visited once.
    return 1;
  }
  return Smi::Value(Smi::RawCast(edge_counters.At(edge_id)));
}

// There is an edge from instruction->successor.  Set its weight (edge count
// per function entry).
static void SetEdgeWeight(BlockEntryInstr* block,
                          BlockEntryInstr* successor,
                          const Array& edge_counters,
                          intptr_t entry_count) {
  ASSERT(entry_count != 0);
  if (auto target = successor->AsTargetEntry()) {
    // If this block ends in a goto, the edge count of this edge is the same
    // as the count on the single outgoing edge. This is true as long as the
    // block does not throw an exception.
    intptr_t count = GetEdgeCount(edge_counters, target->preorder_number());
    if (count >= 0) {
      double weight =
          static_cast<double>(count) / static_cast<double>(entry_count);
      target->set_edge_weight(weight);
    }
  } else if (auto jump = block->last_instruction()->AsGoto()) {
    intptr_t count = GetEdgeCount(edge_counters, block->preorder_number());
    if (count >= 0) {
      double weight =
          static_cast<double>(count) / static_cast<double>(entry_count);
      jump->set_edge_weight(weight);
    }
  }
}

void BlockScheduler::AssignEdgeWeights(FlowGraph* flow_graph) {
  if (!FLAG_reorder_basic_blocks) {
    return;
  }
  if (CompilerState::Current().is_aot()) {
    return;
  }

  const Function& function = flow_graph->parsed_function().function();
  const Array& ic_data_array =
      Array::Handle(flow_graph->zone(), function.ic_data_array());
  if (Compiler::IsBackgroundCompilation() && ic_data_array.IsNull()) {
    // Deferred loading cleared ic_data_array.
    Compiler::AbortBackgroundCompilation(
        DeoptId::kNone, "BlockScheduler: ICData array cleared");
  }
  if (ic_data_array.IsNull()) {
    DEBUG_ASSERT(Isolate::Current()->HasAttemptedReload() ||
                 function.ForceOptimize());
    return;
  }
  Array& edge_counters = Array::Handle();
  edge_counters ^= ic_data_array.At(0);

  auto graph_entry = flow_graph->graph_entry();
  BlockEntryInstr* entry = graph_entry->normal_entry();
  if (entry == nullptr) {
    entry = graph_entry->osr_entry();
    ASSERT(entry != nullptr);
  }
  const intptr_t entry_count =
      GetEdgeCount(edge_counters, entry->preorder_number());
  graph_entry->set_entry_count(entry_count);
  if (entry_count == 0) {
    return;  // Nothing to do.
  }

  for (BlockIterator it = flow_graph->reverse_postorder_iterator(); !it.Done();
       it.Advance()) {
    BlockEntryInstr* block = it.Current();
    Instruction* last = block->last_instruction();
    for (intptr_t i = 0; i < last->SuccessorCount(); ++i) {
      BlockEntryInstr* succ = last->SuccessorAt(i);
      SetEdgeWeight(block, succ, edge_counters, entry_count);
    }
  }
}

// A weighted control-flow graph edge.
struct Edge {
  Edge(BlockEntryInstr* source, BlockEntryInstr* target, double weight)
      : source(source), target(target), weight(weight) {}

  static int LowestWeightFirst(const Edge* a, const Edge* b);

  BlockEntryInstr* source;
  BlockEntryInstr* target;
  double weight;
};

// A linked list node in a chain of blocks.
struct Link : public ZoneAllocated {
  Link(BlockEntryInstr* block, Link* next) : block(block), next(next) {}

  BlockEntryInstr* block;
  Link* next;
};

// A chain of blocks with first and last pointers for fast concatenation and
// a length to support adding a shorter chain's links to a longer chain.
struct Chain : public ZoneAllocated {
  explicit Chain(BlockEntryInstr* block)
      : first(new Link(block, NULL)), last(first), length(1) {}

  Link* first;
  Link* last;
  intptr_t length;
};

int Edge::LowestWeightFirst(const Edge* a, const Edge* b) {
  if (a->weight < b->weight) {
    return -1;
  }
  return (a->weight > b->weight) ? 1 : 0;
}

// Combine two chains by adding the shorter chain's links to the longer
// chain.
static void Union(GrowableArray<Chain*>* chains,
                  Chain* source_chain,
                  Chain* target_chain) {
  if (source_chain->length < target_chain->length) {
    for (Link* link = source_chain->first; link != NULL; link = link->next) {
      (*chains)[link->block->postorder_number()] = target_chain;
    }
    // Link the chains.
    source_chain->last->next = target_chain->first;
    // Update the state of the longer chain.
    target_chain->first = source_chain->first;
    target_chain->length += source_chain->length;
  } else {
    for (Link* link = target_chain->first; link != NULL; link = link->next) {
      (*chains)[link->block->postorder_number()] = source_chain;
    }
    source_chain->last->next = target_chain->first;
    source_chain->last = target_chain->last;
    source_chain->length += target_chain->length;
  }
}

void BlockScheduler::ReorderBlocks(FlowGraph* flow_graph) {
  if (CompilerState::Current().is_aot()) {
    ReorderBlocksAOT(flow_graph);
  } else {
    ReorderBlocksJIT(flow_graph);
  }
}

void BlockScheduler::ReorderBlocksJIT(FlowGraph* flow_graph) {
  if (!FLAG_reorder_basic_blocks) {
    return;
  }

  // Add every block to a chain of length 1 and compute a list of edges
  // sorted by weight.
  intptr_t block_count = flow_graph->preorder().length();
  GrowableArray<Edge> edges(2 * block_count);

  // A map from a block's postorder number to the chain it is in.  Used to
  // implement a simple (ordered) union-find data structure.  Chains are
  // stored by pointer so that they are aliased (mutating one mutates all
  // shared ones).  Find(n) is simply chains[n].
  GrowableArray<Chain*> chains(block_count);

  for (BlockIterator it = flow_graph->postorder_iterator(); !it.Done();
       it.Advance()) {
    BlockEntryInstr* block = it.Current();
    chains.Add(new Chain(block));

    Instruction* last = block->last_instruction();
    for (intptr_t i = 0; i < last->SuccessorCount(); ++i) {
      BlockEntryInstr* succ = last->SuccessorAt(i);
      double weight = 0.0;
      if (succ->IsTargetEntry()) {
        weight = succ->AsTargetEntry()->edge_weight();
      } else if (last->IsGoto()) {
        weight = last->AsGoto()->edge_weight();
      }
      edges.Add(Edge(block, succ, weight));
    }
  }

  // Handle each edge in turn.  The edges are sorted by increasing weight.
  edges.Sort(Edge::LowestWeightFirst);
  while (!edges.is_empty()) {
    Edge edge = edges.RemoveLast();
    Chain* source_chain = chains[edge.source->postorder_number()];
    Chain* target_chain = chains[edge.target->postorder_number()];

    // If the source and target are already in the same chain or if the
    // edge's source or target is not exposed at the appropriate end of a
    // chain skip this edge.
    if ((source_chain == target_chain) ||
        (edge.source != source_chain->last->block) ||
        (edge.target != target_chain->first->block)) {
      continue;
    }

    Union(&chains, source_chain, target_chain);
  }

  // Ensure the checked entry remains first to avoid needing another offset on
  // Instructions, compare Code::EntryPointOf.
  GraphEntryInstr* graph_entry = flow_graph->graph_entry();
  flow_graph->CodegenBlockOrder(true)->Add(graph_entry);
  FunctionEntryInstr* checked_entry = graph_entry->normal_entry();
  if (checked_entry != nullptr) {
    flow_graph->CodegenBlockOrder(true)->Add(checked_entry);
  }
  // Build a new block order.  Emit each chain when its first block occurs
  // in the original reverse postorder ordering (which gives a topological
  // sort of the blocks).
  for (intptr_t i = block_count - 1; i >= 0; --i) {
    if (chains[i]->first->block == flow_graph->postorder()[i]) {
      for (Link* link = chains[i]->first; link != NULL; link = link->next) {
        if ((link->block != checked_entry) && (link->block != graph_entry)) {
          flow_graph->CodegenBlockOrder(true)->Add(link->block);
        }
      }
    }
  }
}

// Moves blocks ending in a throw/rethrow, as well as any block post-dominated
// by such a throwing block, to the end.
void BlockScheduler::ReorderBlocksAOT(FlowGraph* flow_graph) {
  if (!FLAG_reorder_basic_blocks) {
    return;
  }

  auto& reverse_postorder = flow_graph->reverse_postorder();
  const intptr_t block_count = reverse_postorder.length();
  GrowableArray<bool> is_terminating(block_count);
  is_terminating.FillWith(false, 0, block_count);

  // Any block in the worklist is marked and any of its unconditional
  // predecessors need to be marked as well.
  GrowableArray<BlockEntryInstr*> worklist;

  // Add all throwing blocks to the worklist.
  for (intptr_t i = 0; i < block_count; ++i) {
    auto block = reverse_postorder[i];
    auto last = block->last_instruction();
    if (last->IsThrow() || last->IsReThrow()) {
      const intptr_t preorder_nr = block->preorder_number();
      is_terminating[preorder_nr] = true;
      worklist.Add(block);
    }
  }

  // Follow all indirect predecessors which unconditionally will end up in a
  // throwing block.
  while (worklist.length() > 0) {
    auto block = worklist.RemoveLast();
    for (intptr_t i = 0; i < block->PredecessorCount(); ++i) {
      auto predecessor = block->PredecessorAt(i);
      if (predecessor->last_instruction()->IsGoto()) {
        const intptr_t preorder_nr = predecessor->preorder_number();
        if (!is_terminating[preorder_nr]) {
          is_terminating[preorder_nr] = true;
          worklist.Add(predecessor);
        }
      }
    }
  }

  // Emit code in reverse postorder but move any throwing blocks (except the
  // function entry, which needs to come first) to the very end.
  auto codegen_order = flow_graph->CodegenBlockOrder(true);
  for (intptr_t i = 0; i < block_count; ++i) {
    auto block = reverse_postorder[i];
    const intptr_t preorder_nr = block->preorder_number();
    if (!is_terminating[preorder_nr] || block->IsFunctionEntry()) {
      codegen_order->Add(block);
    }
  }
  for (intptr_t i = 0; i < block_count; ++i) {
    auto block = reverse_postorder[i];
    const intptr_t preorder_nr = block->preorder_number();
    if (is_terminating[preorder_nr] && !block->IsFunctionEntry()) {
      codegen_order->Add(block);
    }
  }
}

}  // namespace dart
