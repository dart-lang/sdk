// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_BASE_FLOW_GRAPH_BUILDER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_BASE_FLOW_GRAPH_BUILDER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <initializer_list>

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/object.h"

namespace dart {

class InlineExitCollector;

namespace kernel {

class BaseFlowGraphBuilder;
class TryCatchBlock;

class Fragment {
 public:
  Instruction* entry = nullptr;
  Instruction* current = nullptr;

  Fragment() {}

  explicit Fragment(Instruction* instruction)
      : entry(instruction), current(instruction) {}

  Fragment(Instruction* entry, Instruction* current)
      : entry(entry), current(current) {}

  bool is_open() const { return entry == nullptr || current != nullptr; }
  bool is_closed() const { return !is_open(); }

  bool is_empty() const { return entry == nullptr && current == nullptr; }

  void Prepend(Instruction* start);

  Fragment& operator+=(const Fragment& other);
  Fragment& operator<<=(Instruction* next);

  Fragment closed();

 private:
  DISALLOW_ALLOCATION();
};

Fragment operator+(const Fragment& first, const Fragment& second);
Fragment operator<<(const Fragment& fragment, Instruction* next);

// IL fragment that performs some sort of test (comparison) and
// has a single entry and multiple true and false exits.
class TestFragment {
 public:
  BlockEntryInstr* CreateTrueSuccessor(BaseFlowGraphBuilder* builder);
  BlockEntryInstr* CreateFalseSuccessor(BaseFlowGraphBuilder* builder);

  void IfTrueGoto(BaseFlowGraphBuilder* builder, JoinEntryInstr* join) {
    ConnectBranchesTo(builder, *true_successor_addresses, join);
  }

  // If negate is true then return negated fragment by flipping
  // true and false successors. Otherwise return this fragment
  // without change.
  TestFragment Negate(bool negate) {
    if (negate) {
      return TestFragment(entry, false_successor_addresses,
                          true_successor_addresses);
    } else {
      return *this;
    }
  }

  typedef ZoneGrowableArray<TargetEntryInstr**> SuccessorAddressArray;

  // Create an empty fragment.
  TestFragment() {}

  // Create a fragment with the given entry and true/false exits.
  TestFragment(Instruction* entry,
               SuccessorAddressArray* true_successor_addresses,
               SuccessorAddressArray* false_successor_addresses)
      : entry(entry),
        true_successor_addresses(true_successor_addresses),
        false_successor_addresses(false_successor_addresses) {}

  // Create a fragment with the given entry and a single branch as an exit.
  TestFragment(Instruction* entry, BranchInstr* branch);

  void ConnectBranchesTo(BaseFlowGraphBuilder* builder,
                         const TestFragment::SuccessorAddressArray& branches,
                         JoinEntryInstr* join);

  BlockEntryInstr* CreateSuccessorFor(
      BaseFlowGraphBuilder* builder,
      const TestFragment::SuccessorAddressArray& branches);

  Instruction* entry = nullptr;
  SuccessorAddressArray* true_successor_addresses = nullptr;
  SuccessorAddressArray* false_successor_addresses = nullptr;
};

// Indicates which form of the unchecked entrypoint we are compiling.
//
// kNone:
//
//   There is no unchecked entrypoint: the unchecked entry is set to NULL in
//   the 'GraphEntryInstr'.
//
// kSeparate:
//
//   The normal and unchecked entrypoint each point to their own versions of
//   the prologue, containing exactly those checks which need to be performed
//   on either side. Both sides jump directly to the body after performing
//   their prologue.
//
// kSharedWithVariable:
//
//   A temporary variable is allocated and initialized to 0 on normal entry
//   and 2 on unchecked entry. Code which should be ommitted on the unchecked
//   entrypoint is made conditional on this variable being equal to 0.
//
enum class UncheckedEntryPointStyle {
  kNone = 0,
  kSeparate = 1,
  kSharedWithVariable = 2,
};

class BaseFlowGraphBuilder {
 public:
  BaseFlowGraphBuilder(
      const ParsedFunction* parsed_function,
      intptr_t last_used_block_id,
      intptr_t osr_id = DeoptId::kNone,
      ZoneGrowableArray<intptr_t>* context_level_array = nullptr,
      InlineExitCollector* exit_collector = nullptr,
      bool inlining_unchecked_entry = false)
      : parsed_function_(parsed_function),
        function_(parsed_function_->function()),
        thread_(Thread::Current()),
        zone_(thread_->zone()),
        osr_id_(osr_id),
        context_level_array_(context_level_array),
        context_depth_(0),
        last_used_block_id_(last_used_block_id),
        current_try_index_(kInvalidTryIndex),
        next_used_try_index_(0),
        stack_(NULL),
        exit_collector_(exit_collector),
        inlining_unchecked_entry_(inlining_unchecked_entry),
        saved_args_desc_array_(
            has_saved_args_desc_array()
                ? Array::ZoneHandle(zone_, function_.saved_args_desc())
                : Object::null_array()) {}

