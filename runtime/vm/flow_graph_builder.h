// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_BUILDER_H_
#define VM_FLOW_GRAPH_BUILDER_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/allocation.h"
#include "vm/ast.h"
#include "vm/flow_graph.h"
#include "vm/growable_array.h"
#include "vm/intermediate_language.h"
#include "vm/raw_object.h"

namespace dart {

class AbstractType;
class Array;
class Class;
class Field;
class LocalVariable;
class ParsedFunction;
class String;
class TypeArguments;

class NestedStatement;
class TestGraphVisitor;

// List of recognized list factories:
// (factory-name-symbol, result-cid, fingerprint).
// TODO(srdjan): Store the values in the snapshot instead.
#define RECOGNIZED_LIST_FACTORY_LIST(V)                                        \
  V(_ListFactory, kArrayCid, 335347617)                                        \
  V(_GrowableListWithData, kGrowableObjectArrayCid, 536409567)                 \
  V(_GrowableListFactory, kGrowableObjectArrayCid, 619206641)                  \
  V(_Int8ArrayFactory, kTypedDataInt8ArrayCid, 1234236264)                     \
  V(_Uint8ArrayFactory, kTypedDataUint8ArrayCid, 89436950)                     \
  V(_Uint8ClampedArrayFactory, kTypedDataUint8ClampedArrayCid, 2114336727)     \
  V(_Int16ArrayFactory, kTypedDataInt16ArrayCid, 779429598)                    \
  V(_Uint16ArrayFactory, kTypedDataUint16ArrayCid, 351653952)                  \
  V(_Int32ArrayFactory, kTypedDataInt32ArrayCid, 1909366715)                   \
  V(_Uint32ArrayFactory, kTypedDataUint32ArrayCid, 32690110)                   \
  V(_Int64ArrayFactory, kTypedDataInt64ArrayCid, 1987760123)                   \
  V(_Uint64ArrayFactory, kTypedDataUint64ArrayCid, 1205087814)                 \
  V(_Float64ArrayFactory, kTypedDataFloat64ArrayCid, 77468920)                 \
  V(_Float32ArrayFactory, kTypedDataFloat32ArrayCid, 1988570712)               \
  V(_Float32x4ArrayFactory, kTypedDataFloat32x4ArrayCid, 953075137)            \


// Class that recognizes factories and returns corresponding result cid.
class FactoryRecognizer : public AllStatic {
 public:
  // Return kDynamicCid if factory is not recognized.
  static intptr_t ResultCid(const Function& factory) {
    ASSERT(factory.IsFactory());
    const Class& function_class = Class::Handle(factory.Owner());
    const Library& lib = Library::Handle(function_class.library());
    ASSERT((lib.raw() == Library::CoreLibrary()) ||
        (lib.raw() == Library::TypedDataLibrary()));
    const String& factory_name = String::Handle(factory.name());
#define RECOGNIZE_FACTORY(test_factory_symbol, cid, fp)                        \
    if (String::EqualsIgnoringPrivateKey(                                      \
        factory_name, Symbols::test_factory_symbol())) {                       \
      ASSERT(factory.CheckSourceFingerprint(fp));                              \
      return cid;                                                              \
    }                                                                          \

RECOGNIZED_LIST_FACTORY_LIST(RECOGNIZE_FACTORY);
#undef RECOGNIZE_FACTORY

    return kDynamicCid;
  }
};


// A class to collect the exits from an inlined function during graph
// construction so they can be plugged into the caller's flow graph.
class InlineExitCollector: public ZoneAllocated {
 public:
  InlineExitCollector(FlowGraph* caller_graph, Definition* call)
      : caller_graph_(caller_graph), call_(call), exits_(4) { }

  void AddExit(ReturnInstr* exit);

  void Union(const InlineExitCollector* other);

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

  Isolate* isolate() const { return caller_graph_->isolate(); }

  FlowGraph* caller_graph_;
  Definition* call_;
  GrowableArray<Data> exits_;
};


// Build a flow graph from a parsed function's AST.
class FlowGraphBuilder: public ValueObject {
 public:
  // The inlining context is NULL if not inlining.  The osr_id is the deopt
  // id of the OSR entry or Isolate::kNoDeoptId if not compiling for OSR.
  FlowGraphBuilder(ParsedFunction* parsed_function,
                   const ZoneGrowableArray<const ICData*>& ic_data_array,
                   InlineExitCollector* exit_collector,
                   intptr_t osr_id);

  FlowGraph* BuildGraph();

  ParsedFunction* parsed_function() const { return parsed_function_; }
  const ZoneGrowableArray<const ICData*>& ic_data_array() const {
    return ic_data_array_;
  }

  // Return true if a Javascript compatibility warning should be emitted at
  // runtime for this type test.
  bool WarnOnJSIntegralNumTypeTest(AstNode* node,
                                   const AbstractType& type) const;

  void Bailout(const char* reason) const;

