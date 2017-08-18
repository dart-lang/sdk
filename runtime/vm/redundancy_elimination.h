// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REDUNDANCY_ELIMINATION_H_
#define RUNTIME_VM_REDUNDANCY_ELIMINATION_H_

#include "vm/flow_graph.h"
#include "vm/intermediate_language.h"

namespace dart {

class CSEInstructionMap;

class AllocationSinking : public ZoneAllocated {
 public:
  explicit AllocationSinking(FlowGraph* flow_graph)
      : flow_graph_(flow_graph), candidates_(5), materializations_(5) {}

  const GrowableArray<Definition*>& candidates() const { return candidates_; }

  // Find the materialization inserted for the given allocation
  // at the given exit.
  MaterializeObjectInstr* MaterializationFor(Definition* alloc,
                                             Instruction* exit);

  void Optimize();

  void DetachMaterializations();

 private:
  // Helper class to collect deoptimization exits that might need to
  // rematerialize an object: that is either instructions that reference
  // this object explicitly in their deoptimization environment or
  // reference some other allocation sinking candidate that points to
  // this object.
  class ExitsCollector : public ValueObject {
   public:
    ExitsCollector() : exits_(10), worklist_(3) {}

    const GrowableArray<Instruction*>& exits() const { return exits_; }

    void CollectTransitively(Definition* alloc);

   private:
    // Collect immediate uses of this object in the environments.
    // If this object is stored into other allocation sinking candidates
    // put them onto worklist so that CollectTransitively will process them.
    void Collect(Definition* alloc);

    GrowableArray<Instruction*> exits_;
    GrowableArray<Definition*> worklist_;
  };

  void CollectCandidates();

  void NormalizeMaterializations();

  void RemoveUnusedMaterializations();

  void DiscoverFailedCandidates();

  void InsertMaterializations(Definition* alloc);

  void CreateMaterializationAt(Instruction* exit,
                               Definition* alloc,
                               const ZoneGrowableArray<const Object*>& fields);

  void EliminateAllocation(Definition* alloc);

  Isolate* isolate() const { return flow_graph_->isolate(); }
  Zone* zone() const { return flow_graph_->zone(); }

  FlowGraph* flow_graph_;

  GrowableArray<Definition*> candidates_;
  GrowableArray<MaterializeObjectInstr*> materializations_;

  ExitsCollector exits_collector_;
};

// A simple common subexpression elimination based
// on the dominator tree.
class DominatorBasedCSE : public AllStatic {
 public:
  // Return true, if the optimization changed the flow graph.
  // False, if nothing changed.
  static bool Optimize(FlowGraph* graph);

 private:
  static bool OptimizeRecursive(FlowGraph* graph,
                                BlockEntryInstr* entry,
                                CSEInstructionMap* map);
};

class DeadStoreElimination : public AllStatic {
 public:
  static void Optimize(FlowGraph* graph);
};

class DeadCodeElimination : public AllStatic {
 public:
  static void EliminateDeadPhis(FlowGraph* graph);
};

// Optimize spill stores inside try-blocks by identifying values that always
// contain a single known constant at catch block entry.
class TryCatchAnalyzer : public AllStatic {
 public:
  static void Optimize(FlowGraph* flow_graph);
};

// Loop invariant code motion.
class LICM : public ValueObject {
 public:
  explicit LICM(FlowGraph* flow_graph);

  void Optimize();

  void OptimisticallySpecializeSmiPhis();

 private:
  FlowGraph* flow_graph() const { return flow_graph_; }

  void Hoist(ForwardInstructionIterator* it,
             BlockEntryInstr* pre_header,
             Instruction* current);

  void TrySpecializeSmiPhi(PhiInstr* phi,
                           BlockEntryInstr* header,
                           BlockEntryInstr* pre_header);

  FlowGraph* const flow_graph_;
};

}  // namespace dart

#endif  // RUNTIME_VM_REDUNDANCY_ELIMINATION_H_
