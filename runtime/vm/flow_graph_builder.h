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

class FlowGraph;
class Instruction;
class ParsedFunction;

// An class to collect the exits from an inlined function during graph
// construction so they can be plugged into the caller's flow graph.
class InlineExitCollector: public ZoneAllocated {
 public:
  InlineExitCollector(FlowGraph* caller_graph, Definition* call)
      : caller_graph_(caller_graph), call_(call), exits_(4) { }

  void AddExit(ReturnInstr* exit);

  // Before replacing a call with a graph, the outer environment needs to be
  // attached to each instruction in the callee graph and the caller graph
  // needs to have its block and instruction ID state updated.
  void PrepareGraphs(FlowGraph* callee_graph);

  // Inline a graph at a call site.
  //
  // Assumes the callee is in SSA with a correct dominator tree and use
  // lists.
  //
  // After inlining the caller graph will have correctly adjusted the use
  // lists.  The block orders will need to be recomputed.
  void ReplaceCall(TargetEntryInstr* callee_entry);

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

  Value* ValueAt(intptr_t i) const {
    return ReturnAt(i)->value();
  }

  ReturnInstr* ReturnAt(intptr_t i) const {
    return exits_[i].exit_return;
  }

  static int LowestBlockIdFirst(const Data* a, const Data* b);
  void SortExits();

  Definition* JoinReturns(BlockEntryInstr** exit_block,
                          Instruction** last_instruction);

  FlowGraph* caller_graph_;
  Definition* call_;
  GrowableArray<Data> exits_;
};


// Build a flow graph from a parsed function's AST.
class FlowGraphBuilder: public ValueObject {
 public:
  // The inlining context is NULL if not inlining.
  FlowGraphBuilder(const ParsedFunction& parsed_function,
                   InlineExitCollector* exit_collector);

  FlowGraph* BuildGraph();

  const ParsedFunction& parsed_function() const { return parsed_function_; }

  void Bailout(const char* reason);

  intptr_t AllocateBlockId() { return ++last_used_block_id_; }
  void SetInitialBlockId(intptr_t id) { last_used_block_id_ = id; }

  void set_context_level(intptr_t value) { context_level_ = value; }
  intptr_t context_level() const { return context_level_; }

  // Each try in this function gets its own try index.
  intptr_t AllocateTryIndex() { return ++last_used_try_index_; }

  // Manage the currently active try index.
  void set_try_index(intptr_t value) { try_index_ = value; }
  intptr_t try_index() const { return try_index_; }

  void AddCatchEntry(CatchBlockEntryInstr* entry);

  intptr_t num_copied_params() const {
    return num_copied_params_;
  }
  intptr_t num_non_copied_params() const {
    return num_non_copied_params_;
  }
  intptr_t num_stack_locals() const {
    return num_stack_locals_;
  }

  bool IsInlining() const { return (exit_collector_ != NULL); }
  InlineExitCollector* exit_collector() const { return exit_collector_; }

 private:
  intptr_t parameter_count() const {
    return num_copied_params_ + num_non_copied_params_;
  }
  intptr_t variable_count() const {
    return parameter_count() + num_stack_locals_;
  }

  const ParsedFunction& parsed_function_;

  const intptr_t num_copied_params_;
  const intptr_t num_non_copied_params_;
  const intptr_t num_stack_locals_;  // Does not include any parameters.
  InlineExitCollector* const exit_collector_;

  intptr_t last_used_block_id_;
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
  EffectGraphVisitor(FlowGraphBuilder* owner,
                     intptr_t temp_index)
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
  void InlineBailout(const char* reason);

  // Append a graph fragment to this graph.  Assumes this graph is open.
  void Append(const EffectGraphVisitor& other_fragment);
  // Append a definition that can have uses.  Assumes this graph is open.
  Value* Bind(Definition* definition);
  // Append a computation with no uses.  Assumes this graph is open.
  void Do(Definition* definition);
  // Append a single (non-Definition, non-Entry) instruction.  Assumes this
  // graph is open.
  void AddInstruction(Instruction* instruction);
  // Append a Goto (unconditional control flow) instruction and close
  // the graph fragment.  Assumes this graph fragment is open.
  void Goto(JoinEntryInstr* join);

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

  // Wraps a value in a push-argument instruction and adds the result to the
  // graph.
  PushArgumentInstr* PushArgument(Value* value);

