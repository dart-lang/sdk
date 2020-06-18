// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_KERNEL_TO_IL_H_
#define RUNTIME_VM_COMPILER_FRONTEND_KERNEL_TO_IL_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/growable_array.h"
#include "vm/hash_map.h"

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/ffi/marshaller.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/compiler/frontend/base_flow_graph_builder.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/compiler/frontend/scope_builder.h"

namespace dart {

class InlineExitCollector;

namespace kernel {

class StreamingFlowGraphBuilder;
struct InferredTypeMetadata;
class BreakableBlock;
class CatchBlock;
class FlowGraphBuilder;
class SwitchBlock;
class TryCatchBlock;
class TryFinallyBlock;

struct YieldContinuation {
  Instruction* entry;
  intptr_t try_index;

  YieldContinuation(Instruction* entry, intptr_t try_index)
      : entry(entry), try_index(try_index) {}

  YieldContinuation() : entry(NULL), try_index(kInvalidTryIndex) {}
};

enum class TypeChecksToBuild {
  kCheckAllTypeParameterBounds,
  kCheckNonCovariantTypeParameterBounds,
  kCheckCovariantTypeParameterBounds,
};

class FlowGraphBuilder : public BaseFlowGraphBuilder {
 public:
  FlowGraphBuilder(ParsedFunction* parsed_function,
                   ZoneGrowableArray<const ICData*>* ic_data_array,
                   ZoneGrowableArray<intptr_t>* context_level_array,
                   InlineExitCollector* exit_collector,
                   bool optimizing,
                   intptr_t osr_id,
                   intptr_t first_block_id = 1,
                   bool inlining_unchecked_entry = false);
  virtual ~FlowGraphBuilder();

  FlowGraph* BuildGraph();

 private:
  BlockEntryInstr* BuildPrologue(BlockEntryInstr* normal_entry,
                                 PrologueInfo* prologue_info);

  // Return names of optional named parameters of [function].
  ArrayPtr GetOptionalParameterNames(const Function& function);

  // Generate fragment which pushes all explicit parameters of [function].
  Fragment PushExplicitParameters(
      const Function& function,
      const Function& target = Function::null_function());

  FlowGraph* BuildGraphOfMethodExtractor(const Function& method);
  FlowGraph* BuildGraphOfNoSuchMethodDispatcher(const Function& function);
  FlowGraph* BuildGraphOfInvokeFieldDispatcher(const Function& function);
  FlowGraph* BuildGraphOfFfiTrampoline(const Function& function);
  FlowGraph* BuildGraphOfFfiCallback(const Function& function);
  FlowGraph* BuildGraphOfFfiNative(const Function& function);

  Fragment NativeFunctionBody(const Function& function,
                              LocalVariable* first_parameter);

  // Every recognized method has a body expressed in IL.
  bool IsRecognizedMethodForFlowGraph(const Function& function);
  FlowGraph* BuildGraphOfRecognizedMethod(const Function& function);

  Fragment BuildTypedDataViewFactoryConstructor(const Function& function,
                                                classid_t cid);

  Fragment EnterScope(intptr_t kernel_offset,
                      const LocalScope** scope = nullptr);
  Fragment ExitScope(intptr_t kernel_offset);

  Fragment AdjustContextTo(int depth);

  Fragment PushContext(const LocalScope* scope);
  Fragment PopContext();

  Fragment LoadInstantiatorTypeArguments();
  Fragment LoadFunctionTypeArguments();
  Fragment TranslateInstantiatedTypeArguments(
      const TypeArguments& type_arguments);

  Fragment CatchBlockEntry(const Array& handler_types,
                           intptr_t handler_index,
                           bool needs_stacktrace,
                           bool is_synthesized);
  Fragment TryCatch(int try_handler_index);
  Fragment CheckStackOverflowInPrologue(TokenPosition position);
  Fragment CloneContext(const ZoneGrowableArray<const Slot*>& context_slots);

