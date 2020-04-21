// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_FLOW_GRAPH_BUILDER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_FLOW_GRAPH_BUILDER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/allocation.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/growable_array.h"
#include "vm/raw_object.h"

namespace dart {

// A class to collect the exits from an inlined function during graph
// construction so they can be plugged into the caller's flow graph.
class InlineExitCollector : public ZoneAllocated {
 public:
  InlineExitCollector(FlowGraph* caller_graph, Definition* call)
      : caller_graph_(caller_graph), call_(call), exits_(4) {}

  void AddExit(ReturnInstr* exit);

  void Union(const InlineExitCollector* other);

  // Before replacing a call with a graph, the outer environment needs to be
  // attached to each instruction in the callee graph and the caller graph
  // needs to have its block and instruction ID state updated.
  // Additionally we need to remove all unreachable exits from the list of
  // collected exits.
  void PrepareGraphs(FlowGraph* callee_graph);

  // Inline a graph at a call site.
  //
  // Assumes the callee is in SSA with a correct dominator tree and use
  // lists.
  //
  // After inlining the caller graph will have correctly adjusted the use
  // lists.  The block orders will need to be recomputed.
  void ReplaceCall(BlockEntryInstr* callee_entry);

 private:
  struct Data {
    BlockEntryInstr* exit_block;
    ReturnInstr* exit_return;
  };

  BlockEntryInstr* ExitBlockAt(intptr_t i) const {
    ASSERT(exits_[i].exit_block != NULL);
    return exits_[i].exit_block;
  }

  Instruction* LastInstructionAt(intptr_t i) const {
    return ReturnAt(i)->previous();
  }

  Value* ValueAt(intptr_t i) const { return ReturnAt(i)->value(); }

  ReturnInstr* ReturnAt(intptr_t i) const { return exits_[i].exit_return; }

  static int LowestBlockIdFirst(const Data* a, const Data* b);
  void SortExits();
  void RemoveUnreachableExits(FlowGraph* callee_graph);

  Definition* JoinReturns(BlockEntryInstr** exit_block,
                          Instruction** last_instruction,
                          intptr_t try_index);

  Isolate* isolate() const { return caller_graph_->isolate(); }
  Zone* zone() const { return caller_graph_->zone(); }

  FlowGraph* caller_graph_;
  Definition* call_;
  GrowableArray<Data> exits_;
};

bool SimpleInstanceOfType(const AbstractType& type);
uword FindDoubleConstant(double value);

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_FLOW_GRAPH_BUILDER_H_