  // This implementation shares state among visitors by using the builder.
  // The implementation is incorrect if a visitor that hits a return is not
  // actually added to the graph.
  void AddReturnExit(intptr_t token_pos, Value* value);

 protected:
  Definition* BuildStoreTemp(const LocalVariable& local, Value* value);
  Definition* BuildStoreExprTemp(Value* value);
  Definition* BuildLoadExprTemp();

  Definition* BuildStoreLocal(const LocalVariable& local,
                              Value* value,
                              bool result_is_needed);
  Definition* BuildLoadLocal(const LocalVariable& local);

  void HandleStoreLocal(StoreLocalNode* node, bool result_is_needed);

  // Helpers for translating parts of the AST.
  void TranslateArgumentList(const ArgumentListNode& node,
                             ZoneGrowableArray<Value*>* values);
  void BuildPushArguments(const ArgumentListNode& node,
                          ZoneGrowableArray<PushArgumentInstr*>* values);

  // Creates an instantiated type argument vector used in preparation of an
  // allocation call.
  // May be called only if allocating an object of a parameterized class.
  Value* BuildInstantiatedTypeArguments(
      intptr_t token_pos,
      const AbstractTypeArguments& type_arguments);

  // Creates a possibly uninstantiated type argument vector and the type
  // argument vector of the instantiator used in
  // preparation of a constructor call.
  // May be called only if allocating an object of a parameterized class.
  void BuildConstructorTypeArguments(
      ConstructorCallNode* node,
      Value** type_arguments,
      Value** instantiator,
      ZoneGrowableArray<PushArgumentInstr*>* call_arguments);

  void BuildTypecheckPushArguments(
      intptr_t token_pos,
      PushArgumentInstr** push_instantiator,
      PushArgumentInstr** push_instantiator_type_arguments);
  void BuildTypecheckArguments(intptr_t token_pos,
                               Value** instantiator,
                               Value** instantiator_type_arguments);
  Value* BuildInstantiator();
  Value* BuildInstantiatorTypeArguments(intptr_t token_pos,
                                        Value* instantiator);

  // Perform a type check on the given value.
  AssertAssignableInstr* BuildAssertAssignable(intptr_t token_pos,
                                               Value* value,
                                               const AbstractType& dst_type,
                                               const String& dst_name);

  // Perform a type check on the given value and return it.
  Value* BuildAssignableValue(intptr_t token_pos,
                              Value* value,
                              const AbstractType& dst_type,
                              const String& dst_name);

  static const bool kResultNeeded = true;
  static const bool kResultNotNeeded = false;

  Definition* BuildStoreIndexedValues(StoreIndexedNode* node,
                                      bool result_is_needed);

  void BuildInstanceSetterArguments(
      InstanceSetterNode* node,
      ZoneGrowableArray<PushArgumentInstr*>* arguments,
      bool result_is_needed);

  virtual void BuildTypeTest(ComparisonNode* node);
  virtual void BuildTypeCast(ComparisonNode* node);

  bool MustSaveRestoreContext(SequenceNode* node) const;

  // Moves parent context into the context register.
  void UnchainContext();

  void CloseFragment() { exit_ = NULL; }
  intptr_t AllocateTempIndex() { return temp_index_++; }
  void DeallocateTempIndex(intptr_t n) {
    ASSERT(temp_index_ >= n);
    temp_index_ -= n;
  }

  Value* BuildObjectAllocation(ConstructorCallNode* node);
  void BuildConstructorCall(ConstructorCallNode* node,
                            PushArgumentInstr* alloc_value);

  void BuildStoreContext(const LocalVariable& variable);
  void BuildLoadContext(const LocalVariable& variable);

  void BuildThrowNode(ThrowNode* node);

  StaticCallInstr* BuildStaticNoSuchMethodCall(
      const Class& target_class,
      AstNode* receiver,
      const String& method_name,
      ArgumentListNode* method_arguments);

  StaticCallInstr* BuildThrowNoSuchMethodError(intptr_t token_pos,
                                               const Class& function_class,
                                               const String& function_name,
                                               int invocation_type);

  void BuildStaticSetter(StaticSetterNode* node, bool result_is_needed);
  Definition* BuildStoreStaticField(StoreStaticFieldNode* node,
                                    bool result_is_needed);

