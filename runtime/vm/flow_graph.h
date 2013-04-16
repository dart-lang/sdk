// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_H_
#define VM_FLOW_GRAPH_H_

#include "vm/growable_array.h"
#include "vm/intermediate_language.h"
#include "vm/parser.h"

namespace dart {

class FlowGraphBuilder;
class ValueInliningContext;
class VariableLivenessAnalysis;

class BlockIterator : public ValueObject {
 public:
  explicit BlockIterator(const GrowableArray<BlockEntryInstr*>& block_order)
      : block_order_(block_order), current_(0) { }

  BlockIterator(const BlockIterator& other)
      : ValueObject(),
        block_order_(other.block_order_),
        current_(other.current_) { }

  void Advance() {
    ASSERT(!Done());
    current_++;
  }

  bool Done() const { return current_ >= block_order_.length(); }

  BlockEntryInstr* Current() const { return block_order_[current_]; }

 private:
  const GrowableArray<BlockEntryInstr*>& block_order_;
  intptr_t current_;
};


// Class to incapsulate the construction and manipulation of the flow graph.
class FlowGraph : public ZoneAllocated {
 public:
  FlowGraph(const FlowGraphBuilder& builder,
            GraphEntryInstr* graph_entry,
            intptr_t max_block_id);

  // Function properties.
  const ParsedFunction& parsed_function() const {
    return parsed_function_;
  }
  intptr_t parameter_count() const {
    return num_copied_params_ + num_non_copied_params_;
  }
  intptr_t variable_count() const {
    return parameter_count() + num_stack_locals_;
  }
  intptr_t num_stack_locals() const {
    return num_stack_locals_;
  }
  intptr_t num_copied_params() const {
    return num_copied_params_;
  }
  intptr_t num_non_copied_params() const {
    return num_non_copied_params_;
  }

  // Flow graph orders.
  const GrowableArray<BlockEntryInstr*>& preorder() const {
    return preorder_;
  }
  const GrowableArray<BlockEntryInstr*>& postorder() const {
    return postorder_;
  }
  const GrowableArray<BlockEntryInstr*>& reverse_postorder() const {
    return reverse_postorder_;
  }

  // Iterators.
  BlockIterator reverse_postorder_iterator() const {
    return BlockIterator(reverse_postorder());
  }
  BlockIterator postorder_iterator() const {
    return BlockIterator(postorder());
  }

  intptr_t current_ssa_temp_index() const { return current_ssa_temp_index_; }
  void set_current_ssa_temp_index(intptr_t index) {
    current_ssa_temp_index_ = index;
  }

  intptr_t max_virtual_register_number() const {
    return current_ssa_temp_index();
  }

  intptr_t max_block_id() const { return max_block_id_; }
  void set_max_block_id(intptr_t id) { max_block_id_ = id; }

  GraphEntryInstr* graph_entry() const {
    return graph_entry_;
  }

  ConstantInstr* constant_null() const {
    return constant_null_;
  }

  intptr_t alloc_ssa_temp_index() { return current_ssa_temp_index_++; }

  intptr_t InstructionCount() const;

  ConstantInstr* AddConstantToInitialDefinitions(const Object& object);
  void AddToInitialDefinitions(Definition* defn);

  void InsertBefore(Instruction* next,
                    Instruction* instr,
                    Environment* env,
                    Definition::UseKind use_kind);
  void InsertAfter(Instruction* prev,
                   Instruction* instr,
                   Environment* env,
                   Definition::UseKind use_kind);

  // Operations on the flow graph.
  void ComputeSSA(intptr_t next_virtual_register_number,
                  ZoneGrowableArray<Definition*>* inlining_parameters);

  // Finds natural loops in the flow graph and attaches a list of loop
  // body blocks for each loop header.
  void ComputeLoops(GrowableArray<BlockEntryInstr*>* loop_headers);

  // TODO(zerny): Once the SSA is feature complete this should be removed.
  void Bailout(const char* reason) const;

#ifdef DEBUG
  // Verification methods for debugging.
  bool VerifyUseLists();
#endif  // DEBUG

  void DiscoverBlocks();

 private:
  friend class IfConverter;
  friend class BranchSimplifier;
  friend class ConstantPropagator;