  Fragment LoadField(const Field& field, bool calls_initializer);
  Fragment LoadNativeField(const Slot& native_field,
                           bool calls_initializer = false);
  // Pass true for index_unboxed if indexing into external typed data.
  Fragment LoadIndexed(classid_t class_id,
                       intptr_t index_scale = compiler::target::kWordSize,
                       bool index_unboxed = false);

  Fragment LoadUntagged(intptr_t offset);
  Fragment StoreUntagged(intptr_t offset);
  Fragment ConvertUntaggedToUnboxed(Representation to);
  Fragment ConvertUnboxedToUntagged(Representation from);
  Fragment UnboxSmiToIntptr();
  Fragment FloatToDouble();
  Fragment DoubleToFloat();

  Fragment AddIntptrIntegers();

  void SetTempIndex(Definition* definition);

  Fragment LoadLocal(LocalVariable* variable);
  Fragment StoreLocal(LocalVariable* variable) {
    return StoreLocal(TokenPosition::kNoSource, variable);
  }
  Fragment StoreLocal(TokenPosition position, LocalVariable* variable);
  Fragment StoreLocalRaw(TokenPosition position, LocalVariable* variable);
  Fragment LoadContextAt(int depth);
  Fragment GuardFieldLength(const Field& field, intptr_t deopt_id);
  Fragment GuardFieldClass(const Field& field, intptr_t deopt_id);
  static const Field& MayCloneField(Zone* zone, const Field& field);
  Fragment StoreInstanceField(
      TokenPosition position,
      const Slot& field,
      StoreInstanceFieldInstr::Kind kind =
          StoreInstanceFieldInstr::Kind::kOther,
      StoreBarrierType emit_store_barrier = kEmitStoreBarrier);
  Fragment StoreInstanceField(
      const Field& field,
      StoreInstanceFieldInstr::Kind kind =
          StoreInstanceFieldInstr::Kind::kOther,
      StoreBarrierType emit_store_barrier = kEmitStoreBarrier);
  Fragment StoreInstanceFieldGuarded(const Field& field,
                                     StoreInstanceFieldInstr::Kind kind =
                                         StoreInstanceFieldInstr::Kind::kOther);
  Fragment LoadStaticField(const Field& field, bool calls_initializer);
  Fragment RedefinitionWithType(const AbstractType& type);
  Fragment ReachabilityFence();
  Fragment StoreStaticField(TokenPosition position, const Field& field);
  Fragment StoreIndexed(classid_t class_id);
  // Takes a [class_id] valid for StoreIndexed.
  Fragment StoreIndexedTypedData(classid_t class_id,
                                 intptr_t index_scale,
                                 bool index_unboxed);

  // Sign-extends kUnboxedInt32 and zero-extends kUnboxedUint32.
  Fragment Box(Representation from);

  void Push(Definition* definition);
  Definition* Peek(intptr_t depth = 0);
  Value* Pop();
  Fragment Drop();
  // Drop given number of temps from the stack but preserve top of the stack.
  Fragment DropTempsPreserveTop(intptr_t num_temps_to_drop);
  Fragment MakeTemp();

  // Create a pseudo-local variable for a location on the expression stack.
  // Note: SSA construction currently does not support inserting Phi functions
  // for expression stack locations - only real local variables are supported.
  // This means that you can't use MakeTemporary in a way that would require
  // a Phi in SSA form. For example example below will be miscompiled or
  // will crash debug VM with assertion when building SSA for optimizing
  // compiler:
  //
  //     t = MakeTemporary()
  //     Branch B1 or B2
  //     B1:
  //       StoreLocal(t, v0)
  //       goto B3
  //     B2:
  //       StoreLocal(t, v1)
  //       goto B3
  //     B3:
  //       LoadLocal(t)
  LocalVariable* MakeTemporary(const char* suffix = nullptr);
  Fragment DropTemporary(LocalVariable** temp);

  InputsArray* GetArguments(int count);