  intptr_t AllocateBlockId() { return ++last_used_block_id_; }
  void SetInitialBlockId(intptr_t id) { last_used_block_id_ = id; }

  intptr_t context_level() const;

  void IncrementLoopDepth() { ++loop_depth_; }
  void DecrementLoopDepth() { --loop_depth_; }
  intptr_t loop_depth() const { return loop_depth_; }

  // Manage the currently active try index.
  void set_try_index(intptr_t value) { try_index_ = value; }
  intptr_t try_index() const { return try_index_; }

  // Manage the currently active catch-handler try index.
  void set_catch_try_index(intptr_t value) { catch_try_index_ = value; }
  intptr_t catch_try_index() const { return catch_try_index_; }

  intptr_t next_await_counter() { return jump_count_++; }

  ZoneGrowableArray<intptr_t>* await_levels() const { return await_levels_; }
  ZoneGrowableArray<JoinEntryInstr*>* await_joins() const {
    return await_joins_;
  }

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

  ZoneGrowableArray<const Field*>* guarded_fields() const {
    return parsed_function_->guarded_fields();
  }

  ZoneGrowableArray<const LibraryPrefix*>* deferred_prefixes() const {
    return parsed_function_->deferred_prefixes();
  }

  intptr_t temp_count() const { return temp_count_; }
  intptr_t AllocateTemp() { return temp_count_++; }
  void DeallocateTemps(intptr_t count) {
    ASSERT(temp_count_ >= count);
    temp_count_ -= count;
  }

  intptr_t args_pushed() const { return args_pushed_; }
  void add_args_pushed(intptr_t n) { args_pushed_ += n; }

  NestedStatement* nesting_stack() const { return nesting_stack_; }

  // When compiling for OSR, remove blocks that are not reachable from the
  // OSR entry point.
  void PruneUnreachable();

  // Returns address where the constant 'value' is stored or 0 if not found.
  static uword FindDoubleConstant(double value);

  Isolate* isolate() const { return parsed_function()->isolate(); }

 private:
  friend class NestedStatement;  // Explicit access to nesting_stack_.
  friend class Intrinsifier;

  intptr_t parameter_count() const {
    return num_copied_params_ + num_non_copied_params_;
  }
  intptr_t variable_count() const {
    return parameter_count() + num_stack_locals_;
  }

  ParsedFunction* parsed_function_;
  const ZoneGrowableArray<const ICData*>& ic_data_array_;

  const intptr_t num_copied_params_;
  const intptr_t num_non_copied_params_;
  const intptr_t num_stack_locals_;  // Does not include any parameters.
  InlineExitCollector* const exit_collector_;

  intptr_t last_used_block_id_;
  intptr_t try_index_;
  intptr_t catch_try_index_;
  intptr_t loop_depth_;
  GraphEntryInstr* graph_entry_;

  // The expression stack height.
  intptr_t temp_count_;

  // Outgoing argument stack height.
  intptr_t args_pushed_;

  // A stack of enclosing nested statements.
  NestedStatement* nesting_stack_;

  // The deopt id of the OSR entry or Isolate::kNoDeoptId if not compiling
  // for OSR.
  const intptr_t osr_id_;

  intptr_t jump_count_;
  ZoneGrowableArray<JoinEntryInstr*>* await_joins_;
  ZoneGrowableArray<intptr_t>* await_levels_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(FlowGraphBuilder);
};


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
  explicit EffectGraphVisitor(FlowGraphBuilder* owner)
      : owner_(owner),
        entry_(NULL),
        exit_(NULL) { }

#define DECLARE_VISIT(BaseName)                                                \
  virtual void Visit##BaseName##Node(BaseName##Node* node);

  FOR_EACH_NODE(DECLARE_VISIT)
#undef DECLARE_VISIT

  FlowGraphBuilder* owner() const { return owner_; }
  Instruction* entry() const { return entry_; }
  Instruction* exit() const { return exit_; }

  bool is_empty() const { return entry_ == NULL; }
  bool is_open() const { return is_empty() || exit_ != NULL; }

  void Bailout(const char* reason) const;
  void InlineBailout(const char* reason) const;

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
  void TieLoop(intptr_t token_pos,
               const TestGraphVisitor& test_fragment,
               const EffectGraphVisitor& body_fragment,
               const EffectGraphVisitor& test_preamble_fragment);

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

  Definition* BuildStoreLocal(const LocalVariable& local, Value* value);
  Definition* BuildLoadLocal(const LocalVariable& local);
  LoadLocalInstr* BuildLoadThisVar(LocalScope* scope);

  // Helpers for translating parts of the AST.
  void BuildPushArguments(const ArgumentListNode& node,
                          ZoneGrowableArray<PushArgumentInstr*>* values);

  // Creates an instantiated type argument vector used in preparation of an
  // allocation call.
  // May be called only if allocating an object of a parameterized class.
  Value* BuildInstantiatedTypeArguments(
      intptr_t token_pos,
      const TypeArguments& type_arguments);

