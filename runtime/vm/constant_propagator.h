// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANT_PROPAGATOR_H_
#define RUNTIME_VM_CONSTANT_PROPAGATOR_H_

#include "vm/flow_graph.h"
#include "vm/intermediate_language.h"

namespace dart {

// Sparse conditional constant propagation and unreachable code elimination.
// Assumes that use lists are computed and preserves them.
class ConstantPropagator : public FlowGraphVisitor {
 public:
  ConstantPropagator(FlowGraph* graph,
                     const GrowableArray<BlockEntryInstr*>& ignored);

  static void Optimize(FlowGraph* graph);

  // (1) Visit branches to optimize away unreachable blocks discovered  by range
  // analysis.
  // (2) Eliminate branches that have the same true- and false-target: For
  // example, this occurs after expressions like
  //
  // if (a == null || b == null) {
  //   ...
  // }
  //
  // where b is known to be null.
  static void OptimizeBranches(FlowGraph* graph);

  // Used to initialize the abstract value of definitions.
  static RawObject* Unknown() { return Object::unknown_constant().raw(); }

 private:
  void Analyze();
  void Transform();
  void EliminateRedundantBranches();

  void SetReachable(BlockEntryInstr* block);
  bool SetValue(Definition* definition, const Object& value);

  Definition* UnwrapPhi(Definition* defn);
  void MarkPhi(Definition* defn);

  // Assign the join (least upper bound) of a pair of abstract values to the
  // first one.
  void Join(Object* left, const Object& right);

  bool IsUnknown(const Object& value) { return value.raw() == unknown_.raw(); }
  bool IsNonConstant(const Object& value) {
    return value.raw() == non_constant_.raw();
  }
  bool IsConstant(const Object& value) {
    return !IsNonConstant(value) && !IsUnknown(value);
  }

  void VisitBinaryIntegerOp(BinaryIntegerOpInstr* binary_op);
  void VisitUnaryIntegerOp(UnaryIntegerOpInstr* unary_op);

  virtual void VisitBlocks() { UNREACHABLE(); }

#define DECLARE_VISIT(type) virtual void Visit##type(type##Instr* instr);
  FOR_EACH_INSTRUCTION(DECLARE_VISIT)
#undef DECLARE_VISIT

  Isolate* isolate() const { return graph_->isolate(); }

  FlowGraph* graph_;

  // Sentinels for unknown constant and non-constant values.
  const Object& unknown_;
  const Object& non_constant_;

  // Analysis results. For each block, a reachability bit.  Indexed by
  // preorder number.
  BitVector* reachable_;

  BitVector* marked_phis_;

  // Worklists of blocks and definitions.
  GrowableArray<BlockEntryInstr*> block_worklist_;
  DefinitionWorklist definition_worklist_;
};

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANT_PROPAGATOR_H_
