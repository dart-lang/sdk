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
  if (ic_data_array.IsNull()) {
    DEBUG_ASSERT(IsolateGroup::Current()->HasAttemptedReload() ||
                 function.ForceOptimize());
    return;
  }
  Array& edge_counters = Array::Handle();
  edge_counters ^=
      ic_data_array.At(Function::ICDataArrayIndices::kEdgeCounters);
  if (edge_counters.IsNull()) {
    return;
  }

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
      : first(new Link(block, nullptr)), last(first), length(1) {}

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
    for (Link* link = source_chain->first; link != nullptr; link = link->next) {
      (*chains)[link->block->postorder_number()] = target_chain;
    }
    // Link the chains.
    source_chain->last->next = target_chain->first;
    // Update the state of the longer chain.
    target_chain->first = source_chain->first;
    target_chain->length += source_chain->length;
  } else {
    for (Link* link = target_chain->first; link != nullptr; link = link->next) {
      (*chains)[link->block->postorder_number()] = source_chain;
    }
    source_chain->last->next = target_chain->first;
    source_chain->last = target_chain->last;
    source_chain->length += target_chain->length;
  }
}

void BlockScheduler::ReorderBlocks(FlowGraph* flow_graph) {
  if (!flow_graph->should_reorder_blocks()) {
    return;
  }

  if (CompilerState::Current().is_aot()) {
    ReorderBlocksAOT(flow_graph);
  } else {
    ReorderBlocksJIT(flow_graph);
  }
}

void BlockScheduler::ReorderBlocksJIT(FlowGraph* flow_graph) {
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
  flow_graph->CodegenBlockOrder()->Add(graph_entry);
  FunctionEntryInstr* checked_entry = graph_entry->normal_entry();
  if (checked_entry != nullptr) {
    flow_graph->CodegenBlockOrder()->Add(checked_entry);
  }
  // Build a new block order.  Emit each chain when its first block occurs
  // in the original reverse postorder ordering.
  // Note: the resulting order is not topologically sorted and can't be
  // used a replacement for reverse_postorder in algorithms that expect
  // topological sort.
  for (intptr_t i = block_count - 1; i >= 0; --i) {
    if (chains[i]->first->block == flow_graph->postorder()[i]) {
      for (Link* link = chains[i]->first; link != nullptr; link = link->next) {
        if ((link->block != checked_entry) && (link->block != graph_entry)) {
          flow_graph->CodegenBlockOrder()->Add(link->block);
        }
      }
    }
  }
}

// AOT block order is based on reverse post order but with two changes:
//
// - Blocks which always throw and their direct predecessors are considered
// *cold* and moved to the end of the order.
// - Blocks which belong to the same loop are kept together (where possible)
// and not interspersed with other blocks.
//
namespace {
class AOTBlockScheduler {
 public:
  explicit AOTBlockScheduler(FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        block_count_(flow_graph->reverse_postorder().length()),
        marks_(block_count_),
        postorder_(block_count_),
        cold_postorder_(10) {
    marks_.FillWith(0, 0, block_count_);
  }

  void ComputeOrder() {
    ComputeOrderImpl();

    const auto codegen_order = flow_graph_->CodegenBlockOrder();
    for (intptr_t i = postorder_.length() - 1; i >= 0; --i) {
      codegen_order->Add(postorder_[i]);
    }
    for (intptr_t i = cold_postorder_.length() - 1; i >= 0; --i) {
      codegen_order->Add(cold_postorder_[i]);
    }
  }

 private:
  // The algorithm below is almost identical to |FlowGraph::DiscoverBlocks|, but
  // with few tweaks which guarantee improved scheduling for cold code and
  // loops.
  void ComputeOrderImpl() {
    PushBlock(flow_graph_->graph_entry());
    while (!block_stack_.is_empty()) {
      BlockEntryInstr* block = block_stack_.Last();
      auto& marks = MarksOf(block);
      auto last = block->last_instruction();
      const auto successor_count = last->SuccessorCount();

      if ((marks & kVisitedMark) == 0) {
        marks |= kVisitedMark;

        if (last->IsThrow() || last->IsReThrow()) {
          marks |= kColdMark;
        } else {
          // When visiting a block inside a loop with two successors
          // push the successor with lesser nesting *last*, so that it is
          // visited first. This helps to keep blocks which belong to the
          // same loop together.
          //
          // This is the main difference from |DiscoverBlocks| which always
          // visits successors in reverse order.
          if (successor_count == 2 && block->loop_info() != nullptr) {
            auto succ0 = last->SuccessorAt(0);
            auto succ1 = last->SuccessorAt(1);

            if (succ0->NestingDepth() < succ1->NestingDepth()) {
              PushBlock(succ1);
              PushBlock(succ0);
            } else {
              PushBlock(succ0);
              PushBlock(succ1);
            }
          } else {
            for (intptr_t i = 0; i < successor_count; i++) {
              PushBlock(last->SuccessorAt(i));
            }
          }

          // We have pushed some successors to the stack. Process them first.
          if (block_stack_.Last() != block) {
            continue;
          }

          // No successors added, fall through.
        }
      }

      // All successors of this block were visited, which means we are
      // done with this block.
      block_stack_.RemoveLast();

      // Propagate cold mark from the successors: if all successors are
      // cold then this block is cold as well.
      if (successor_count > 0) {
        uint8_t cold_mark = kColdMark;
        for (intptr_t i = 0; i < successor_count; i++) {
          cold_mark &= MarksOf(last->SuccessorAt(i));
        }
        marks |= cold_mark;
      }

      if ((marks & (kColdMark | kPinnedMark)) == kColdMark) {
        // This block is cold and not pinned: move it to cold section at
        // the end.
        cold_postorder_.Add(block);
      } else {
        postorder_.Add(block);
      }
    }
  }

  // The block was added to the stack.
  static constexpr uint8_t kSeenMark = 1 << 0;
  // The block was visited and all of its successors were added to the stack.
  static constexpr uint8_t kVisitedMark = 1 << 1;
  // The block terminates with unconditional throw or rethrow.
  static constexpr uint8_t kColdMark = 1 << 2;
  // The block should not move to cold section.
  static constexpr uint8_t kPinnedMark = 1 << 3;

  uint8_t& MarksOf(BlockEntryInstr* block) {
    return marks_[block->preorder_number()];
  }

  void PushBlock(BlockEntryInstr* block) {
    auto& marks = MarksOf(block);
    if ((marks & kSeenMark) == 0) {
      marks |= kSeenMark;
      block_stack_.Add(block);

      if (block->IsFunctionEntry() || block->IsGraphEntry()) {
        marks |= kPinnedMark;
      }
    }
  }

  FlowGraph* const flow_graph_;
  const intptr_t block_count_;

  // Block marks for each block indexed by block preorder number.
  GrowableArray<uint8_t> marks_;

  // Stack of blocks to process.
  GrowableArray<BlockEntryInstr*> block_stack_;

  GrowableArray<BlockEntryInstr*> postorder_;
  GrowableArray<BlockEntryInstr*> cold_postorder_;
};
}  // namespace

void BlockScheduler::ReorderBlocksAOT(FlowGraph* flow_graph) {
  AOTBlockScheduler(flow_graph).ComputeOrder();
}

}  // namespace dart