  void BuildTypecheckPushArguments(
      intptr_t token_pos,
      PushArgumentInstr** push_instantiator,
      PushArgumentInstr** push_instantiator_type_arguments);
  void BuildTypecheckArguments(intptr_t token_pos,
                               Value** instantiator,
                               Value** instantiator_type_arguments);
  Value* BuildInstantiator(const Class& instantiator_class);
  Value* BuildInstantiatorTypeArguments(intptr_t token_pos,
                                        const Class& instantiator_class,
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

  StrictCompareInstr* BuildStrictCompare(AstNode* left,
                                         AstNode* right,
                                         Token::Kind kind,
                                         intptr_t token_pos);

  virtual void BuildTypeTest(ComparisonNode* node);
  virtual void BuildTypeCast(ComparisonNode* node);

  bool HasContextScope() const;

  // Moves the nth parent context into the context register.
  void UnchainContexts(intptr_t n);

  void CloseFragment() { exit_ = NULL; }

  // Returns a local variable index for a temporary local that is
  // on top of the current expression stack.
  intptr_t GetCurrentTempLocalIndex() const;

  Value* BuildObjectAllocation(ConstructorCallNode* node);
  void BuildConstructorCall(ConstructorCallNode* node,
                            PushArgumentInstr* alloc_value);

  void BuildSaveContext(const LocalVariable& variable);
  void BuildRestoreContext(const LocalVariable& variable);

  Definition* BuildStoreContext(Value* value);
  Definition* BuildCurrentContext();

  void BuildThrowNode(ThrowNode* node);

  StaticCallInstr* BuildStaticNoSuchMethodCall(
      const Class& target_class,
      AstNode* receiver,
      const String& method_name,
      ArgumentListNode* method_arguments,
      bool save_last_arg,
      bool is_super_invocation);

  StaticCallInstr* BuildThrowNoSuchMethodError(
      intptr_t token_pos,
      const Class& function_class,
      const String& function_name,
      ArgumentListNode* function_arguments,
      int invocation_type);

  void BuildStaticSetter(StaticSetterNode* node, bool result_is_needed);
  Definition* BuildStoreStaticField(StoreStaticFieldNode* node,
                                    bool result_is_needed);

  void BuildClosureCall(ClosureCallNode* node, bool result_needed);

  Value* BuildNullValue();

  // Returns true if the run-time type check can be eliminated.
  bool CanSkipTypeCheck(intptr_t token_pos,
                        Value* value,
                        const AbstractType& dst_type,
                        const String& dst_name);

  // Helpers for allocating and deallocating temporary locals on top of the
  // expression stack.
  LocalVariable* EnterTempLocalScope(Value* value);
  Definition* ExitTempLocalScope(LocalVariable* var);

  void BuildLetTempExpressions(LetNode* node);

  void BuildAwaitJump(LocalVariable* old_context,
                      LocalVariable* continuation_result,
                      LocalVariable* continuation_error,
                      const intptr_t old_ctx_level,
                      JoinEntryInstr* target);

  Isolate* isolate() const { return owner()->isolate(); }

 private:
  friend class TempLocalScope;  // For ReturnDefinition.

  // Helper to drop the result value.
  virtual void ReturnValue(Value* value) {
    Do(new DropTempsInstr(0, value));
  }

  // Specify a definition of the final result.  Adds the definition to
  // the graph, but normally overridden in subclasses.
  virtual void ReturnDefinition(Definition* definition) {
    // Constants have no effect, do not add them to graph otherwise SSA
    // builder will get confused.
    if (!definition->IsConstant()) {
      Do(definition);
    }
  }

  // Shared global state.
  FlowGraphBuilder* owner_;

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
  explicit ValueGraphVisitor(FlowGraphBuilder* owner)
      : EffectGraphVisitor(owner), value_(NULL) { }

  // Visit functions overridden by this class.
  virtual void VisitAssignableNode(AssignableNode* node);
  virtual void VisitConstructorCallNode(ConstructorCallNode* node);
  virtual void VisitBinaryOpNode(BinaryOpNode* node);
  virtual void VisitConditionalExprNode(ConditionalExprNode* node);
  virtual void VisitLoadLocalNode(LoadLocalNode* node);
  virtual void VisitStoreIndexedNode(StoreIndexedNode* node);
  virtual void VisitInstanceSetterNode(InstanceSetterNode* node);
  virtual void VisitThrowNode(ThrowNode* node);
  virtual void VisitClosureCallNode(ClosureCallNode* node);
  virtual void VisitStaticSetterNode(StaticSetterNode* node);
  virtual void VisitStoreStaticFieldNode(StoreStaticFieldNode* node);
  virtual void VisitTypeNode(TypeNode* node);
  virtual void VisitLetNode(LetNode* node);

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
                   intptr_t condition_token_pos)
      : ValueGraphVisitor(owner),
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
