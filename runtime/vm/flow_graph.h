// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_H_
#define VM_FLOW_GRAPH_H_

#include "vm/growable_array.h"
#include "vm/parser.h"

namespace dart {

class BlockEntryInstr;
class Definition;
class FlowGraphBuilder;
class GraphEntryInstr;
class PhiInstr;

// Class to incapsulate the construction and manipulation of the flow graph.
class FlowGraph: public ZoneAllocated {
 public:
  FlowGraph(const FlowGraphBuilder& builder, GraphEntryInstr* graph_entry);

  // Function properties.
  const ParsedFunction& parsed_function() const {
    return parsed_function_;
  }
  intptr_t parameter_count() const {
    return copied_parameter_count_ + non_copied_parameter_count_;
  }
  intptr_t variable_count() const {
    return parameter_count() + stack_local_count_;
  }
  intptr_t stack_local_count() const {
    return stack_local_count_;
  }
  intptr_t copied_parameter_count() const {
    return copied_parameter_count_;
  }
  intptr_t non_copied_parameter_count() const {
    return non_copied_parameter_count_;
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

  intptr_t max_virtual_register_number() const {
    return current_ssa_temp_index();
  }

  // Operations on the flow graph.
  void ComputeSSA();

  // TODO(zerny): Once the SSA is feature complete this should be removed.
  void Bailout(const char* reason) const;

 private:
  void DiscoverBlocks();

  // SSA transformation methods and fields.
  void ComputeDominators(
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<intptr_t>* parent,
      GrowableArray<BitVector*>* dominance_frontier);

  void CompressPath(
      intptr_t start_index,
      intptr_t current_index,
      GrowableArray<intptr_t>* parent,
      GrowableArray<intptr_t>* label);

  void Rename(GrowableArray<PhiInstr*>* live_phis);
  void RenameRecursive(
      BlockEntryInstr* block_entry,
      GrowableArray<Definition*>* env,
      GrowableArray<PhiInstr*>* live_phis);

  void InsertPhis(
      const GrowableArray<BlockEntryInstr*>& preorder,
      const GrowableArray<BitVector*>& assigned_vars,
      const GrowableArray<BitVector*>& dom_frontier);

  void MarkLivePhis(GrowableArray<PhiInstr*>* live_phis);

  intptr_t current_ssa_temp_index() const { return current_ssa_temp_index_; }
  intptr_t alloc_ssa_temp_index() { return current_ssa_temp_index_++; }

  // DiscoverBlocks computes parent_ and assigned_vars_ which are then used
  // if/when computing SSA.
  GrowableArray<intptr_t> parent_;
  GrowableArray<BitVector*> assigned_vars_;

  intptr_t current_ssa_temp_index_;

  // Flow graph fields.
  const ParsedFunction& parsed_function_;
  const intptr_t copied_parameter_count_;
  const intptr_t non_copied_parameter_count_;
  const intptr_t stack_local_count_;
  GraphEntryInstr* graph_entry_;
  GrowableArray<BlockEntryInstr*> preorder_;
  GrowableArray<BlockEntryInstr*> postorder_;
  GrowableArray<BlockEntryInstr*> reverse_postorder_;
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_H_