  ClosureCallInstr* BuildClosureCall(ClosureCallNode* node);

  Value* BuildNullValue();

 private:
  // Specify a definition of the final result.  Adds the definition to
  // the graph, but normally overridden in subclasses.
  virtual void ReturnDefinition(Definition* definition) {
    Do(definition);
  }

 protected:
  // Returns true if the run-time type check can be eliminated.
  bool CanSkipTypeCheck(intptr_t token_pos,
                        Value* value,
                        const AbstractType& dst_type,
                        const String& dst_name);

 private:
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
  ValueGraphVisitor(FlowGraphBuilder* owner,
                    intptr_t temp_index)
      : EffectGraphVisitor(owner, temp_index), value_(NULL) { }

  // Visit functions overridden by this class.
  virtual void VisitLiteralNode(LiteralNode* node);
  virtual void VisitAssignableNode(AssignableNode* node);
  virtual void VisitConstructorCallNode(ConstructorCallNode* node);
  virtual void VisitBinaryOpNode(BinaryOpNode* node);
  virtual void VisitConditionalExprNode(ConditionalExprNode* node);
  virtual void VisitLoadLocalNode(LoadLocalNode* node);
  virtual void VisitStoreLocalNode(StoreLocalNode* node);
  virtual void VisitStoreIndexedNode(StoreIndexedNode* node);
  virtual void VisitStoreInstanceFieldNode(StoreInstanceFieldNode* node);
  virtual void VisitInstanceSetterNode(InstanceSetterNode* node);
  virtual void VisitThrowNode(ThrowNode* node);
  virtual void VisitClosureCallNode(ClosureCallNode* node);
  virtual void VisitStaticSetterNode(StaticSetterNode* node);
  virtual void VisitStoreStaticFieldNode(StoreStaticFieldNode* node);
  virtual void VisitTypeNode(TypeNode* node);

  Value* value() const { return value_; }

 protected:
  // Output parameters.
  Value* value_;

 private:
  // Helper to set the output state to return a Value.
  virtual void ReturnValue(Value* value) { value_ = value; }

  // Specify a definition of the final result.  Adds the definition to
  // the graph and returns a use of it (i.e., set the visitor's output
  // parameters).
  virtual void ReturnDefinition(Definition* definition) {
    ReturnValue(Bind(definition));
  }

  virtual void BuildTypeTest(ComparisonNode* node);
  virtual void BuildTypeCast(ComparisonNode* node);
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
// The cis and token_pos are used in checked mode to verify that the
// condition of the test is of type bool.
class TestGraphVisitor : public ValueGraphVisitor {
 public:
  TestGraphVisitor(FlowGraphBuilder* owner,
                   intptr_t temp_index,
                   intptr_t condition_token_pos)
      : ValueGraphVisitor(owner, temp_index),
        true_successor_addresses_(1),
        false_successor_addresses_(1),
        condition_token_pos_(condition_token_pos) { }

  void IfFalseGoto(JoinEntryInstr* join) const;
  void IfTrueGoto(JoinEntryInstr* join) const;

  BlockEntryInstr* CreateTrueSuccessor() const;
  BlockEntryInstr* CreateFalseSuccessor() const;

  virtual void VisitBinaryOpNode(BinaryOpNode* node);

  intptr_t condition_token_pos() const { return condition_token_pos_; }

 private:
  // Construct and concatenate a Branch instruction to this graph fragment.
  // Closes the fragment and sets the output parameters.
  virtual void ReturnValue(Value* value);

  // Either merges the definition into a BranchInstr (Comparison, BooleanNegate)
  // or adds the definition to the graph and returns a use of its value.
  virtual void ReturnDefinition(Definition* definition);

  void MergeBranchWithComparison(ComparisonInstr* comp);
  void MergeBranchWithNegate(BooleanNegateInstr* comp);

  BlockEntryInstr* CreateSuccessorFor(
    const GrowableArray<TargetEntryInstr**>& branches) const;

  void ConnectBranchesTo(
    const GrowableArray<TargetEntryInstr**>& branches,
    JoinEntryInstr* join) const;

  // Output parameters.
  GrowableArray<TargetEntryInstr**> true_successor_addresses_;
  GrowableArray<TargetEntryInstr**> false_successor_addresses_;

  intptr_t condition_token_pos_;
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_BUILDER_H_
