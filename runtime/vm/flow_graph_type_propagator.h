// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_FLOW_GRAPH_TYPE_PROPAGATOR_H_
#define RUNTIME_VM_FLOW_GRAPH_TYPE_PROPAGATOR_H_

#include "vm/flow_graph.h"
#include "vm/intermediate_language.h"

namespace dart {

class FlowGraphTypePropagator : public FlowGraphVisitor {
 public:
  static void Propagate(FlowGraph* flow_graph);

 private:
  explicit FlowGraphTypePropagator(FlowGraph* flow_graph);

  void Propagate();

  void PropagateRecursive(BlockEntryInstr* block);

  void RollbackTo(intptr_t rollback_point);

  void VisitValue(Value* value);

  virtual void VisitJoinEntry(JoinEntryInstr* instr);
  virtual void VisitCheckSmi(CheckSmiInstr* instr);
  virtual void VisitCheckArrayBound(CheckArrayBoundInstr* instr);
  virtual void VisitCheckClass(CheckClassInstr* instr);
  virtual void VisitCheckClassId(CheckClassIdInstr* instr);
  virtual void VisitGuardFieldClass(GuardFieldClassInstr* instr);
  virtual void VisitAssertAssignable(AssertAssignableInstr* instr);
  virtual void VisitInstanceCall(InstanceCallInstr* instr);
  virtual void VisitPolymorphicInstanceCall(
      PolymorphicInstanceCallInstr* instr);

  // Current reaching type of the definition. Valid only during dominator tree
  // traversal.
  CompileType* TypeOf(Definition* def);

  // Mark definition as having given compile type in all dominated instructions.
  void SetTypeOf(Definition* def, CompileType* type);

  // Mark definition as having given class id in all dominated instructions.
  void SetCid(Definition* value, intptr_t cid);

  ConstrainedCompileType* MarkNonNullable(Definition* value);

  void AddToWorklist(Definition* defn);
  Definition* RemoveLastFromWorklist();

  // Type assertion strengthening.
  void StrengthenAsserts(BlockEntryInstr* block);
  void StrengthenAssertWith(Instruction* check);

  Zone* zone() const { return flow_graph_->zone(); }

  FlowGraph* flow_graph_;

  BitVector* visited_blocks_;

  // Mapping between SSA values and their current reaching types. Valid
  // only during dominator tree traversal.
  GrowableArray<CompileType*> types_;

  // Worklist for fixpoint computation.
  GrowableArray<Definition*> worklist_;
  BitVector* in_worklist_;

  ZoneGrowableArray<AssertAssignableInstr*>* asserts_;
  ZoneGrowableArray<intptr_t>* collected_asserts_;

  // RollbackEntry is used to track and rollback changed in the types_ array
  // done during dominator tree traversal.
  class RollbackEntry {
   public:
    // Default constructor needed for the container.
    RollbackEntry() : index_(), type_() {}

    RollbackEntry(intptr_t index, CompileType* type)
        : index_(index), type_(type) {}

    intptr_t index() const { return index_; }
    CompileType* type() const { return type_; }

   private:
    intptr_t index_;
    CompileType* type_;
  };

  GrowableArray<RollbackEntry> rollback_;
};

}  // namespace dart

#endif  // RUNTIME_VM_FLOW_GRAPH_TYPE_PROPAGATOR_H_
