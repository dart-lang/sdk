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

  void AnalyzeLiveness();

 private:
  void ComputeKillAndGenSets();
  bool UpdateLiveOut(BlockEntryInstr* instr);
  bool UpdateLiveIn(BlockEntryInstr* instr);
  void ComputeLiveInAndLiveOutSets();
  void DumpLiveness();

  GrowableArray<BitVector*> live_out_;
  GrowableArray<BitVector*> kill_;
  GrowableArray<BitVector*> gen_;
  GrowableArray<BitVector*> live_in_;
  const GrowableArray<BlockEntryInstr*>& postorder_;
  const intptr_t vreg_count_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphAllocator);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_ALLOCATOR_H_