  TargetEntryInstr* BuildTargetEntry();
  FunctionEntryInstr* BuildFunctionEntry(GraphEntryInstr* graph_entry);
  JoinEntryInstr* BuildJoinEntry();
  JoinEntryInstr* BuildJoinEntry(intptr_t try_index);
  IndirectEntryInstr* BuildIndirectEntry(intptr_t indirect_id,
                                         intptr_t try_index);

  Fragment StrictCompare(TokenPosition position,
                         Token::Kind kind,
                         bool number_check = false);
  Fragment StrictCompare(Token::Kind kind, bool number_check = false);
  Fragment Goto(JoinEntryInstr* destination);
  Fragment UnboxedIntConstant(int64_t value, Representation representation);
  Fragment IntConstant(int64_t value);
  Fragment Constant(const Object& value);
  Fragment NullConstant();
  Fragment SmiRelationalOp(Token::Kind kind);
  Fragment SmiBinaryOp(Token::Kind op, bool is_truncating = false);
  Fragment BinaryIntegerOp(Token::Kind op,
                           Representation representation,
                           bool is_truncating = false);
  Fragment LoadFpRelativeSlot(intptr_t offset,
                              CompileType result_type,
                              Representation representation = kTagged);
  Fragment StoreFpRelativeSlot(intptr_t offset);
  Fragment BranchIfTrue(TargetEntryInstr** then_entry,
                        TargetEntryInstr** otherwise_entry,
                        bool negate = false);
  Fragment BranchIfNull(TargetEntryInstr** then_entry,
                        TargetEntryInstr** otherwise_entry,
                        bool negate = false);
  Fragment BranchIfEqual(TargetEntryInstr** then_entry,
                         TargetEntryInstr** otherwise_entry,
                         bool negate = false);
  Fragment BranchIfStrictEqual(TargetEntryInstr** then_entry,
                               TargetEntryInstr** otherwise_entry);
  Fragment Return(
      TokenPosition position,
      intptr_t yield_index = PcDescriptorsLayout::kInvalidYieldIndex);
  Fragment CheckStackOverflow(TokenPosition position,
                              intptr_t stack_depth,
                              intptr_t loop_depth);
  Fragment CheckStackOverflowInPrologue(TokenPosition position);
  Fragment MemoryCopy(classid_t src_cid, classid_t dest_cid);
  Fragment TailCall(const Code& code);
  Fragment Utf8Scan();

  intptr_t GetNextDeoptId() {
    intptr_t deopt_id = thread_->compiler_state().GetNextDeoptId();
    if (context_level_array_ != NULL) {
      intptr_t level = context_depth_;
      context_level_array_->Add(deopt_id);
      context_level_array_->Add(level);
    }
    return deopt_id;
  }

  intptr_t AllocateTryIndex() { return next_used_try_index_++; }
  intptr_t CurrentTryIndex() const { return current_try_index_; }
  void SetCurrentTryIndex(intptr_t try_index) {
    current_try_index_ = try_index;
  }

  bool IsCompiledForOsr() { return osr_id_ != DeoptId::kNone; }

  bool IsInlining() const { return exit_collector_ != nullptr; }

  void InlineBailout(const char* reason);

  Fragment LoadArgDescriptor();
  Fragment TestTypeArgsLen(Fragment eq_branch,
                           Fragment neq_branch,
                           intptr_t num_type_args);
  Fragment TestDelayedTypeArgs(LocalVariable* closure,
                               Fragment present,
                               Fragment absent);
  Fragment TestAnyTypeArgs(Fragment present, Fragment absent);

  JoinEntryInstr* BuildThrowNoSuchMethod();

  Fragment AssertBool(TokenPosition position);
  Fragment BooleanNegate();
  Fragment AllocateContext(const ZoneGrowableArray<const Slot*>& scope);
  Fragment AllocateClosure(TokenPosition position,
                           const Function& closure_function);
  Fragment CreateArray();
  Fragment AllocateTypedData(TokenPosition position, classid_t class_id);
  Fragment InstantiateType(const AbstractType& type);
  Fragment InstantiateTypeArguments(const TypeArguments& type_arguments);
  Fragment InstantiateDynamicTypeArguments();
  Fragment LoadClassId();

  // Returns true if we are building a graph for inlining of a call site that
  // enters the function through the unchecked entry.
  bool InliningUncheckedEntry() const { return inlining_unchecked_entry_; }

  // Returns depth of expression stack.
  intptr_t GetStackDepth() const {
    return stack_ == nullptr ? 0 : stack_->definition()->temp_index() + 1;
  }