  Fragment InstanceCall(
      TokenPosition position,
      const String& name,
      Token::Kind kind,
      intptr_t type_args_len,
      intptr_t argument_count,
      const Array& argument_names,
      intptr_t checked_argument_count,
      const Function& interface_target = Function::null_function(),
      const Function& tearoff_interface_target = Function::null_function(),
      const InferredTypeMetadata* result_type = nullptr,
      bool use_unchecked_entry = false,
      const CallSiteAttributesMetadata* call_site_attrs = nullptr,
      bool receiver_is_not_smi = false);

  Fragment FfiCall(const compiler::ffi::CallMarshaller& marshaller);

  Fragment ThrowException(TokenPosition position);
  Fragment RethrowException(TokenPosition position, int catch_try_index);
  Fragment LoadLocal(LocalVariable* variable);
  Fragment StoreLateField(const Field& field,
                          LocalVariable* instance,
                          LocalVariable* setter_value);
  Fragment NativeCall(const String* name, const Function* function);
  Fragment Return(
      TokenPosition position,
      bool omit_result_type_check = false,
      intptr_t yield_index = PcDescriptorsLayout::kInvalidYieldIndex);
  void SetResultTypeForStaticCall(StaticCallInstr* call,
                                  const Function& target,
                                  intptr_t argument_count,
                                  const InferredTypeMetadata* result_type);
  Fragment StaticCall(TokenPosition position,
                      const Function& target,
                      intptr_t argument_count,
                      ICData::RebindRule rebind_rule);
  Fragment StaticCall(TokenPosition position,
                      const Function& target,
                      intptr_t argument_count,
                      const Array& argument_names,
                      ICData::RebindRule rebind_rule,
                      const InferredTypeMetadata* result_type = NULL,
                      intptr_t type_args_len = 0,
                      bool use_unchecked_entry = false);
  Fragment StringInterpolateSingle(TokenPosition position);
  Fragment ThrowTypeError();
  Fragment ThrowNoSuchMethodError(const Function& target);
  Fragment ThrowLateInitializationError(TokenPosition position,
                                        const String& name);
  Fragment BuildImplicitClosureCreation(const Function& target);

  Fragment EvaluateAssertion();
  Fragment CheckVariableTypeInCheckedMode(const AbstractType& dst_type,
                                          const String& name_symbol);
  Fragment CheckBoolean(TokenPosition position);
  Fragment CheckAssignable(
      const AbstractType& dst_type,
      const String& dst_name,
      AssertAssignableInstr::Kind kind = AssertAssignableInstr::kUnknown);

  Fragment AssertAssignableLoadTypeArguments(
      TokenPosition position,
      const AbstractType& dst_type,
      const String& dst_name,
      AssertAssignableInstr::Kind kind = AssertAssignableInstr::kUnknown);
  Fragment AssertSubtype(TokenPosition position,
                         const AbstractType& sub_type,
                         const AbstractType& super_type,
                         const String& dst_name);

  bool NeedsDebugStepCheck(const Function& function, TokenPosition position);
  bool NeedsDebugStepCheck(Value* value, TokenPosition position);

  // Truncates (instead of deoptimizing) if the origin does not fit into the
  // target representation.
  Fragment UnboxTruncate(Representation to);

  // Creates an ffi.Pointer holding a given address (TOS).
  Fragment FfiPointerFromAddress(const Type& result_type);

  // Pushes an (unboxed) bogus value returned when a native -> Dart callback
  // throws an exception.
  Fragment FfiExceptionalReturnValue(const AbstractType& result_type,
                                     const Representation target);

  // Pops a Dart object and push the unboxed native version, according to the
  // semantics of FFI argument translation.
  Fragment FfiConvertArgumentToNative(
      const compiler::ffi::BaseMarshaller& marshaller,
      intptr_t arg_index,
      LocalVariable* api_local_scope);

  // Reverse of 'FfiConvertArgumentToNative'.
  Fragment FfiConvertArgumentToDart(
      const compiler::ffi::BaseMarshaller& marshaller,
      intptr_t arg_index);

  // Generates a call to `Thread::EnterApiScope`.
  Fragment EnterHandleScope();

  // Generates a call to `Thread::api_top_scope`.
  Fragment GetTopHandleScope();

  // Generates a call to `Thread::ExitApiScope`.
  Fragment ExitHandleScope();

  // Leaves a `LocalHandle` on the stack.
  Fragment AllocateHandle(LocalVariable* api_local_scope);