  // SSA transformation methods and fields.
  void ComputeDominators(GrowableArray<BitVector*>* dominance_frontier);

  void CompressPath(
      intptr_t start_index,
      intptr_t current_index,
      GrowableArray<intptr_t>* parent,
      GrowableArray<intptr_t>* label);

  void Rename(GrowableArray<PhiInstr*>* live_phis,
              VariableLivenessAnalysis* variable_liveness,
              ZoneGrowableArray<Definition*>* inlining_parameters);
  void RenameRecursive(
      BlockEntryInstr* block_entry,
      GrowableArray<Definition*>* env,
      GrowableArray<PhiInstr*>* live_phis,
      VariableLivenessAnalysis* variable_liveness);

  void AttachEnvironment(Instruction* instr, GrowableArray<Definition*>* env);

  void InsertPhis(
      const GrowableArray<BlockEntryInstr*>& preorder,
      const GrowableArray<BitVector*>& assigned_vars,
      const GrowableArray<BitVector*>& dom_frontier);

  void RemoveDeadPhis(GrowableArray<PhiInstr*>* live_phis);

  void ReplacePredecessor(BlockEntryInstr* old_block,
                          BlockEntryInstr* new_block);

  // DiscoverBlocks computes parent_ and assigned_vars_ which are then used
  // if/when computing SSA.
  GrowableArray<intptr_t> parent_;
  GrowableArray<BitVector*> assigned_vars_;

  intptr_t current_ssa_temp_index_;
  intptr_t max_block_id_;

  // Flow graph fields.
  const ParsedFunction& parsed_function_;
  const intptr_t num_copied_params_;
  const intptr_t num_non_copied_params_;
  const intptr_t num_stack_locals_;
  GraphEntryInstr* graph_entry_;
  GrowableArray<BlockEntryInstr*> preorder_;
  GrowableArray<BlockEntryInstr*> postorder_;
  GrowableArray<BlockEntryInstr*> reverse_postorder_;
  ConstantInstr* constant_null_;
};


class LivenessAnalysis : public ValueObject {
 public:
  LivenessAnalysis(intptr_t variable_count,
                   const GrowableArray<BlockEntryInstr*>& postorder);

  void Analyze();

  virtual ~LivenessAnalysis() { }

  BitVector* GetLiveInSetAt(intptr_t postorder_number) const {
    return live_in_[postorder_number];
  }

  BitVector* GetLiveOutSetAt(intptr_t postorder_number) const {
    return live_out_[postorder_number];
  }

  BitVector* GetLiveInSet(BlockEntryInstr* block) const {
    return GetLiveInSetAt(block->postorder_number());
  }

  BitVector* GetKillSet(BlockEntryInstr* block) const {
    return kill_[block->postorder_number()];
  }

  BitVector* GetLiveOutSet(BlockEntryInstr* block) const {
    return GetLiveOutSetAt(block->postorder_number());
  }

  // Print results of liveness analysis.
  void Dump();

 protected:
  // Compute initial values for live-out, kill and live-in sets.
  virtual void ComputeInitialSets() = 0;

  // Update live-out set for the given block: live-out should contain
  // all values that are live-in for block's successors.
  // Returns true if live-out set was changed.
  bool UpdateLiveOut(const BlockEntryInstr& instr);

  // Update live-in set for the given block: live-in should contain
  // all values that are live-out from the block and are not defined
  // by this block.
  // Returns true if live-in set was changed.
  bool UpdateLiveIn(const BlockEntryInstr& instr);

  // Perform fix-point iteration updating live-out and live-in sets
  // for blocks until they stop changing.
  void ComputeLiveInAndLiveOutSets();

  const intptr_t variable_count_;

  const GrowableArray<BlockEntryInstr*>& postorder_;

  // Live-out sets for each block.  They contain indices of variables
  // that are live out from this block: that is values that were either
  // defined in this block or live into it and that are used in some
  // successor block.
  GrowableArray<BitVector*> live_out_;

  // Kill sets for each block.  They contain indices of variables that
  // are defined by this block.
  GrowableArray<BitVector*> kill_;

  // Live-in sets for each block.  They contain indices of variables
  // that are used by this block or its successors.
  GrowableArray<BitVector*> live_in_;
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_H_
