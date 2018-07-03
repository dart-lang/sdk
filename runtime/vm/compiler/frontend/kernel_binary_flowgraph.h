// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_
#define RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/bytecode_reader.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/kernel.h"
#include "vm/kernel_binary.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class StreamingScopeBuilder {
 public:
  explicit StreamingScopeBuilder(ParsedFunction* parsed_function);

  virtual ~StreamingScopeBuilder() = default;

  ScopeBuildingResult* BuildScopes();

 private:
  void VisitField();

  void VisitProcedure();

  void VisitConstructor();

  void VisitFunctionNode();
  void VisitNode();
  void VisitInitializer();
  void VisitExpression();
  void VisitStatement();
  void VisitArguments();
  void VisitVariableDeclaration();
  void VisitDartType();
  void VisitInterfaceType(bool simple);
  void VisitFunctionType(bool simple);
  void VisitTypeParameterType();
  void HandleLocalFunction(intptr_t parent_kernel_offset);

  AbstractType& BuildAndVisitVariableType();

  void EnterScope(intptr_t kernel_offset);
  void ExitScope(TokenPosition start_position, TokenPosition end_position);

  virtual void ReportUnexpectedTag(const char* variant, Tag tag);

  // This enum controls which parameters would be marked as requring type
  // check on the callee side.
  enum ParameterTypeCheckMode {
    // All parameters will be checked.
    kTypeCheckAllParameters,

    // Only parameters marked as covariant or generic-covariant-impl will be
    // checked.
    kTypeCheckForNonDynamicallyInvokedMethod,

    // Only parameters *not* marked as covariant or generic-covariant-impl will
    // be checked. The rest would be checked in the method itself.
    // Inverse of kTypeCheckForNonDynamicallyInvokedMethod.
    kTypeCheckEverythingNotCheckedInNonDynamicallyInvokedMethod,

    // No parameters will be checked.
    kTypeCheckForStaticFunction,
  };

  // This assumes that the reader is at a FunctionNode,
  // about to read the positional parameters.
  void AddPositionalAndNamedParameters(
      intptr_t pos,
      ParameterTypeCheckMode type_check_mode,
      const ProcedureAttributesMetadata& attrs);

  // This assumes that the reader is at a FunctionNode,
  // about to read a parameter (i.e. VariableDeclaration).
  void AddVariableDeclarationParameter(
      intptr_t pos,
      ParameterTypeCheckMode type_check_mode,
      const ProcedureAttributesMetadata& attrs);

  LocalVariable* MakeVariable(TokenPosition declaration_pos,
                              TokenPosition token_pos,
                              const String& name,
                              const AbstractType& type,
                              const InferredTypeMetadata* param_type_md = NULL);

  void AddExceptionVariable(GrowableArray<LocalVariable*>* variables,
                            const char* prefix,
                            intptr_t nesting_depth);

  void FinalizeExceptionVariable(GrowableArray<LocalVariable*>* variables,
                                 GrowableArray<LocalVariable*>* raw_variables,
                                 const String& symbol,
                                 intptr_t nesting_depth);

  void AddTryVariables();
  void AddCatchVariables();
  void FinalizeCatchVariables();
  void AddIteratorVariable();
  void AddSwitchVariable();

  // Record an assignment or reference to a variable.  If the occurrence is
  // in a nested function, ensure that the variable is handled properly as a
  // captured variable.
  void LookupVariable(intptr_t declaration_binary_offset);

  StringIndex GetNameFromVariableDeclaration(intptr_t kernel_offset,
                                             const Function& function);

  const String& GenerateName(const char* prefix, intptr_t suffix);

  void HandleSpecialLoad(LocalVariable** variable, const String& symbol);
  void LookupCapturedVariableByName(LocalVariable** variable,
                                    const String& name);

  struct DepthState {
    explicit DepthState(intptr_t function)
        : loop_(0),
          function_(function),
          try_(0),
          catch_(0),
          finally_(0),
          for_in_(0) {}

    intptr_t loop_;
    intptr_t function_;
    intptr_t try_;
    intptr_t catch_;
    intptr_t finally_;
    intptr_t for_in_;
  };

  ScopeBuildingResult* result_;
  ParsedFunction* parsed_function_;

  ActiveClass active_class_;

  TranslationHelper translation_helper_;
  Zone* zone_;

  FunctionNodeHelper::AsyncMarker current_function_async_marker_;
  LocalScope* current_function_scope_;
  LocalScope* scope_;
  DepthState depth_;

  intptr_t name_index_;

  bool needs_expr_temp_;
  TokenPosition first_body_token_position_;

  KernelReaderHelper helper_;
  InferredTypeMetadataHelper inferred_type_metadata_helper_;
  ProcedureAttributesMetadataHelper procedure_attributes_metadata_helper_;
  TypeTranslator type_translator_;
};