  // Populates the base + offset with a tagged value.
  Fragment RawStoreField(int32_t offset);

  // Wraps an `Object` from the stack and leaves a `LocalHandle` on the stack.
  Fragment WrapHandle(LocalVariable* api_local_scope);

  // Unwraps a `LocalHandle` from the stack and leaves the object on the stack.
  Fragment UnwrapHandle();

  // Wrap the current exception and stacktrace in an unhandled exception.
  Fragment UnhandledException();

  // Return from a native -> Dart callback. Can only be used in conjunction with
  // NativeEntry and NativeParameter are used.
  Fragment NativeReturn(const compiler::ffi::CallbackMarshaller& marshaller);

  // Bit-wise cast between representations.
  // Pops the input and pushes the converted result.
  // Currently only works with equal sizes and floating point <-> integer.
  Fragment BitCast(Representation from, Representation to);

  LocalVariable* LookupVariable(intptr_t kernel_offset);

  // Build argument type checks for the current function.
  // ParsedFunction should have the following information:
  //  - is_forwarding_stub()
  //  - forwarding_stub_super_target()
  // Scope should be populated with parameter variables including
  //  - needs_type_check()
  //  - is_explicit_covariant_parameter()
  void BuildArgumentTypeChecks(TypeChecksToBuild mode,
                               Fragment* explicit_checks,
                               Fragment* implicit_checks,
                               Fragment* implicit_redefinitions);

  // Returns true if null assertion is needed for
  // a parameter of given type.
  bool NeedsNullAssertion(const AbstractType& type);

  // Builds null assertion for the given parameter.
  Fragment NullAssertion(LocalVariable* variable);

  // Builds null assertions for all parameters (if needed).
  Fragment BuildNullAssertions();

  // Builds flow graph for noSuchMethod forwarder.
  //
  // If throw_no_such_method_error is set to true, an
  // instance of NoSuchMethodError is thrown. Otherwise, the instance
  // noSuchMethod is called.
  //
  // ParsedFunction should have the following information:
  //  - default_parameter_values()
  //  - is_forwarding_stub()
  //  - forwarding_stub_super_target()
  //
  // Scope should be populated with parameter variables including
  //  - needs_type_check()
  //  - is_explicit_covariant_parameter()
  //
  FlowGraph* BuildGraphOfNoSuchMethodForwarder(
      const Function& function,
      bool is_implicit_closure_function,
      bool throw_no_such_method_error);

  // If no type arguments are passed to a generic function, we need to fill the
  // type arguments in with the default types stored on the TypeParameter nodes
  // in Kernel.
  //
  // ParsedFunction should have the following information:
  //  - DefaultFunctionTypeArguments()
  //  - function_type_arguments()
  Fragment BuildDefaultTypeHandling(const Function& function);

  FunctionEntryInstr* BuildSharedUncheckedEntryPoint(
      Fragment prologue_from_normal_entry,
      Fragment skippable_checks,
      Fragment redefinitions_if_skipped,
      Fragment body);
  FunctionEntryInstr* BuildSeparateUncheckedEntryPoint(
      BlockEntryInstr* normal_entry,
      Fragment normal_prologue,
      Fragment extra_prologue,
      Fragment shared_prologue,
      Fragment body);

  // Builds flow graph for implicit closure function (tear-off).
  //
  // ParsedFunction should have the following information:
  //  - DefaultFunctionTypeArguments()
  //  - function_type_arguments()
  //  - default_parameter_values()
  //  - is_forwarding_stub()
  //  - forwarding_stub_super_target()
  //
  // Scope should be populated with parameter variables including
  //  - needs_type_check()
  //  - is_explicit_covariant_parameter()
  //
  FlowGraph* BuildGraphOfImplicitClosureFunction(const Function& function);

  // Builds flow graph of implicit field getter, setter, or a
  // dynamic invocation forwarder to a field setter.
  //
  // If field is const, its value should be evaluated and stored in
  //  - StaticValue()
  //
  // Scope should be populated with parameter variables including
  //  - needs_type_check()
  //
  FlowGraph* BuildGraphOfFieldAccessor(const Function& function);

