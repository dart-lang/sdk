// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_OPTIMIZER_H_
#define VM_FLOW_GRAPH_OPTIMIZER_H_

#include "vm/intermediate_language.h"
#include "vm/flow_graph.h"

namespace dart {

template <typename T> class GrowableArray;
template <typename T> class DirectChainedHashMap;

class FlowGraphOptimizer : public FlowGraphVisitor {
 public:
  explicit FlowGraphOptimizer(FlowGraph* flow_graph)
      : FlowGraphVisitor(flow_graph->reverse_postorder()),
        flow_graph_(flow_graph) { }
  virtual ~FlowGraphOptimizer() {}

  void ApplyICData();

  void OptimizeComputations();

  void EliminateDeadPhis();

  void SelectRepresentations();

  void PropagateSminess();

  virtual void VisitStaticCall(StaticCallInstr* instr);
  virtual void VisitInstanceCall(InstanceCallInstr* instr);
  virtual void VisitRelationalOp(RelationalOpInstr* instr);
  virtual void VisitEqualityCompare(EqualityCompareInstr* instr);
  virtual void VisitBranch(BranchInstr* instr);

  void InsertBefore(Instruction* next,
                    Instruction* instr,
                    Environment* env,
                    Definition::UseKind use_kind);

 private:
  bool TryReplaceWithArrayOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithBinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithUnaryOp(InstanceCallInstr* call, Token::Kind op_kind);

  bool TryInlineInstanceGetter(InstanceCallInstr* call);
  bool TryInlineInstanceSetter(InstanceCallInstr* call);

  bool TryInlineInstanceMethod(InstanceCallInstr* call);

  void AddCheckClass(InstanceCallInstr* call, Value* value);

  void InsertAfter(Instruction* prev,
                   Instruction* instr,
                   Environment* env,
                   Definition::UseKind use_kind);

  void InsertConversionsFor(Definition* def);

  bool InstanceCallNeedsClassCheck(InstanceCallInstr* call) const;

  FlowGraph* flow_graph_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphOptimizer);
};


// Analyze the generated flow graph. Currently only if it is a leaf
// method, i.e., does not contain any calls to runtime or other Dart code.
class FlowGraphAnalyzer : public ValueObject {
 public:
  explicit FlowGraphAnalyzer(const FlowGraph& flow_graph)
      : blocks_(flow_graph.reverse_postorder()), is_leaf_(false) {}
  virtual ~FlowGraphAnalyzer() {}

  void Analyze();

  bool is_leaf() const { return is_leaf_; }

 private:
  const GrowableArray<BlockEntryInstr*>& blocks_;
  bool is_leaf_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphAnalyzer);
};


class ParsedFunction;


class FlowGraphTypePropagator : public FlowGraphVisitor {
 public:
  explicit FlowGraphTypePropagator(FlowGraph* flow_graph)
      : FlowGraphVisitor(flow_graph->reverse_postorder()),
        parsed_function_(flow_graph->parsed_function()),
        flow_graph_(flow_graph),
        still_changing_(false) { }
  virtual ~FlowGraphTypePropagator() { }

  const ParsedFunction& parsed_function() const { return parsed_function_; }

  void PropagateTypes();

 private:
  virtual void VisitBlocks();

  virtual void VisitAssertAssignable(AssertAssignableInstr* instr);
  virtual void VisitAssertBoolean(AssertBooleanInstr* instr);
  virtual void VisitInstanceOf(InstanceOfInstr* instr);

  virtual void VisitGraphEntry(GraphEntryInstr* graph_entry);
  virtual void VisitJoinEntry(JoinEntryInstr* join_entry);
  virtual void VisitPhi(PhiInstr* phi);
  virtual void VisitParameter(ParameterInstr* param);
  virtual void VisitPushArgument(PushArgumentInstr* bind);

  const ParsedFunction& parsed_function_;
  FlowGraph* flow_graph_;
  bool still_changing_;
  DISALLOW_COPY_AND_ASSIGN(FlowGraphTypePropagator);
};


// Loop invariant code motion.
class LICM : public AllStatic {
 public:
  static void Optimize(FlowGraph* flow_graph);

 private:
  static void Hoist(ForwardInstructionIterator* it,
                    BlockEntryInstr* pre_header,
                    Instruction* current);

  static void TryHoistCheckSmiThroughPhi(ForwardInstructionIterator* it,
                                         BlockEntryInstr* header,
                                         BlockEntryInstr* pre_header,
                                         Instruction* current);
};


// A simple common subexpression elimination based
// on the dominator tree.
class DominatorBasedCSE : public AllStatic {
 public:
  static void Optimize(FlowGraph* graph);

 private:
  static void OptimizeRecursive(
      BlockEntryInstr* entry,
      DirectChainedHashMap<Instruction*>* map);
};


// Sparse conditional constant propagation and unreachable code elimination.
// Assumes that use lists are computed and preserves them.
class ConstantPropagator : public FlowGraphVisitor {
 public:
  ConstantPropagator(FlowGraph* graph,
                     const GrowableArray<BlockEntryInstr*>& ignored);

  static void Optimize(FlowGraph* graph);

  // Used to initialize the abstract value of definitions.
  static RawObject* Unknown() { return Object::transition_sentinel(); }

 private:
  void Analyze();
  void Transform();

  void SetReachable(BlockEntryInstr* block);
  void SetValue(Definition* definition, const Object& value);

  // Assign the join (least upper bound) of a pair of abstract values to the
  // first one.
  void Join(Object* left, const Object& right);

  bool IsUnknown(const Object& value) {
    return value.raw() == unknown_.raw();
  }
  bool IsNonConstant(const Object& value) {
    return value.raw() == non_constant_.raw();
  }
  bool IsConstant(const Object& value) {
    return !IsNonConstant(value) && !IsUnknown(value);
  }

  virtual void VisitBlocks() { UNREACHABLE(); }

#define DECLARE_VISIT(type) virtual void Visit##type(type##Instr* instr);
  FOR_EACH_INSTRUCTION(DECLARE_VISIT)
#undef DECLARE_VISIT

  FlowGraph* graph_;

  // Sentinels for unknown constant and non-constant values.
  const Object& unknown_;
  const Object& non_constant_;

  // Analysis results. For each block, a reachability bit.  Indexed by
  // preorder number.
  BitVector* reachable_;

  // Definitions can move up the lattice twice, so we use a mark bit to
  // indicate that they are already on the worklist in order to avoid adding
  // them again.  Indexed by SSA temp index.
  BitVector* definition_marks_;

  // Worklists of blocks and definitions.
  GrowableArray<BlockEntryInstr*> block_worklist_;
  GrowableArray<Definition*> definition_worklist_;
};


}  // namespace dart

#endif  // VM_FLOW_GRAPH_OPTIMIZER_H_