  // Builds the graph for an invocation of '_asFunctionInternal'.
  //
  // 'signatures' contains the pair [<dart signature>, <native signature>].
  Fragment BuildFfiAsFunctionInternalCall(const TypeArguments& signatures);

  Fragment AllocateObject(TokenPosition position,
                          const Class& klass,
                          intptr_t argument_count);

  Fragment DebugStepCheck(TokenPosition position);

  // Loads 'receiver' and checks it for null. Throws NoSuchMethod if it is null.
  // 'function_name' is a selector which is being called (reported in
  // NoSuchMethod message).
  // Sets 'receiver' to 'null' after the check if 'clear_the_temp'.
  // Note that this does _not_ use the result of the CheckNullInstr, so it does
  // not create a data depedency and might break with code motion.
  Fragment CheckNull(TokenPosition position,
                     LocalVariable* receiver,
                     const String& function_name,
                     bool clear_the_temp = true);

  // Pops the top of the stack, checks it for null, and pushes the result on
  // the stack to create a data dependency.
  // 'function_name' is a selector which is being called (reported in
  // NoSuchMethod message).
  // Note that the result can currently only be used in optimized code, because
  // optimized code uses FlowGraph::RemoveRedefinitions to remove the
  // redefinitions, while unoptimized code does not.
  Fragment CheckNullOptimized(TokenPosition position,
                              const String& function_name);

  // Records extra unchecked entry point 'unchecked_entry' in 'graph_entry'.
  void RecordUncheckedEntryPoint(GraphEntryInstr* graph_entry,
                                 FunctionEntryInstr* unchecked_entry);

  // Pop the index of the current entry-point off the stack. If there is any
  // entrypoint-tracing hook registered in a pragma for the function, it is
  // called with the name of the current function and the current entry-point
  // index.
  Fragment BuildEntryPointsIntrospection();

  // Builds closure call with given number of arguments. Target closure
  // function is taken from top of the stack.
  // PushArgument instructions should be already added for arguments.
  Fragment ClosureCall(TokenPosition position,
                       intptr_t type_args_len,
                       intptr_t argument_count,
                       const Array& argument_names,
                       bool use_unchecked_entry = false);

  // Builds StringInterpolate instruction, an equivalent of
  // _StringBase._interpolate call.
  Fragment StringInterpolate(TokenPosition position);

  // Pops function type arguments, instantiator type arguments, dst_type, and
  // value; and type checks value against the type arguments.
  Fragment AssertAssignable(
      TokenPosition position,
      const String& dst_name,
      AssertAssignableInstr::Kind kind = AssertAssignableInstr::kUnknown);

  // Returns true if we're currently recording deopt_id -> context level
  // mapping.
  bool is_recording_context_levels() const {
    return context_level_array_ != nullptr;
  }

  // Sets current context level. It will be recorded for all subsequent
  // deopt ids (until it is adjusted again).
  void set_context_depth(intptr_t context_level) {
    context_depth_ = context_level;
  }

  // Reset context level for the given deopt id (which was allocated earlier).
  void reset_context_depth_for_deopt_id(intptr_t deopt_id);

  // Sets raw parameter variables to inferred constant values.
  Fragment InitConstantParameters();

  // Returns whether this function has a saved arguments descriptor array.
  bool has_saved_args_desc_array() {
    return function_.IsInvokeFieldDispatcher() ||
           function_.IsNoSuchMethodDispatcher();
  }

  // Returns the saved arguments descriptor array for functions that have them.
  const Array& saved_args_desc_array() {
    ASSERT(has_saved_args_desc_array());
    return saved_args_desc_array_;
  }

 protected:
  intptr_t AllocateBlockId() { return ++last_used_block_id_; }

  const ParsedFunction* parsed_function_;
  const Function& function_;
  Thread* thread_;
  Zone* zone_;
  intptr_t osr_id_;
  // Contains (deopt_id, context_level) pairs.
  ZoneGrowableArray<intptr_t>* context_level_array_;
  intptr_t context_depth_;
  intptr_t last_used_block_id_;

  intptr_t current_try_index_;
  intptr_t next_used_try_index_;

  Value* stack_;
  InlineExitCollector* exit_collector_;

  const bool inlining_unchecked_entry_;
  const Array& saved_args_desc_array_;

  friend class StreamingFlowGraphBuilder;

 private:
  DISALLOW_COPY_AND_ASSIGN(BaseFlowGraphBuilder);
};

}  // namespace kernel
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_BASE_FLOW_GRAPH_BUILDER_H_
