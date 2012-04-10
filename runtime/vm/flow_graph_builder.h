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

  void BuildGraph();

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

  void AddCatchEntry(intptr_t try_index, Instruction* entry);

 private:
  void ComputeDominators(GrowableArray<BlockEntryInstr*>* preorder,
                         GrowableArray<intptr_t>* parent);
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
  GrowableArray<Instruction*> catch_entries_;

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
  // Helpers for translating parts of the AST.
  void TranslateArgumentList(const ArgumentListNode& node,
                             intptr_t next_temp_index,
                             ZoneGrowableArray<Value*>* values);

  // Build the load part of a instance field increment.  Translates the
  // receiver and loads the value.  The receiver will be named with
  // start_index, the temporary index of the value is returned (always
  // start_index+1).
  int BuildIncrOpFieldLoad(IncrOpInstanceFieldNode* node, intptr_t start_index);

  // Build the load part of an indexed increment.  Translates the receiver
  // and index and loads the value.  The receiver will be named with
  // start_index, the index with start_index+1, and the temporary index of
  // the value is returned (always start_index+2).
  int BuildIncrOpIndexedLoad(IncrOpIndexedNode* node, intptr_t start_index);

  // Build the increment part of an increment operation (add or subtract 1).
  // The original value is expected to be named with start_index-1, and the
  // result will be named with start_index.
  void BuildIncrOpIncrement(Token::Kind kind,
                            intptr_t node_id,
                            intptr_t token_index,
                            intptr_t start_index);

  // Creates an instantiated type argument vector used in preparation of a
  // factory call.
  // May be called only if allocating an object of a parameterized class.
  Value* BuildFactoryTypeArguments(ConstructorCallNode* node,
                                   intptr_t start_index);

  // Creates a possibly uninstantiated type argument vector and the type
  // argument vector of the instantiator (two values in 'args') used in
  // preparation of a constructor call.
  // May be called only if allocating an object of a parameterized class.
  void BuildConstructorTypeArguments(ConstructorCallNode* node,
                                     intptr_t start_index,
                                     ZoneGrowableArray<Value*>* args);

  // Returns the value of the type arguments of the instantiator.
  Value* BuildInstantiatorTypeArguments(intptr_t token_index,
                                        intptr_t start_index);

  bool MustSaveRestoreContext(SequenceNode* node) const;

  // Moves parent context into the context register.
  void UnchainContext();

  void CloseFragment() { exit_ = NULL; }
  intptr_t AllocateTempIndex() { return temp_index_++; }

  virtual void CompiletimeStringInterpolation(const Function& interpol_func,
                                              const Array& literals);

  TempVal* BuildObjectAllocation(ConstructorCallNode* node,
                                 int start_index);
  void BuildConstructorCall(ConstructorCallNode* node,
                            int start_index,
                            Value* alloc_value);

  void BuildStoreContext(const LocalVariable& variable, intptr_t start_index);
  void BuildLoadContext(const LocalVariable& variable, intptr_t start_index);

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
  virtual void VisitIncrOpLocalNode(IncrOpLocalNode* node);
  virtual void VisitIncrOpInstanceFieldNode(IncrOpInstanceFieldNode* node);
  virtual void VisitIncrOpIndexedNode(IncrOpIndexedNode* node);
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
  virtual void ReturnValue(Value* value) { value_ = value; }

  // Specify a computation as the final result.  Adds a Bind instruction to
  // the graph and returns its temporary value (i.e., set the output
  // parameters).
  virtual void ReturnComputation(Computation* computation) {
    AddInstruction(new BindInstr(temp_index(), computation));
    value_ = new TempVal(AllocateTempIndex());
  }

  virtual void CompiletimeStringInterpolation(const Function& interpol_func,
                                              const Array& literals);
};


// Translate an AstNode to a control-flow graph fragment for both its effects
// and value as an outgoing argument.  Implements a function from an AstNode
// and next temporary index to a graph fragment (as in the
// EffectGraphBuilder), an updated temporary index, and an intermediate
// language Value.
class ArgumentGraphVisitor : public ValueGraphVisitor {
 public:
  ArgumentGraphVisitor(FlowGraphBuilder* owner, intptr_t temp_index)
      : ValueGraphVisitor(owner, temp_index) { }

 private:
  // Override the returning of constants to ensure they are materialized.
  virtual void ReturnValue(Value* value);
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
class TestGraphVisitor : public ValueGraphVisitor {
 public:
  TestGraphVisitor(FlowGraphBuilder* owner, intptr_t temp_index)
      : ValueGraphVisitor(owner, temp_index),
        true_successor_address_(NULL),
        false_successor_address_(NULL) {
  }

  // Visit functions overridden by this class.
  virtual void VisitLiteralNode(LiteralNode* node);
  virtual void VisitLoadLocalNode(LoadLocalNode* node);

  TargetEntryInstr** true_successor_address() const {
    ASSERT(true_successor_address_ != NULL);
    return true_successor_address_;
  }
  TargetEntryInstr** false_successor_address() const {
    ASSERT(false_successor_address_ != NULL);
    return false_successor_address_;
  }

 private:
  // Construct and concatenate a Branch instruction to this graph fragment.
  // Closes the fragment and sets the output parameters.
  virtual void ReturnValue(Value* value);

  // Specify a computation as the final result.  Adds a Bind instruction to
  // the graph and branches on its value.
  virtual void ReturnComputation(Computation* computation) {
    AddInstruction(new BindInstr(temp_index(), computation));
    ReturnValue(new TempVal(temp_index()));
  }

  // Output parameters.
  TargetEntryInstr** true_successor_address_;
  TargetEntryInstr** false_successor_address_;
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_BUILDER_H_