  // Builds flow graph of dynamic invocation forwarder.
  //
  // ParsedFunction should have the following information:
  //  - DefaultFunctionTypeArguments()
  //  - function_type_arguments()
  //  - default_parameter_values()
  //  - is_forwarding_stub()
  //  - forwarding_stub_super_target()
  //
  // Scope should be populated with parameter variables including
  //  - needs_type_check()
  //  - is_explicit_covariant_parameter()
  //
  FlowGraph* BuildGraphOfDynamicInvocationForwarder(const Function& function);

  TranslationHelper translation_helper_;
  Thread* thread_;
  Zone* zone_;

  ParsedFunction* parsed_function_;
  const bool optimizing_;
  ZoneGrowableArray<const ICData*>& ic_data_array_;

  intptr_t next_function_id_;
  intptr_t AllocateFunctionId() { return next_function_id_++; }

  intptr_t loop_depth_;
  intptr_t try_depth_;
  intptr_t catch_depth_;
  intptr_t for_in_depth_;
  intptr_t block_expression_depth_;

  GraphEntryInstr* graph_entry_;

  ScopeBuildingResult* scopes_;

  GrowableArray<YieldContinuation> yield_continuations_;

  LocalVariable* CurrentException() {
    return scopes_->exception_variables[catch_depth_ - 1];
  }
  LocalVariable* CurrentStackTrace() {
    return scopes_->stack_trace_variables[catch_depth_ - 1];
  }
  LocalVariable* CurrentRawException() {
    return scopes_->raw_exception_variables[catch_depth_ - 1];
  }
  LocalVariable* CurrentRawStackTrace() {
    return scopes_->raw_stack_trace_variables[catch_depth_ - 1];
  }
  LocalVariable* CurrentCatchContext() {
    return scopes_->catch_context_variables[try_depth_];
  }

  TryCatchBlock* CurrentTryCatchBlock() const { return try_catch_block_; }

  void SetCurrentTryCatchBlock(TryCatchBlock* try_catch_block);

  // A chained list of breakable blocks. Chaining and lookup is done by the
  // [BreakableBlock] class.
  BreakableBlock* breakable_block_;

  // A chained list of switch blocks. Chaining and lookup is done by the
  // [SwitchBlock] class.
  SwitchBlock* switch_block_;

  // A chained list of try-catch blocks. Chaining and lookup is done by the
  // [TryCatchBlock] class.
  TryCatchBlock* try_catch_block_;

  // A chained list of try-finally blocks. Chaining and lookup is done by the
  // [TryFinallyBlock] class.
  TryFinallyBlock* try_finally_block_;

  // A chained list of catch blocks. Chaining and lookup is done by the
  // [CatchBlock] class.
  CatchBlock* catch_block_;

  ActiveClass active_class_;

  // Cached _AssertionError._throwNewNullAssertion.
  Function* throw_new_null_assertion_ = nullptr;

  friend class BreakableBlock;
  friend class CatchBlock;
  friend class ProgramState;
  friend class StreamingFlowGraphBuilder;
  friend class SwitchBlock;
  friend class TryCatchBlock;
  friend class TryFinallyBlock;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphBuilder);
};

// Convenience class to save/restore program state.
// This snapshot denotes a partial state of the flow
// grap builder that is needed when recursing into
// the statements and expressions of a finalizer block.
class ProgramState {
 public:
  ProgramState(BreakableBlock* breakable_block,
               SwitchBlock* switch_block,
               intptr_t loop_depth,
               intptr_t for_in_depth,
               intptr_t try_depth,
               intptr_t catch_depth,
               intptr_t block_expression_depth)
      : breakable_block_(breakable_block),
        switch_block_(switch_block),
        loop_depth_(loop_depth),
        for_in_depth_(for_in_depth),
        try_depth_(try_depth),
        catch_depth_(catch_depth),
        block_expression_depth_(block_expression_depth) {}

  void assignTo(FlowGraphBuilder* builder) const {
    builder->breakable_block_ = breakable_block_;
    builder->switch_block_ = switch_block_;
    builder->loop_depth_ = loop_depth_;
    builder->for_in_depth_ = for_in_depth_;
    builder->try_depth_ = try_depth_;
    builder->catch_depth_ = catch_depth_;
    builder->block_expression_depth_ = block_expression_depth_;
  }

