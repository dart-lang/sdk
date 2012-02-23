// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_BUILDER_H_
#define VM_FLOW_GRAPH_BUILDER_H_

#include "vm/allocation.h"
#include "vm/ast.h"
#include "vm/growable_array.h"
#include "vm/intermediate_language.h"

namespace dart {

class Instruction;
class ParsedFunction;

// Build a flow graph from a parsed function's AST.
class FlowGraphBuilder: public ValueObject {
 public:
  explicit FlowGraphBuilder(const ParsedFunction& parsed_function)
      : parsed_function_(parsed_function),
        postorder_block_entries_() { }

  void BuildGraph();

  const ParsedFunction& parsed_function() const { return parsed_function_; }

  void Bailout(const char* reason);
  void PrintGraph() const;

 private:
  const ParsedFunction& parsed_function_;
  GrowableArray<BlockEntryInstr*> postorder_block_entries_;
};


#define DEFINE_VISIT(type, name) virtual void Visit##type(type* node);

class TestGraphVisitor;

// Translate an AstNode to a control-flow graph fragment for its effects
// (e.g., a statement or an expression in an effect context).  Implements a
// function from an AstNode and next temporary index to a graph fragment
// with a single entry and at most one exit.  The fragment is represented by
// an (entry, exit) pair of Instruction pointers:
//
//   - (NULL, NULL): an empty and open graph fragment
//   - (i0, NULL): a closed graph fragment which has only non-local exits
//   - (i0, i1): an open graph fragment
class EffectGraphVisitor : public AstNodeVisitor {
 public:
  EffectGraphVisitor(FlowGraphBuilder* owner, intptr_t temp_index)
      : owner_(owner),
        temp_index_(temp_index),
        entry_(NULL),
        exit_(NULL) { }

  NODE_LIST(DEFINE_VISIT)

  FlowGraphBuilder* owner() const { return owner_; }
  intptr_t temp_index() const { return temp_index_; }
  Instruction* entry() const { return entry_; }
  Instruction* exit() const { return exit_; }

  bool is_empty() const { return entry_ == NULL; }
  bool is_open() const { return is_empty() || exit_ != NULL; }

  void Bailout(const char* reason);

  // Append a graph fragment to this graph.  Assumes this graph is open.
  void Append(const EffectGraphVisitor& other_fragment);
  // Append a single instruction.  Assumes this graph is open.
  void AddInstruction(Instruction* instruction);

  // Append a 'diamond' branch and join to this graph, depending on which
  // parts are reachable.  Assumes this graph is open.
  void Join(const TestGraphVisitor& test_fragment,
            const EffectGraphVisitor& true_fragment,
            const EffectGraphVisitor& false_fragment);

  // Append a 'while loop' test and back edge to this graph, depending on
  // which parts are reachable.  Afterward, the graph exit is the false
  // successor of the loop condition.
  void TieLoop(const TestGraphVisitor& test_fragment,
               const EffectGraphVisitor& body_fragment);

 protected:
  // Implement the core part of the translation of expression node types.
  AssertAssignableComp* TranslateAssignable(const AssignableNode& node);
  InstanceCallComp* TranslateBinaryOp(const BinaryOpNode& node);
  InstanceCallComp* TranslateUnaryOp(const UnaryOpNode& node);
  InstanceCallComp* TranslateComparison(const ComparisonNode& node);
  StoreLocalComp* TranslateStoreLocal(const StoreLocalNode& node);
  StaticCallComp* TranslateStaticCall(const StaticCallNode& node);

  void CloseFragment() { exit_ = NULL; }
  intptr_t AllocateTempIndex() { return temp_index_++; }

 private:
  // Helper to append a Do instruction to the graph.
  void DoComputation(Computation* computation) {
    AddInstruction(new DoInstr(computation));
  }

  // Shared global state.
  FlowGraphBuilder* owner_;

  // Input parameters.
  intptr_t temp_index_;

  // Output parameters.
  Instruction* entry_;
  Instruction* exit_;
};


// Translate an AstNode to a control-flow graph fragment for both its effects
// and value (e.g., for an expression in a value context).  Implements a
// function from an AstNode and next temporary index to a graph fragment (as
// in the EffectGraphVisitor), a next temporary index, and an intermediate
// language Value.
class ValueGraphVisitor : public EffectGraphVisitor {
 public:
  ValueGraphVisitor(FlowGraphBuilder* owner, intptr_t temp_index)
      : EffectGraphVisitor(owner, temp_index), value_(NULL) { }

  NODE_LIST(DEFINE_VISIT)

  Value* value() const { return value_; }

 private:
  // Helper to set the output state to return a Value.
  void ReturnValue(Value* value) { value_ = value; }

  // Helper to append a Bind instruction to the graph and return its
  // temporary value (i.e., set the output parameters).
  void ReturnValueOf(Computation* computation) {
    AddInstruction(new BindInstr(temp_index(), computation));
    value_ = new TempValue(AllocateTempIndex());
  }

  // Output parameters.
  Value* value_;
};


// Translate an AstNode to a control-flow graph fragment for both its
// effects and true/false control flow (e.g., for an expression in a test
// context).  The resulting graph is always closed (even if it is empty)
// Successor control flow is explicitly set by a pair of pointers to
// TargetEntryInstr*.
//
// To distinguish between the graphs with only nonlocal exits and graphs
// with both true and false exits, there are a pair of TargetEntryInstr**:
//
//   - Both NULL: only non-local exits, truly closed
//   - Neither NULL: true and false successors at the given addresses
//
// We expect that AstNode in test contexts either have only nonlocal exits
// or else control flow has both true and false successors.
class TestGraphVisitor : public EffectGraphVisitor {
 public:
  TestGraphVisitor(FlowGraphBuilder* owner, intptr_t temp_index)
      : EffectGraphVisitor(owner, temp_index),
        true_successor_address_(NULL),
        false_successor_address_(NULL) {
  }

  NODE_LIST(DEFINE_VISIT)

  bool can_be_true() const {
    // Either both successors are set or neither is set.
    ASSERT((true_successor_address_ == NULL) ==
           (false_successor_address_ == NULL));
    return true_successor_address_ != NULL;
  }
  bool can_be_false() const {
    // Either both successors are set or neither is set.
    ASSERT((true_successor_address_ == NULL) ==
           (false_successor_address_ == NULL));
    return false_successor_address_ != NULL;
  }

  TargetEntryInstr** true_successor_address() const {
    ASSERT(can_be_true());
    return true_successor_address_;
  }
  TargetEntryInstr** false_successor_address() const {
    ASSERT(can_be_false());
    return false_successor_address_;
  }

 private:
  // Construct and concatenate a Branch instruction to this graph fragment.
  // Closes the fragment and sets the output parameters.
  void BranchOnValue(Value* value);

  // Helper to bind a computation and branch on its value.
  void BranchOnValueOf(Computation* computation) {
    AddInstruction(new BindInstr(temp_index(), computation));
    BranchOnValue(new TempValue(temp_index()));
  }

  // Output parameters.
  TargetEntryInstr** true_successor_address_;
  TargetEntryInstr** false_successor_address_;
};

#undef DEFINE_VISIT


}  // namespace dart

#endif  // VM_FLOW_GRAPH_BUILDER_H_
