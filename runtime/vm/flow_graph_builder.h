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
  explicit FlowGraphBuilder(const ParsedFunction& parsed_function);

  void BuildGraph(bool for_optimized);

  const ParsedFunction& parsed_function() const { return parsed_function_; }

  const GrowableArray<BlockEntryInstr*>& postorder_block_entries() const {
    return postorder_block_entries_;
  }

  void Bailout(const char* reason);

  void set_context_level(intptr_t value) { context_level_ = value; }
  intptr_t context_level() const { return context_level_; }

  // Each try in this function gets its own try index.
  intptr_t AllocateTryIndex() { return ++last_used_try_index_; }

  // Manage the currently active try index.
  void set_try_index(intptr_t value) { try_index_ = value; }
  intptr_t try_index() const { return try_index_; }

  void AddCatchEntry(TargetEntryInstr* entry);

 private:
  void ComputeDominators(GrowableArray<BlockEntryInstr*>* preorder,
                         GrowableArray<intptr_t>* parent,
                         GrowableArray<BitVector*>* dominance_frontier);

  void CompressPath(intptr_t start_index,
                    intptr_t current_index,
                    GrowableArray<intptr_t>* parent,
                    GrowableArray<intptr_t>* label);

  const ParsedFunction& parsed_function_;
  GrowableArray<BlockEntryInstr*> preorder_block_entries_;
  GrowableArray<BlockEntryInstr*> postorder_block_entries_;
  intptr_t context_level_;
  intptr_t last_used_try_index_;
  intptr_t try_index_;
  GraphEntryInstr* graph_entry_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(FlowGraphBuilder);
};


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

#define DEFINE_VISIT(type, name) virtual void Visit##type(type* node);
  NODE_LIST(DEFINE_VISIT)
#undef DEFINE_VISIT

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
  Computation* BuildStoreLocal(const LocalVariable& local, Value* value);
  Computation* BuildLoadLocal(const LocalVariable& local);

  // Helpers for translating parts of the AST.
  void TranslateArgumentList(const ArgumentListNode& node,
                             ZoneGrowableArray<Value*>* values);

  // Creates an instantiated type argument vector used in preparation of an
  // allocation call.
  // May be called only if allocating an object of a parameterized class.
  Definition* BuildInstantiatedTypeArguments(
      intptr_t token_index,
      const AbstractTypeArguments& type_arguments);

  // Creates a possibly uninstantiated type argument vector and the type
  // argument vector of the instantiator (two values in 'args') used in
  // preparation of a constructor call.
  // May be called only if allocating an object of a parameterized class.
  void BuildConstructorTypeArguments(ConstructorCallNode* node,
                                     ZoneGrowableArray<Value*>* args);

  // Returns the value of the type arguments of the instantiator.
  Value* BuildInstantiatorTypeArguments(intptr_t token_index);

  // Perform a type check on the given value.
  void BuildAssertAssignable(intptr_t token_index,
                             Value* value,
                             const AbstractType& dst_type,
                             const String& dst_name);

  // Perform a type check on the given value and return it.
  Value* BuildAssignableValue(AstNode* value_node,
                              Value* value,
                              const AbstractType& dst_type,
                              const String& dst_name);

  virtual void BuildInstanceOf(ComparisonNode* node);

  bool MustSaveRestoreContext(SequenceNode* node) const;

  // Moves parent context into the context register.
  void UnchainContext();

  void CloseFragment() { exit_ = NULL; }
  intptr_t AllocateTempIndex() { return temp_index_++; }
  void DeallocateTempIndex(intptr_t n) {
    ASSERT(temp_index_ >= n);
    temp_index_ -= n;
  }

  virtual void CompiletimeStringInterpolation(const Function& interpol_func,
                                              const Array& literals);

  Definition* BuildObjectAllocation(ConstructorCallNode* node);
  void BuildConstructorCall(ConstructorCallNode* node, Value* alloc_value);

  void BuildStoreContext(const LocalVariable& variable);
  void BuildLoadContext(const LocalVariable& variable);

  void BuildThrowNode(ThrowNode* node);

 private:
  // Specify a computation as the final result.  Adds a Do instruction to
  // the graph, but normally overridden in subclasses.
  virtual void ReturnComputation(Computation* computation) {
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

  // Visit functions overridden by this class.
  virtual void VisitLiteralNode(LiteralNode* node);
  virtual void VisitAssignableNode(AssignableNode* node);
  virtual void VisitConstructorCallNode(ConstructorCallNode* node);
  virtual void VisitBinaryOpNode(BinaryOpNode* node);
  virtual void VisitConditionalExprNode(ConditionalExprNode* node);
  virtual void VisitLoadLocalNode(LoadLocalNode* node);
  virtual void VisitThrowNode(ThrowNode* node);

  Value* value() const { return value_; }

 protected:
  // Output parameters.
  Value* value_;

 private:
  // Helper to set the output state to return a Value.
  virtual void ReturnValue(Value* value) {
    ASSERT(value->IsUse());
    value_ = value;
  }

  // Specify a computation as the final result.  Adds a Bind instruction to
  // the graph and returns its temporary value (i.e., set the output
  // parameters).
  virtual void ReturnComputation(Computation* computation) {
    BindInstr* defn = new BindInstr(computation);
    AddInstruction(defn);
    ReturnValue(new UseVal(defn));
  }

  virtual void CompiletimeStringInterpolation(const Function& interpol_func,
                                              const Array& literals);

  virtual void BuildInstanceOf(ComparisonNode* node);
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
//
// The cis and token_index are used in checked mode to verify that the
// condition of the test is of type bool.
class TestGraphVisitor : public ValueGraphVisitor {
 public:
  TestGraphVisitor(FlowGraphBuilder* owner,
                   intptr_t temp_index,
                   intptr_t condition_token_index)
      : ValueGraphVisitor(owner, temp_index),
        true_successor_address_(NULL),
        false_successor_address_(NULL),
        condition_token_index_(condition_token_index) {
  }

  TargetEntryInstr** true_successor_address() const {
    ASSERT(true_successor_address_ != NULL);
    return true_successor_address_;
  }
  TargetEntryInstr** false_successor_address() const {
    ASSERT(false_successor_address_ != NULL);
    return false_successor_address_;
  }

  intptr_t condition_token_index() const { return condition_token_index_; }

 private:
  // Construct and concatenate a Branch instruction to this graph fragment.
  // Closes the fragment and sets the output parameters.
  virtual void ReturnValue(Value* value);

  // Output parameters.
  TargetEntryInstr** true_successor_address_;
  TargetEntryInstr** false_successor_address_;

  intptr_t condition_token_index_;
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_BUILDER_H_