// There are several cases when we are compiling constant expressions:
//
//   * constant field initializers:
//      const FieldName = <expr>;
//
//   * constant expressions:
//      const [<expr>, ...]
//      const {<expr> : <expr>, ...}
//      const Constructor(<expr>, ...)
//
//   * constant default parameters:
//      f(a, [b = <expr>])
//      f(a, {b: <expr>})
//
//   * constant values to compare in a [SwitchCase]
//      case <expr>:
//
// In all cases `<expr>` must be recursively evaluated and canonicalized at
// compile-time.
class StreamingConstantEvaluator {
 public:
  explicit StreamingConstantEvaluator(StreamingFlowGraphBuilder* builder);

  virtual ~StreamingConstantEvaluator() {}

  bool IsCached(intptr_t offset);

  RawInstance* EvaluateExpression(intptr_t offset, bool reset_position = true);
  Instance& EvaluateListLiteral(intptr_t offset, bool reset_position = true);
  Instance& EvaluateMapLiteral(intptr_t offset, bool reset_position = true);
  Instance& EvaluateConstructorInvocation(intptr_t offset,
                                          bool reset_position = true);
  RawObject* EvaluateExpressionSafe(intptr_t offset);

 private:
  bool IsAllowedToEvaluate();
  void EvaluateAsExpression();
  void EvaluateVariableGet(bool is_specialized);
  void EvaluatePropertyGet();
  void EvaluateDirectPropertyGet();
  void EvaluateStaticGet();
  void EvaluateMethodInvocation();
  void EvaluateDirectMethodInvocation();
  void EvaluateSuperMethodInvocation();
  void EvaluateStaticInvocation();
  void EvaluateConstructorInvocationInternal();
  void EvaluateNot();
  void EvaluateLogicalExpression();
  void EvaluateConditionalExpression();
  void EvaluateStringConcatenation();
  void EvaluateSymbolLiteral();
  void EvaluateTypeLiteral();
  void EvaluateListLiteralInternal();
  void EvaluateMapLiteralInternal();
  void EvaluateLet();
  void EvaluatePartialTearoffInstantiation();
  void EvaluateBigIntLiteral();
  void EvaluateStringLiteral();
  void EvaluateIntLiteral(uint8_t payload);
  void EvaluateIntLiteral(bool is_negative);
  void EvaluateDoubleLiteral();
  void EvaluateBoolLiteral(bool value);
  void EvaluateNullLiteral();
  void EvaluateConstantExpression();

  void EvaluateGetStringLength(intptr_t expression_offset,
                               TokenPosition position);

  const Object& RunFunction(const Function& function,
                            intptr_t argument_count,
                            const Instance* receiver,
                            const TypeArguments* type_args);

  const Object& RunFunction(const Function& function,
                            const Array& arguments,
                            const Array& names);

  const Object& RunMethodCall(const Function& function,
                              const Instance* receiver);

  RawObject* EvaluateConstConstructorCall(const Class& type_class,
                                          const TypeArguments& type_arguments,
                                          const Function& constructor,
                                          const Object& argument);

  const TypeArguments* TranslateTypeArguments(const Function& target,
                                              Class* target_klass);

  void AssertBool() {
    if (!result_.IsBool()) {
      translation_helper_.ReportError("Expected boolean expression.");
    }
  }

  bool EvaluateBooleanExpressionHere();

  bool GetCachedConstant(intptr_t kernel_offset, Instance* value);
  void CacheConstantValue(intptr_t kernel_offset, const Instance& value);

  StreamingFlowGraphBuilder* builder_;
  Isolate* isolate_;
  Zone* zone_;
  TranslationHelper& translation_helper_;
  TypeTranslator& type_translator_;

  const Script& script_;
  Instance& result_;
};

class KernelFingerprintHelper : public KernelReaderHelper {
 public:
  KernelFingerprintHelper(Zone* zone,
                          TranslationHelper* translation_helper,
                          const Script& script,
                          const ExternalTypedData& data,
                          intptr_t data_program_offset)
      : KernelReaderHelper(zone,
                           translation_helper,
                           script,
                           data,
                           data_program_offset),
        hash_(0) {}

  virtual ~KernelFingerprintHelper() {}
  uint32_t CalculateFieldFingerprint();
  uint32_t CalculateFunctionFingerprint();

  static uint32_t CalculateHash(uint32_t current, uint32_t val) {
    return current * 31 + val;
  }

