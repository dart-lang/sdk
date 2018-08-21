// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_
#define RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/bytecode_reader.h"
#include "vm/compiler/frontend/constant_evaluator.h"
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
        type_translator_(this, active_class_, /* finalize= */ true),
        constant_evaluator_(this,
                            &type_translator_,
                            active_class_,
                            flow_graph_builder),
#if defined(DART_USE_INTERPRETER)
        bytecode_metadata_helper_(this, &type_translator_, active_class_),
#endif  // defined(DART_USE_INTERPRETER)
        direct_call_metadata_helper_(this),
        inferred_type_metadata_helper_(this),
        procedure_attributes_metadata_helper_(this),
        call_site_attributes_metadata_helper_(this, &type_translator_) {
  }

  virtual ~StreamingFlowGraphBuilder() {}

  FlowGraph* BuildGraph();

  void ReportUnexpectedTag(const char* variant, Tag tag) override;

  Fragment BuildStatementAt(intptr_t kernel_offset);

 private:
  bool optimizing();

  FlowGraph* BuildGraphOfFieldInitializer();
  FlowGraph* BuildGraphOfFieldAccessor(LocalVariable* setter_value);
  void SetupDefaultParameterValues();
  Fragment BuildFieldInitializer(NameIndex canonical_name);
  Fragment BuildInitializers(const Class& parent_class);
  FlowGraph* BuildGraphOfImplicitClosureFunction(const Function& function);
  FlowGraph* BuildGraphOfFunction(bool constructor);
  FlowGraph* BuildGraphOfDynamicInvocationForwarder();
  FlowGraph* BuildGraphOfNoSuchMethodForwarder(
      const Function& function,
      bool is_implicit_closure_function,
      bool throw_no_such_method_error = false);

  Fragment BuildExpression(TokenPosition* position = NULL);
  Fragment BuildStatement();

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
  struct UncheckedEntryPointStyle_ {
    enum Style {
      kNone = 0,
      kSeparate = 1,
      kSharedWithVariable = 2,
    };
  };
  typedef UncheckedEntryPointStyle_::Style UncheckedEntryPointStyle;

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
  Fragment DebugStepCheckInPrologue(const Function& dart_function,
                                    TokenPosition position);
  Fragment SetAsyncStackTrace(const Function& dart_function);
  Fragment CheckStackOverflowInPrologue(const Function& dart_function);
  Fragment SetupCapturedParameters(const Function& dart_function);
  Fragment ShortcutForUserDefinedEquals(const Function& dart_function,
                                        LocalVariable* first_parameter);
  Fragment TypeArgumentsHandling(const Function& dart_function,
                                 intptr_t type_parameters_offset);
  void CheckArgumentTypesAsNecessary(const Function& dart_function,
                                     intptr_t type_parameters_offset,
                                     Fragment* explicit_checks,
                                     Fragment* implicit_checks);
  Fragment CompleteBodyWithYieldContinuations(Fragment body);
  TargetEntryInstr* BuildSeparateUncheckedEntryPoint(
      BlockEntryInstr* normal_entry,
      Fragment normal_prologue,
      Fragment extra_prologue,
      Fragment shared_prologue,
      Fragment body);
  TargetEntryInstr* BuildSharedUncheckedEntryPoint(
      Fragment prologue_from_normal_entry,
      Fragment skippable_checks,
      Fragment body);

  Fragment BuildEntryPointsIntrospection();

  static UncheckedEntryPointStyle ChooseEntryPointStyle(
      const Function& dart_function,
      const Fragment& implicit_type_checks,
      const Fragment& first_time_prologue,
      const Fragment& every_time_prologue);

  void RecordUncheckedEntryPoint(TargetEntryInstr* extra_entry);

  void loop_depth_inc();
  void loop_depth_dec();
  intptr_t for_in_depth();
  void for_in_depth_inc();
  void for_in_depth_dec();
  void catch_depth_inc();
  void catch_depth_dec();
  void try_depth_inc();
  void try_depth_dec();
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
  Fragment Return(TokenPosition position);
  Fragment PushArgument();
  Fragment EvaluateAssertion();
  Fragment RethrowException(TokenPosition position, int catch_try_index);
  Fragment ThrowNoSuchMethodError();
  Fragment Constant(const Object& value);
  Fragment IntConstant(int64_t value);
  Fragment LoadStaticField();
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
                      intptr_t type_args_len = 0);
  Fragment InstanceCall(TokenPosition position,
                        const String& name,
                        Token::Kind kind,
                        intptr_t argument_count,
                        intptr_t checked_argument_count = 1);
  Fragment InstanceCall(TokenPosition position,
                        const String& name,
                        Token::Kind kind,
                        intptr_t type_args_len,
                        intptr_t argument_count,
                        const Array& argument_names,
                        intptr_t checked_argument_count,
                        const Function& interface_target,
                        const InferredTypeMetadata* result_type = NULL);

  enum TypeChecksToBuild {
    kCheckAllTypeParameterBounds,
    kCheckNonCovariantTypeParameterBounds,
    kCheckCovariantTypeParameterBounds,
  };

  // Does not move the cursor.
  Fragment BuildDefaultTypeHandling(const Function& function,
                                    intptr_t type_parameters_offset);

  struct PushedArguments {
    intptr_t type_args_len;
    intptr_t argument_count;
    Array& argument_names;
  };
  Fragment PushAllArguments(PushedArguments* pushed);

  void BuildArgumentTypeChecks(TypeChecksToBuild mode,
                               Fragment* explicit_checks,
                               Fragment* implicit_checks);

  Fragment ThrowException(TokenPosition position);
  Fragment BooleanNegate();
  Fragment TranslateInstantiatedTypeArguments(
      const TypeArguments& type_arguments);
  Fragment StrictCompare(Token::Kind kind, bool number_check = false);
  Fragment AllocateObject(TokenPosition position,
                          const Class& klass,
                          intptr_t argument_count);
  Fragment AllocateObject(const Class& klass, const Function& closure_function);
  Fragment AllocateContext(intptr_t size);
  Fragment LoadField(intptr_t offset);
  Fragment StoreLocal(TokenPosition position, LocalVariable* variable);
  Fragment StoreStaticField(TokenPosition position, const Field& field);
  Fragment StoreInstanceField(TokenPosition position, intptr_t offset);
  Fragment StringInterpolate(TokenPosition position);
  Fragment StringInterpolateSingle(TokenPosition position);
  Fragment ThrowTypeError();
  Fragment LoadInstantiatorTypeArguments();
  Fragment LoadFunctionTypeArguments();
  Fragment InstantiateType(const AbstractType& type);
  Fragment CreateArray();
  Fragment StoreIndexed(intptr_t class_id);
  Fragment CheckStackOverflow(TokenPosition position);
  Fragment CloneContext(intptr_t num_context_variables);
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
  Fragment CheckAssignableInCheckedMode(const AbstractType& dst_type,
                                        const String& dst_name);
  Fragment CheckArgumentType(LocalVariable* variable, const AbstractType& type);
  Fragment CheckTypeArgumentBound(const AbstractType& parameter,
                                  const AbstractType& bound,
                                  const String& dst_name);
  Fragment CheckVariableTypeInCheckedMode(intptr_t variable_kernel_position);
  Fragment CheckVariableTypeInCheckedMode(const AbstractType& dst_type,
                                          const String& name_symbol);
  Fragment EnterScope(intptr_t kernel_offset,
                      intptr_t* num_context_variables = NULL);
  Fragment ExitScope(intptr_t kernel_offset);

  TestFragment TranslateConditionForControl();

  const TypeArguments& BuildTypeArguments();
  Fragment BuildArguments(Array* argument_names,
                          intptr_t* argument_count,
                          intptr_t* positional_argument_count,
                          bool skip_push_arguments = false,
                          bool do_drop = false);
  Fragment BuildArgumentsFromActualArguments(Array* argument_names,
                                             bool skip_push_arguments = false,
                                             bool do_drop = false);

  Fragment BuildInvalidExpression(TokenPosition* position);
  Fragment BuildVariableGet(TokenPosition* position);
  Fragment BuildVariableGet(uint8_t payload, TokenPosition* position);
  Fragment BuildVariableSet(TokenPosition* position);
  Fragment BuildVariableSet(uint8_t payload, TokenPosition* position);
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
  Fragment BuildDirectPropertyGet(TokenPosition* position);
  Fragment BuildDirectPropertySet(TokenPosition* position);
  Fragment BuildStaticGet(TokenPosition* position);
  Fragment BuildStaticSet(TokenPosition* position);
  Fragment BuildMethodInvocation(TokenPosition* position);
  Fragment BuildDirectMethodInvocation(TokenPosition* position);
  Fragment BuildSuperMethodInvocation(TokenPosition* position);
  Fragment BuildStaticInvocation(bool is_const, TokenPosition* position);
  Fragment BuildConstructorInvocation(bool is_const, TokenPosition* position);
  Fragment BuildNot(TokenPosition* position);
  Fragment BuildLogicalExpression(TokenPosition* position);
  Fragment TranslateLogicalExpressionForValue(bool negated,
                                              TestFragment* side_exits);
  Fragment BuildConditionalExpression(TokenPosition* position);
  Fragment BuildStringConcatenation(TokenPosition* position);
  Fragment BuildIsExpression(TokenPosition* position);
  Fragment BuildAsExpression(TokenPosition* position);
  Fragment BuildSymbolLiteral(TokenPosition* position);
  Fragment BuildTypeLiteral(TokenPosition* position);
  Fragment BuildThisExpression(TokenPosition* position);
  Fragment BuildRethrow(TokenPosition* position);
  Fragment BuildThrow(TokenPosition* position);
  Fragment BuildListLiteral(bool is_const, TokenPosition* position);
  Fragment BuildMapLiteral(bool is_const, TokenPosition* position);
  Fragment BuildFunctionExpression();
  Fragment BuildLet(TokenPosition* position);
  Fragment BuildBigIntLiteral(TokenPosition* position);
  Fragment BuildStringLiteral(TokenPosition* position);
  Fragment BuildIntLiteral(uint8_t payload, TokenPosition* position);
  Fragment BuildIntLiteral(bool is_negative, TokenPosition* position);
  Fragment BuildDoubleLiteral(TokenPosition* position);
  Fragment BuildBoolLiteral(bool value, TokenPosition* position);
  Fragment BuildNullLiteral(TokenPosition* position);
  Fragment BuildFutureNullValue(TokenPosition* position);
  Fragment BuildConstantExpression(TokenPosition* position);
  Fragment BuildPartialTearoffInstantiation(TokenPosition* position);

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

  FlowGraphBuilder* flow_graph_builder_;
  ActiveClass* const active_class_;
  TypeTranslator type_translator_;
  ConstantEvaluator constant_evaluator_;
#if defined(DART_USE_INTERPRETER)
  BytecodeMetadataHelper bytecode_metadata_helper_;
#endif  // defined(DART_USE_INTERPRETER)
  DirectCallMetadataHelper direct_call_metadata_helper_;
  InferredTypeMetadataHelper inferred_type_metadata_helper_;
  ProcedureAttributesMetadataHelper procedure_attributes_metadata_helper_;
  CallSiteAttributesMetadataHelper call_site_attributes_metadata_helper_;

  friend class KernelLoader;

  DISALLOW_COPY_AND_ASSIGN(StreamingFlowGraphBuilder);
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_