 private:
  BreakableBlock* const breakable_block_;
  SwitchBlock* const switch_block_;
  const intptr_t loop_depth_;
  const intptr_t for_in_depth_;
  const intptr_t try_depth_;
  const intptr_t catch_depth_;
  const intptr_t block_expression_depth_;
};

class SwitchBlock {
 public:
  SwitchBlock(FlowGraphBuilder* builder, intptr_t case_count)
      : builder_(builder),
        outer_(builder->switch_block_),
        outer_finally_(builder->try_finally_block_),
        case_count_(case_count),
        context_depth_(builder->context_depth_),
        try_index_(builder->CurrentTryIndex()) {
    builder_->switch_block_ = this;
    if (outer_ != NULL) {
      depth_ = outer_->depth_ + outer_->case_count_;
    } else {
      depth_ = 0;
    }
  }
  ~SwitchBlock() { builder_->switch_block_ = outer_; }

  bool HadJumper(intptr_t case_num) {
    return destinations_.Lookup(case_num) != NULL;
  }

  // Get destination via absolute target number (i.e. the correct destination
  // is not necessarily in this block).
  JoinEntryInstr* Destination(intptr_t target_index,
                              TryFinallyBlock** outer_finally = NULL,
                              intptr_t* context_depth = NULL) {
    // Verify consistency of program state.
    ASSERT(builder_->switch_block_ == this);
    // Find corresponding destination.
    SwitchBlock* block = this;
    while (block->depth_ > target_index) {
      block = block->outer_;
      ASSERT(block != nullptr);
    }

    // Set the outer finally block.
    if (outer_finally != NULL) {
      *outer_finally = block->outer_finally_;
      *context_depth = block->context_depth_;
    }

    // Ensure there's [JoinEntryInstr] for that [SwitchCase].
    return block->EnsureDestination(target_index - block->depth_);
  }

  // Get destination via relative target number (i.e. relative to this block,
  // 0 is first case in this block etc).
  JoinEntryInstr* DestinationDirect(intptr_t case_num,
                                    TryFinallyBlock** outer_finally = NULL,
                                    intptr_t* context_depth = NULL) {
    // Set the outer finally block.
    if (outer_finally != NULL) {
      *outer_finally = outer_finally_;
      *context_depth = context_depth_;
    }

    // Ensure there's [JoinEntryInstr] for that [SwitchCase].
    return EnsureDestination(case_num);
  }

 private:
  JoinEntryInstr* EnsureDestination(intptr_t case_num) {
    JoinEntryInstr* cached_inst = destinations_.Lookup(case_num);
    if (cached_inst == NULL) {
      JoinEntryInstr* inst = builder_->BuildJoinEntry(try_index_);
      destinations_.Insert(case_num, inst);
      return inst;
    }
    return cached_inst;
  }

  FlowGraphBuilder* builder_;
  SwitchBlock* outer_;

  IntMap<JoinEntryInstr*> destinations_;

  TryFinallyBlock* outer_finally_;
  intptr_t case_count_;
  intptr_t depth_;
  intptr_t context_depth_;
  intptr_t try_index_;
};

class TryCatchBlock {
 public:
  explicit TryCatchBlock(FlowGraphBuilder* builder,
                         intptr_t try_handler_index = -1)
      : builder_(builder),
        outer_(builder->CurrentTryCatchBlock()),
        try_index_(try_handler_index == -1 ? builder->AllocateTryIndex()
                                           : try_handler_index) {
    builder->SetCurrentTryCatchBlock(this);
  }

  ~TryCatchBlock() { builder_->SetCurrentTryCatchBlock(outer_); }

  intptr_t try_index() { return try_index_; }
  TryCatchBlock* outer() const { return outer_; }

 private:
  FlowGraphBuilder* const builder_;
  TryCatchBlock* const outer_;
  intptr_t const try_index_;