 private:
  void BuildHash(uint32_t val);
  void CalculateConstructorFingerprint();
  void CalculateArgumentsFingerprint();
  void CalculateVariableDeclarationFingerprint();
  void CalculateStatementListFingerprint();
  void CalculateListOfExpressionsFingerprint();
  void CalculateListOfDartTypesFingerprint();
  void CalculateListOfVariableDeclarationsFingerprint();
  void CalculateStringReferenceFingerprint();
  void CalculateListOfStringsFingerprint();
  void CalculateTypeParameterFingerprint();
  void CalculateTypeParametersListFingerprint();
  void CalculateCanonicalNameFingerprint();
  void CalculateInitializerFingerprint();
  void CalculateDartTypeFingerprint();
  void CalculateOptionalDartTypeFingerprint();
  void CalculateInterfaceTypeFingerprint(bool simple);
  void CalculateFunctionTypeFingerprint(bool simple);
  void CalculateGetterNameFingerprint();
  void CalculateSetterNameFingerprint();
  void CalculateMethodNameFingerprint();
  void CalculateExpressionFingerprint();
  void CalculateStatementFingerprint();
  void CalculateFunctionNodeFingerprint();

  uint32_t hash_;
};

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
        constant_evaluator_(this),
        type_translator_(this, active_class_, /* finalize= */ true),
        current_script_id_(-1),
        record_for_script_id_(-1),
        record_token_positions_into_(NULL),
        record_yield_positions_into_(NULL),
#if defined(DART_USE_INTERPRETER)
        bytecode_metadata_helper_(this, &type_translator_, active_class_),
#endif  // defined(DART_USE_INTERPRETER)
        direct_call_metadata_helper_(this),
        inferred_type_metadata_helper_(this),
        procedure_attributes_metadata_helper_(this) {
  }

  StreamingFlowGraphBuilder(TranslationHelper* translation_helper,
                            Zone* zone,
                            const uint8_t* data_buffer,
                            intptr_t buffer_length,
                            intptr_t data_program_offset,
                            ActiveClass* active_class)
      : KernelReaderHelper(zone,
                           translation_helper,
                           data_buffer,
                           buffer_length,
                           data_program_offset),
        flow_graph_builder_(NULL),
        active_class_(active_class),
        constant_evaluator_(this),
        type_translator_(this, active_class_, /* finalize= */ true),
        current_script_id_(-1),
        record_for_script_id_(-1),
        record_token_positions_into_(NULL),
        record_yield_positions_into_(NULL),
#if defined(DART_USE_INTERPRETER)
        bytecode_metadata_helper_(this, &type_translator_, active_class_),
#endif  // defined(DART_USE_INTERPRETER)
        direct_call_metadata_helper_(this),
        inferred_type_metadata_helper_(this),
        procedure_attributes_metadata_helper_(this) {
  }

  StreamingFlowGraphBuilder(TranslationHelper* translation_helper,
                            const Script& script,
                            Zone* zone,
                            const ExternalTypedData& data,
                            intptr_t data_program_offset,
                            ActiveClass* active_class)
      : KernelReaderHelper(zone,
                           translation_helper,
                           script,
                           data,
                           data_program_offset),
        flow_graph_builder_(NULL),
        active_class_(active_class),
        constant_evaluator_(this),
        type_translator_(this, active_class_, /* finalize= */ true),
        current_script_id_(-1),
        record_for_script_id_(-1),
        record_token_positions_into_(NULL),
        record_yield_positions_into_(NULL),
#if defined(DART_USE_INTERPRETER)
        bytecode_metadata_helper_(this, &type_translator_, active_class_),
