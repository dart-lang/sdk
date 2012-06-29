// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_ALLOCATOR_H_
#define VM_FLOW_GRAPH_ALLOCATOR_H_

#include "vm/growable_array.h"
#include "vm/intermediate_language.h"

namespace dart {

class FlowGraphAllocator : public ValueObject {
 public:
  FlowGraphAllocator(const GrowableArray<BlockEntryInstr*>& postorder,
                     intptr_t max_ssa_temp_index);

  void ResolveConstraints();

  // Build live-in and live-out sets for each block.
  void AnalyzeLiveness();

 private:
  // Compute initial values for live-out, kill and live-in sets.
  void ComputeInitialSets();

  // Update live-out set for the given block: live-out should contain
  // all values that are live-in for block's successors.
  // Returns true if live-out set was changed.
  bool UpdateLiveOut(BlockEntryInstr* instr);

  // Update live-in set for the given block: live-in should contain
  // all values taht are live-out from the block and are not defined
  // by this block.
  // Returns true if live-in set was changed.
  bool UpdateLiveIn(BlockEntryInstr* instr);

  // Perform fix-point iteration updating live-out and live-in sets
  // for blocks until they stop changing.
  void ComputeLiveInAndLiveOutSets();

  // Print results of liveness analysis.
  void DumpLiveness();

  // Live-out sets for each block.  They contain indices of SSA values
  // that are live out from this block: that is values that were either
  // defined in this block or live into it and that are used in some
  // successor block.
  GrowableArray<BitVector*> live_out_;

  // Kill sets for each block.  They contain indices of SSA values that
  // are defined by this block.
  GrowableArray<BitVector*> kill_;

  // Live-in sets for each block.  They contain indices of SSA values
  // that are used by this block or its successors.
  GrowableArray<BitVector*> live_in_;

  const GrowableArray<BlockEntryInstr*>& postorder_;

  // Number of virtual registers.  Currently equal to the number of
  // SSA values.
  const intptr_t vreg_count_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphAllocator);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_ALLOCATOR_H_
