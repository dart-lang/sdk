// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_BASE_FLOW_GRAPH_BUILDER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_BASE_FLOW_GRAPH_BUILDER_H_

#include <initializer_list>

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/object.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

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

typedef ZoneGrowableArray<PushArgumentInstr*>* ArgumentArray;

class BaseFlowGraphBuilder {
 public:
  BaseFlowGraphBuilder(
      const ParsedFunction* parsed_function,
      intptr_t last_used_block_id,
      ZoneGrowableArray<intptr_t>* context_level_array = nullptr,
      InlineExitCollector* exit_collector = nullptr,
      bool inlining_unchecked_entry = false)
      : parsed_function_(parsed_function),
        function_(parsed_function_->function()),
        thread_(Thread::Current()),
        zone_(thread_->zone()),
        context_level_array_(context_level_array),
        context_depth_(0),
        last_used_block_id_(last_used_block_id),
        try_catch_block_(NULL),
        next_used_try_index_(0),
        stack_(NULL),
        pending_argument_count_(0),
        loop_depth_(0),
        exit_collector_(exit_collector),
        inlining_unchecked_entry_(inlining_unchecked_entry) {}

  Fragment LoadField(intptr_t offset, intptr_t class_id = kDynamicCid);
  Fragment LoadNativeField(const NativeFieldDesc* native_field);
  Fragment LoadIndexed(intptr_t index_scale);

  void SetTempIndex(Definition* definition);

  Fragment LoadLocal(LocalVariable* variable);
  Fragment StoreLocal(TokenPosition position, LocalVariable* variable);
  Fragment StoreLocalRaw(TokenPosition position, LocalVariable* variable);
  Fragment LoadContextAt(int depth);
  Fragment GuardFieldLength(const Field& field, intptr_t deopt_id);
  Fragment GuardFieldClass(const Field& field, intptr_t deopt_id);
  const Field& MayCloneField(const Field& field);
  Fragment StoreInstanceField(
      TokenPosition position,
      intptr_t offset,
      StoreBarrierType emit_store_barrier = kEmitStoreBarrier);
  Fragment StoreInstanceField(
      const Field& field,
      bool is_initialization_store,
      StoreBarrierType emit_store_barrier = kEmitStoreBarrier);
  Fragment StoreInstanceFieldGuarded(const Field& field,
                                     bool is_initialization_store);
  Fragment LoadStaticField();
  Fragment StoreStaticField(TokenPosition position, const Field& field);
  Fragment StoreIndexed(intptr_t class_id);

  void Push(Definition* definition);
  Definition* Peek();
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
  //
  LocalVariable* MakeTemporary();

  Fragment PushArgument();
  ArgumentArray GetArguments(int count);

  TargetEntryInstr* BuildTargetEntry();
  JoinEntryInstr* BuildJoinEntry();
  JoinEntryInstr* BuildJoinEntry(intptr_t try_index);

  Fragment StrictCompare(Token::Kind kind, bool number_check = false);
  Fragment Goto(JoinEntryInstr* destination);
  Fragment IntConstant(int64_t value);
  Fragment Constant(const Object& value);
  Fragment NullConstant();
  Fragment SmiRelationalOp(Token::Kind kind);
  Fragment SmiBinaryOp(Token::Kind op, bool is_truncating = false);
  Fragment LoadFpRelativeSlot(intptr_t offset);
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
  Fragment Return(TokenPosition position);
  Fragment CheckStackOverflow(TokenPosition position);
  Fragment ThrowException(TokenPosition position);
  Fragment TailCall(const Code& code);

  intptr_t GetNextDeoptId() {
    intptr_t deopt_id = thread_->GetNextDeoptId();
    if (context_level_array_ != NULL) {
      intptr_t level = context_depth_;
      context_level_array_->Add(deopt_id);
      context_level_array_->Add(level);
    }
    return deopt_id;
  }

  intptr_t AllocateTryIndex() { return next_used_try_index_++; }

  bool IsInlining() const { return exit_collector_ != nullptr; }

  void InlineBailout(const char* reason);

  Fragment LoadArgDescriptor() {
    ASSERT(parsed_function_->has_arg_desc_var());
    return LoadLocal(parsed_function_->arg_desc_var());
  }

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
  Fragment AllocateContext(intptr_t size);
  Fragment CreateArray();
  Fragment InstantiateType(const AbstractType& type);
  Fragment InstantiateTypeArguments(const TypeArguments& type_arguments);

  // Returns true if we are building a graph for inlining of a call site that
  // enters the function through the unchecked entry.
  bool InliningUncheckedEntry() const { return inlining_unchecked_entry_; }

 protected:
  intptr_t AllocateBlockId() { return ++last_used_block_id_; }
  intptr_t CurrentTryIndex();

  const ParsedFunction* parsed_function_;
  const Function& function_;
  Thread* thread_;
  Zone* zone_;
  // Contains (deopt_id, context_level) pairs.
  ZoneGrowableArray<intptr_t>* context_level_array_;
  intptr_t context_depth_;
  intptr_t last_used_block_id_;

  // A chained list of try-catch blocks. Chaining and lookup is done by the
  // [TryCatchBlock] class.
  TryCatchBlock* try_catch_block_;
  intptr_t next_used_try_index_;

  Value* stack_;
  intptr_t pending_argument_count_;
  intptr_t loop_depth_;
  InlineExitCollector* exit_collector_;

  const bool inlining_unchecked_entry_;

  friend class TryCatchBlock;
  friend class StreamingFlowGraphBuilder;

 private:
  DISALLOW_COPY_AND_ASSIGN(BaseFlowGraphBuilder);
};

class TryCatchBlock {
 public:
  explicit TryCatchBlock(BaseFlowGraphBuilder* builder,
                         intptr_t try_handler_index = -1)
      : builder_(builder),
        outer_(builder->try_catch_block_),
        try_index_(try_handler_index) {
    if (try_index_ == -1) try_index_ = builder->AllocateTryIndex();
    builder->try_catch_block_ = this;
  }
  ~TryCatchBlock() { builder_->try_catch_block_ = outer_; }

  intptr_t try_index() { return try_index_; }
  TryCatchBlock* outer() const { return outer_; }

 private:
  BaseFlowGraphBuilder* builder_;
  TryCatchBlock* outer_;
  intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(TryCatchBlock);
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_BASE_FLOW_GRAPH_BUILDER_H_