  DISALLOW_COPY_AND_ASSIGN(TryCatchBlock);
};

class TryFinallyBlock {
 public:
  TryFinallyBlock(FlowGraphBuilder* builder, intptr_t finalizer_kernel_offset)
      : builder_(builder),
        outer_(builder->try_finally_block_),
        finalizer_kernel_offset_(finalizer_kernel_offset),
        context_depth_(builder->context_depth_),
        try_index_(builder_->CurrentTryIndex()),
        // Finalizers are executed outside of the try block hence
        // try depth of finalizers are one less than current try
        // depth. For others, program state is snapshot of current.
        state_(builder_->breakable_block_,
               builder_->switch_block_,
               builder_->loop_depth_,
               builder_->for_in_depth_,
               builder_->try_depth_ - 1,
               builder_->catch_depth_,
               builder_->block_expression_depth_) {
    builder_->try_finally_block_ = this;
  }
  ~TryFinallyBlock() { builder_->try_finally_block_ = outer_; }

  TryFinallyBlock* outer() const { return outer_; }
  intptr_t finalizer_kernel_offset() const { return finalizer_kernel_offset_; }
  intptr_t context_depth() const { return context_depth_; }
  intptr_t try_index() const { return try_index_; }
  const ProgramState& state() const { return state_; }

 private:
  FlowGraphBuilder* const builder_;
  TryFinallyBlock* const outer_;
  const intptr_t finalizer_kernel_offset_;
  const intptr_t context_depth_;
  const intptr_t try_index_;
  const ProgramState state_;

  DISALLOW_COPY_AND_ASSIGN(TryFinallyBlock);
};

class BreakableBlock {
 public:
  explicit BreakableBlock(FlowGraphBuilder* builder)
      : builder_(builder),
        outer_(builder->breakable_block_),
        destination_(NULL),
        outer_finally_(builder->try_finally_block_),
        context_depth_(builder->context_depth_),
        try_index_(builder->CurrentTryIndex()) {
    if (builder_->breakable_block_ == NULL) {
      index_ = 0;
    } else {
      index_ = builder_->breakable_block_->index_ + 1;
    }
    builder_->breakable_block_ = this;
  }
  ~BreakableBlock() { builder_->breakable_block_ = outer_; }

  bool HadJumper() { return destination_ != NULL; }

  JoinEntryInstr* destination() { return destination_; }

  JoinEntryInstr* BreakDestination(intptr_t label_index,
                                   TryFinallyBlock** outer_finally,
                                   intptr_t* context_depth) {
    // Verify consistency of program state.
    ASSERT(builder_->breakable_block_ == this);
    // Find corresponding destination.
    BreakableBlock* block = this;
    while (block->index_ != label_index) {
      block = block->outer_;
      ASSERT(block != nullptr);
    }
    *outer_finally = block->outer_finally_;
    *context_depth = block->context_depth_;
    return block->EnsureDestination();
  }

 private:
  JoinEntryInstr* EnsureDestination() {
    if (destination_ == NULL) {
      destination_ = builder_->BuildJoinEntry(try_index_);
    }
    return destination_;
  }

  FlowGraphBuilder* builder_;
  intptr_t index_;
  BreakableBlock* outer_;
  JoinEntryInstr* destination_;
  TryFinallyBlock* outer_finally_;
  intptr_t context_depth_;
  intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(BreakableBlock);
};

class CatchBlock {
 public:
  CatchBlock(FlowGraphBuilder* builder,
             LocalVariable* exception_var,
             LocalVariable* stack_trace_var,
             intptr_t catch_try_index)
      : builder_(builder),
        outer_(builder->catch_block_),
        exception_var_(exception_var),
        stack_trace_var_(stack_trace_var),
        catch_try_index_(catch_try_index) {
    builder_->catch_block_ = this;
  }
  ~CatchBlock() { builder_->catch_block_ = outer_; }

  LocalVariable* exception_var() { return exception_var_; }
  LocalVariable* stack_trace_var() { return stack_trace_var_; }
  intptr_t catch_try_index() { return catch_try_index_; }

 private:
  FlowGraphBuilder* builder_;
  CatchBlock* outer_;
  LocalVariable* exception_var_;
  LocalVariable* stack_trace_var_;
  intptr_t catch_try_index_;

  DISALLOW_COPY_AND_ASSIGN(CatchBlock);
};

}  // namespace kernel
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_KERNEL_TO_IL_H_
