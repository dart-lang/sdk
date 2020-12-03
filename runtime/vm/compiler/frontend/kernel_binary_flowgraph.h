// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_
#define RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/constant_reader.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/compiler/frontend/scope_builder.h"
#include "vm/kernel.h"
#include "vm/kernel_binary.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class StreamingFlowGraphBuilder : public KernelReaderHelper {
 public:
  StreamingFlowGraphBuilder(FlowGraphBuilder* flow_graph_builder,
                            const ExternalTypedData& data,
                            intptr_t data_program_offset)
      : KernelReaderHelper(
            flow_graph_builder->zone_,
            &flow_graph_builder->translation_helper_,
            Script::Handle(
                flow_graph_builder->zone_,
                flow_graph_builder->parsed_function_->function().script()),
            data,
            data_program_offset),
        flow_graph_builder_(flow_graph_builder),
        active_class_(&flow_graph_builder->active_class_),
        constant_reader_(this, active_class_),
        type_translator_(this,
                         &constant_reader_,
                         active_class_,
                         /* finalize= */ true),
        direct_call_metadata_helper_(this),
        inferred_type_metadata_helper_(this, &constant_reader_),
        procedure_attributes_metadata_helper_(this),
        call_site_attributes_metadata_helper_(this, &type_translator_),
        closure_owner_(Object::Handle(flow_graph_builder->zone_)) {}

  virtual ~StreamingFlowGraphBuilder() {}

  FlowGraph* BuildGraph();

  void ReportUnexpectedTag(const char* variant, Tag tag) override;

  Fragment BuildStatementAt(intptr_t kernel_offset);

 private:
  Thread* thread() const { return flow_graph_builder_->thread_; }

  void ParseKernelASTFunction();
  void ReadForwardingStubTarget(const Function& function);
  void EvaluateConstFieldValue(const Field& field);
  void SetupDefaultParameterValues();

  FlowGraph* BuildGraphOfFieldInitializer();
  Fragment BuildFieldInitializer(const Field& field,
                                 bool only_for_side_effects);
  Fragment BuildLateFieldInitializer(const Field& field, bool has_initializer);
  Fragment BuildInitializers(const Class& parent_class);
  FlowGraph* BuildGraphOfFunction(bool constructor);

  Fragment BuildExpression(TokenPosition* position = NULL);
  Fragment BuildStatement();

  // Kernel offset:
  //   start of function expression -> end of function body statement
  Fragment BuildFunctionBody(const Function& dart_function,
                             LocalVariable* first_parameter,
                             bool constructor);

  // Pieces of the prologue. They are all agnostic to the current Kernel offset.
  Fragment BuildEveryTimePrologue(const Function& dart_function,
                                  TokenPosition token_position,
                                  intptr_t type_parameters_offset);
  Fragment BuildFirstTimePrologue(const Function& dart_function,
                                  LocalVariable* first_parameter,
                                  intptr_t type_parameters_offset);
  Fragment ClearRawParameters(const Function& dart_function);
  Fragment DebugStepCheckInPrologue(const Function& dart_function,
                                    TokenPosition position);
  Fragment SetAsyncStackTrace(const Function& dart_function);
  Fragment CheckStackOverflowInPrologue(const Function& dart_function);
  Fragment SetupCapturedParameters(const Function& dart_function);
  Fragment ShortcutForUserDefinedEquals(const Function& dart_function,
                                        LocalVariable* first_parameter);
  Fragment TypeArgumentsHandling(const Function& dart_function);
  Fragment CompleteBodyWithYieldContinuations(Fragment body);

  static UncheckedEntryPointStyle ChooseEntryPointStyle(
      const Function& dart_function,
      const Fragment& implicit_type_checks,
      const Fragment& first_time_prologue,
      const Fragment& every_time_prologue,
      const Fragment& type_args_handling);

  void loop_depth_inc();
  void loop_depth_dec();
  intptr_t for_in_depth();
  void for_in_depth_inc();
  void for_in_depth_dec();
  void catch_depth_inc();
  void catch_depth_dec();
  void try_depth_inc();
  void try_depth_dec();
  intptr_t block_expression_depth();
  void block_expression_depth_inc();
  void block_expression_depth_dec();
  intptr_t CurrentTryIndex();
  intptr_t AllocateTryIndex();
  LocalVariable* CurrentException();
  LocalVariable* CurrentStackTrace();
  CatchBlock* catch_block();
  ActiveClass* active_class();
  ScopeBuildingResult* scopes();
  void set_scopes(ScopeBuildingResult* scope);
  ParsedFunction* parsed_function();
  TryFinallyBlock* try_finally_block();
  SwitchBlock* switch_block();
  BreakableBlock* breakable_block();
  GrowableArray<YieldContinuation>& yield_continuations();
  Value* stack();
  void Push(Definition* definition);
  Value* Pop();
  Class& GetSuperOrDie();

  Tag PeekArgumentsFirstPositionalTag();
  const TypeArguments& PeekArgumentsInstantiatedType(const Class& klass);
  intptr_t PeekArgumentsCount();

  // See BaseFlowGraphBuilder::MakeTemporary.
  LocalVariable* MakeTemporary();

  LocalVariable* LookupVariable(intptr_t kernel_offset);
  Function& FindMatchingFunction(const Class& klass,
                                 const String& name,
                                 int type_args_len,
                                 int argument_count,
                                 const Array& argument_names);

  bool NeedsDebugStepCheck(const Function& function, TokenPosition position);
  bool NeedsDebugStepCheck(Value* value, TokenPosition position);

  void InlineBailout(const char* reason);
  Fragment DebugStepCheck(TokenPosition position);
  Fragment LoadLocal(LocalVariable* variable);
  Fragment Return(
      TokenPosition position,
      intptr_t yield_index = PcDescriptorsLayout::kInvalidYieldIndex);
  Fragment EvaluateAssertion();
  Fragment RethrowException(TokenPosition position, int catch_try_index);
  Fragment ThrowNoSuchMethodError(const Function& target);
  Fragment Constant(const Object& value);
  Fragment IntConstant(int64_t value);
  Fragment LoadStaticField(const Field& field, bool calls_initializer);
  Fragment RedefinitionWithType(const AbstractType& type);
  Fragment CheckNull(TokenPosition position,
                     LocalVariable* receiver,
                     const String& function_name,
                     bool clear_the_temp = true);
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
  Fragment InstanceCall(TokenPosition position,
                        const String& name,
                        Token::Kind kind,
                        intptr_t argument_count,
                        intptr_t checked_argument_count = 1);
  Fragment InstanceCall(
      TokenPosition position,
      const String& name,
      Token::Kind kind,
      intptr_t type_args_len,
      intptr_t argument_count,
      const Array& argument_names,
      intptr_t checked_argument_count,
      const Function& interface_target,
      const Function& tearoff_interface_target,
      const InferredTypeMetadata* result_type = nullptr,
      bool use_unchecked_entry = false,
      const CallSiteAttributesMetadata* call_site_attrs = nullptr,
      bool receiver_is_not_smi = false);

  Fragment ThrowException(TokenPosition position);
  Fragment BooleanNegate();
  Fragment TranslateInstantiatedTypeArguments(
      const TypeArguments& type_arguments);
  Fragment StrictCompare(TokenPosition position,
                         Token::Kind kind,
                         bool number_check = false);
  Fragment AllocateObject(TokenPosition position,
                          const Class& klass,
                          intptr_t argument_count);
  Fragment AllocateObject(const Class& klass, const Function& closure_function);
  Fragment AllocateContext(const ZoneGrowableArray<const Slot*>& context_slots);
  Fragment LoadNativeField(const Slot& field);
  Fragment StoreLocal(TokenPosition position, LocalVariable* variable);
  Fragment StoreStaticField(TokenPosition position, const Field& field);
  Fragment StringInterpolate(TokenPosition position);
  Fragment StringInterpolateSingle(TokenPosition position);
  Fragment ThrowTypeError();
  Fragment LoadInstantiatorTypeArguments();
  Fragment LoadFunctionTypeArguments();
  Fragment InstantiateType(const AbstractType& type);
  Fragment CreateArray();
  Fragment StoreIndexed(intptr_t class_id);
  Fragment CheckStackOverflow(TokenPosition position);
  Fragment CloneContext(const ZoneGrowableArray<const Slot*>& context_slots);
  Fragment TranslateFinallyFinalizers(TryFinallyBlock* outer_finally,
                                      intptr_t target_context_depth);
  Fragment BranchIfTrue(TargetEntryInstr** then_entry,
                        TargetEntryInstr** otherwise_entry,
                        bool negate);
  Fragment BranchIfEqual(TargetEntryInstr** then_entry,
                         TargetEntryInstr** otherwise_entry,
                         bool negate);
  Fragment BranchIfNull(TargetEntryInstr** then_entry,
                        TargetEntryInstr** otherwise_entry,
                        bool negate = false);
  Fragment CatchBlockEntry(const Array& handler_types,
                           intptr_t handler_index,
                           bool needs_stacktrace,
                           bool is_synthesized);
  Fragment TryCatch(int try_handler_index);
  Fragment Drop();

  // Drop given number of temps from the stack but preserve top of the stack.
  Fragment DropTempsPreserveTop(intptr_t num_temps_to_drop);

  Fragment MakeTemp();
  Fragment NullConstant();
  JoinEntryInstr* BuildJoinEntry();
  JoinEntryInstr* BuildJoinEntry(intptr_t try_index);
  Fragment Goto(JoinEntryInstr* destination);
  Fragment BuildImplicitClosureCreation(const Function& target);
  Fragment CheckBoolean(TokenPosition position);
  Fragment CheckArgumentType(LocalVariable* variable, const AbstractType& type);
  Fragment EnterScope(intptr_t kernel_offset,
                      const LocalScope** scope = nullptr);
  Fragment ExitScope(intptr_t kernel_offset);

  TestFragment TranslateConditionForControl();

  const TypeArguments& BuildTypeArguments();
  Fragment BuildArguments(Array* argument_names,
                          intptr_t* argument_count,
                          intptr_t* positional_argument_count);
  Fragment BuildArgumentsFromActualArguments(Array* argument_names);

  Fragment BuildInvalidExpression(TokenPosition* position);
  Fragment BuildVariableGet(TokenPosition* position);
  Fragment BuildVariableGet(uint8_t payload, TokenPosition* position);
  Fragment BuildVariableGetImpl(intptr_t variable_kernel_position,
                                TokenPosition position);
  Fragment BuildVariableSet(TokenPosition* position);
  Fragment BuildVariableSet(uint8_t payload, TokenPosition* position);
  Fragment BuildVariableSetImpl(TokenPosition position,
                                intptr_t variable_kernel_position);
  Fragment BuildPropertyGet(TokenPosition* position);
  Fragment BuildPropertySet(TokenPosition* position);
  Fragment BuildAllocateInvocationMirrorCall(TokenPosition position,
                                             const String& name,
                                             intptr_t num_type_arguments,
                                             intptr_t num_arguments,
                                             const Array& argument_names,
                                             LocalVariable* actuals_array,
                                             Fragment build_rest_of_actuals);
  Fragment BuildSuperPropertyGet(TokenPosition* position);
  Fragment BuildSuperPropertySet(TokenPosition* position);
  Fragment BuildStaticGet(TokenPosition* position);
  Fragment BuildStaticSet(TokenPosition* position);
  Fragment BuildMethodInvocation(TokenPosition* position);
  Fragment BuildSuperMethodInvocation(TokenPosition* position);
  Fragment BuildStaticInvocation(TokenPosition* position);
  Fragment BuildConstructorInvocation(TokenPosition* position);
  Fragment BuildNot(TokenPosition* position);
  Fragment BuildNullCheck(TokenPosition* position);
  Fragment BuildLogicalExpression(TokenPosition* position);
  Fragment TranslateLogicalExpressionForValue(bool negated,
                                              TestFragment* side_exits);
  Fragment BuildConditionalExpression(TokenPosition* position);
  Fragment BuildStringConcatenation(TokenPosition* position);
  Fragment BuildIsExpression(TokenPosition* position);
  Fragment BuildAsExpression(TokenPosition* position);
  Fragment BuildTypeLiteral(TokenPosition* position);
  Fragment BuildThisExpression(TokenPosition* position);
  Fragment BuildRethrow(TokenPosition* position);
  Fragment BuildThrow(TokenPosition* position);
  Fragment BuildListLiteral(TokenPosition* position);
  Fragment BuildMapLiteral(TokenPosition* position);
  Fragment BuildFunctionExpression();
  Fragment BuildLet(TokenPosition* position);
  Fragment BuildBlockExpression();
  Fragment BuildBigIntLiteral(TokenPosition* position);
  Fragment BuildStringLiteral(TokenPosition* position);
  Fragment BuildIntLiteral(uint8_t payload, TokenPosition* position);
  Fragment BuildIntLiteral(bool is_negative, TokenPosition* position);
  Fragment BuildDoubleLiteral(TokenPosition* position);
  Fragment BuildBoolLiteral(bool value, TokenPosition* position);
  Fragment BuildNullLiteral(TokenPosition* position);
  Fragment BuildFutureNullValue(TokenPosition* position);
  Fragment BuildConstantExpression(TokenPosition* position, Tag tag);
  Fragment BuildPartialTearoffInstantiation(TokenPosition* position);
  Fragment BuildLibraryPrefixAction(TokenPosition* position,
                                    const String& selector);

  Fragment BuildExpressionStatement();
  Fragment BuildBlock();
  Fragment BuildEmptyStatement();
  Fragment BuildAssertBlock();
  Fragment BuildAssertStatement();
  Fragment BuildLabeledStatement();
  Fragment BuildBreakStatement();
  Fragment BuildWhileStatement();
  Fragment BuildDoStatement();
  Fragment BuildForStatement();
  Fragment BuildForInStatement(bool async);
  Fragment BuildSwitchStatement();
  Fragment BuildContinueSwitchStatement();
  Fragment BuildIfStatement();
  Fragment BuildReturnStatement();
  Fragment BuildTryCatch();
  Fragment BuildTryFinally();
  Fragment BuildYieldStatement();
  Fragment BuildVariableDeclaration();
  Fragment BuildFunctionDeclaration();
  Fragment BuildFunctionNode(TokenPosition parent_position,
                             StringIndex name_index);

  // Build build FG for '_asFunctionInternal'. Reads an Arguments from the
  // Kernel buffer and pushes the resulting closure.
  Fragment BuildFfiAsFunctionInternal();

  // Build build FG for '_nativeCallbackFunction'. Reads an Arguments from the
  // Kernel buffer and pushes the resulting Function object.
  Fragment BuildFfiNativeCallbackFunction();

  // Piece of a StringConcatenation.
  // Represents either a StringLiteral, or a Reader offset to the expression.
  struct ConcatPiece {
    intptr_t offset;
    const String* literal;
  };

  // Collector that automatically concatenates adjacent string ConcatPieces.
  struct PiecesCollector {
    explicit PiecesCollector(Zone* z, TranslationHelper* translation_helper)
        : pieces(5),
          literal_run(z, 1),
          translation_helper(translation_helper) {}

    GrowableArray<ConcatPiece> pieces;
    GrowableHandlePtrArray<const String> literal_run;
    TranslationHelper* translation_helper;

    void Add(const ConcatPiece& piece) {
      if (piece.literal != nullptr) {
        literal_run.Add(*piece.literal);
      } else {
        FlushRun();
        pieces.Add(piece);
      }
    }

    void FlushRun() {
      switch (literal_run.length()) {
        case 0:
          return;
        case 1:
          pieces.Add({-1, &literal_run[0]});
          break;
        default:
          pieces.Add({-1, &translation_helper->DartString(literal_run)});
      }
      literal_run.Clear();
    }
  };

  // Flattens and collects pieces of StringConcatenations such that:
  //   ["a", "", "b"] => ["ab"]
  //   ["a", StringConcat("b", "c")] => ["abc"]
  //   ["a", "", StringConcat("b", my_var), "c"] => ["ab", my_var, "c"]
  void FlattenStringConcatenation(PiecesCollector* collector);

  FlowGraphBuilder* flow_graph_builder_;
  ActiveClass* const active_class_;
  ConstantReader constant_reader_;
  TypeTranslator type_translator_;
  DirectCallMetadataHelper direct_call_metadata_helper_;
  InferredTypeMetadataHelper inferred_type_metadata_helper_;
  ProcedureAttributesMetadataHelper procedure_attributes_metadata_helper_;
  CallSiteAttributesMetadataHelper call_site_attributes_metadata_helper_;
  Object& closure_owner_;

  friend class KernelLoader;

  DISALLOW_COPY_AND_ASSIGN(StreamingFlowGraphBuilder);
};

}  // namespace kernel
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_