#endif  // defined(DART_USE_INTERPRETER)
        direct_call_metadata_helper_(this),
        inferred_type_metadata_helper_(this),
        procedure_attributes_metadata_helper_(this) {
  }

  virtual ~StreamingFlowGraphBuilder() {}

  bool NeedsDynamicInvocationForwarder(const Function& function);

  FlowGraph* BuildGraph();

  void ReportUnexpectedTag(const char* variant, Tag tag) override;

  Fragment BuildStatementAt(intptr_t kernel_offset);
  RawObject* BuildParameterDescriptor(intptr_t kernel_offset);
  RawObject* BuildAnnotations();
  RawObject* EvaluateMetadata(intptr_t kernel_offset);
  void CollectTokenPositionsFor(
      intptr_t script_index,
      intptr_t initial_script_index,
      intptr_t kernel_offset,
      GrowableArray<intptr_t>* record_token_positions_in,
      GrowableArray<intptr_t>* record_yield_positions_in);
  intptr_t SourceTableSize();
  String& SourceTableUriFor(intptr_t index);
  String& GetSourceFor(intptr_t index);
  RawTypedData* GetLineStartsFor(intptr_t index);

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

  intptr_t GetOffsetForSourceInfo(intptr_t index);

  Fragment BuildExpression(TokenPosition* position = NULL);
  Fragment BuildStatement();

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
  Function& FindMatchingFunctionAnyArgs(const Class& klass, const String& name);
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
                     const String& function_name);
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

  Fragment BuildArgumentTypeChecks(TypeChecksToBuild mode);

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

  Fragment TranslateCondition(bool* negate);
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
  void SetupFunctionParameters(ActiveClass* active_class,
                               const Class& klass,
                               const Function& function,
                               bool is_method,
                               bool is_closure,
                               FunctionNodeHelper* function_node_helper);

  void set_current_script_id(intptr_t id) override { current_script_id_ = id; }

  void RecordTokenPosition(TokenPosition position) override;
  void RecordYieldPosition(TokenPosition position) override;

  FlowGraphBuilder* flow_graph_builder_;
  ActiveClass* const active_class_;
  StreamingConstantEvaluator constant_evaluator_;
  TypeTranslator type_translator_;
  intptr_t current_script_id_;
  intptr_t record_for_script_id_;
  GrowableArray<intptr_t>* record_token_positions_into_;
  GrowableArray<intptr_t>* record_yield_positions_into_;
#if defined(DART_USE_INTERPRETER)
  BytecodeMetadataHelper bytecode_metadata_helper_;
#endif  // defined(DART_USE_INTERPRETER)
  DirectCallMetadataHelper direct_call_metadata_helper_;
  InferredTypeMetadataHelper inferred_type_metadata_helper_;
  ProcedureAttributesMetadataHelper procedure_attributes_metadata_helper_;

  friend class ClassHelper;
  friend class ConstantHelper;
  friend class KernelLoader;
  friend class SimpleExpressionConverter;
  friend class StreamingConstantEvaluator;
  friend class StreamingScopeBuilder;
};

// Helper class that reads a kernel Constant from binary.
class ConstantHelper {
 public:
  ConstantHelper(ActiveClass* active_class,
                 StreamingFlowGraphBuilder* builder,
                 TypeTranslator* type_translator,
                 TranslationHelper* translation_helper,
                 Zone* zone,
                 NameIndex skip_vmservice_library)
      : skip_vmservice_library_(skip_vmservice_library),
        active_class_(active_class),
        builder_(*builder),
        type_translator_(*type_translator),
        const_evaluator_(&builder_),
        translation_helper_(*translation_helper),
        zone_(zone),
        temp_type_(AbstractType::Handle(zone)),
        temp_type_arguments_(TypeArguments::Handle(zone)),
        temp_type_arguments2_(TypeArguments::Handle(zone)),
        temp_type_arguments3_(TypeArguments::Handle(zone)),
        temp_object_(Object::Handle(zone)),
        temp_array_(Array::Handle(zone)),
        temp_instance_(Instance::Handle(zone)),
        temp_field_(Field::Handle(zone)),
        temp_class_(Class::Handle(zone)),
        temp_function_(Function::Handle(zone)),
        temp_closure_(Closure::Handle(zone)),
        temp_context_(Context::Handle(zone)),
        temp_integer_(Integer::Handle(zone)) {}

  // Reads the constant table from the binary.
  //
  // This method assumes the Reader is positioned already at the constant table
  // and an active class scope is setup.
  const Array& ReadConstantTable();

 private:
  void InstantiateTypeArguments(const Class& receiver_class,
                                TypeArguments* type_arguments);

  // If [index] has `dart:vm_service` as a parent and we are skipping the VM
  // service library, this method returns `true`, otherwise `false`.
  bool ShouldSkipConstant(NameIndex index);

  NameIndex skip_vmservice_library_;
  ActiveClass* const active_class_;
  StreamingFlowGraphBuilder& builder_;
  TypeTranslator& type_translator_;
  StreamingConstantEvaluator const_evaluator_;
  TranslationHelper translation_helper_;
  Zone* zone_;
  AbstractType& temp_type_;
  TypeArguments& temp_type_arguments_;
  TypeArguments& temp_type_arguments2_;
  TypeArguments& temp_type_arguments3_;
  Object& temp_object_;
  Array& temp_array_;
  Instance& temp_instance_;
  Field& temp_field_;
  Class& temp_class_;
  Function& temp_function_;
  Closure& temp_closure_;
  Context& temp_context_;
  Integer& temp_integer_;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_
