// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_BINARY_FLOWGRAPH_H_
#define RUNTIME_VM_KERNEL_BINARY_FLOWGRAPH_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include <map>

#include "vm/kernel.h"
#include "vm/kernel_binary.h"
#include "vm/kernel_to_il.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class StreamingDartTypeTranslator {
 public:
  StreamingDartTypeTranslator(StreamingFlowGraphBuilder* builder,
                              bool finalize = false);

  // Can return a malformed type.
  AbstractType& BuildType();
  // Is guaranteed to be not malformed.
  AbstractType& BuildVariableType();

  // Will return `TypeArguments::null()` in case any of the arguments are
  // malformed.
  const TypeArguments& BuildTypeArguments(intptr_t length);

  // Will return `TypeArguments::null()` in case any of the arguments are
  // malformed.
  const TypeArguments& BuildInstantiatedTypeArguments(
      const dart::Class& receiver_class,
      intptr_t length);

  const Type& ReceiverType(const dart::Class& klass);

 private:
  // Can build a malformed type.
  void BuildTypeInternal();
  void BuildInterfaceType(bool simple);
  void BuildFunctionType(bool simple);
  void BuildTypeParameterType();

  class TypeParameterScope {
   public:
    TypeParameterScope(StreamingDartTypeTranslator* translator,
                       intptr_t parameters_offset,
                       intptr_t parameters_count)
        : parameters_offset_(parameters_offset),
          parameters_count_(parameters_count),
          outer_(translator->type_parameter_scope_),
          translator_(translator) {
      translator_->type_parameter_scope_ = this;
    }
    ~TypeParameterScope() {
      translator_->type_parameter_scope_ = outer_;
    }

    TypeParameterScope* outer() const { return outer_; }
    intptr_t parameters_offset() const { return parameters_offset_; }
    intptr_t parameters_count() const { return parameters_count_; }

   private:
    intptr_t parameters_offset_;
    intptr_t parameters_count_;
    TypeParameterScope* outer_;
    StreamingDartTypeTranslator* translator_;
  };

  intptr_t FindTypeParameterIndex(intptr_t parameters_offset,
                                  intptr_t parameters_count,
                                  intptr_t look_for);

  StreamingFlowGraphBuilder* builder_;
  TranslationHelper& translation_helper_;
  ActiveClass* active_class_;
  TypeParameterScope* type_parameter_scope_;
  Zone* zone_;
  AbstractType& result_;
  bool finalize_;

  friend class StreamingScopeBuilder;
};


class StreamingScopeBuilder {
 public:
  StreamingScopeBuilder(ParsedFunction* parsed_function,
                        intptr_t kernel_offset,
                        const uint8_t* buffer,
                        intptr_t buffer_length);

  virtual ~StreamingScopeBuilder();

  ScopeBuildingResult* BuildScopes();

 private:
  void VisitField();
  void ReadFieldUntilAnnotation(TokenPosition* position,
                                TokenPosition* end_position,
                                word* flags,
                                intptr_t* parent_offset);

  /**
   * Will read until the function node; as this is optional, will return the tag
   * (i.e. either kSomething or kNothing).
   */
  Tag ReadProcedureUntilFunctionNode(word* kind, intptr_t* parent_offset);
  void GetTypeParameterInfoForPossibleProcedure(
      intptr_t outermost_kernel_offset,
      bool* member_is_procedure,
      bool* is_factory_procedure,
      intptr_t* member_type_parameters,
      intptr_t* member_type_parameters_offset_start);
  void VisitProcedure();

  /**
   * Will return binary offset of parent class.
   */
  intptr_t ReadConstructorUntilFunctionNode();
  void VisitConstructor();

  void ReadClassUntilTypeParameters();
  void ReadClassUntilFields();

  void ReadFunctionNodeUntilTypeParameters(word* async_marker,
                                           word* dart_async_marker);
  void VisitFunctionNode();

  void DiscoverEnclosingElements(Zone* zone,
                                 const Function& function,
                                 Function* outermost_function,
                                 intptr_t* outermost_kernel_offset,
                                 intptr_t* parent_class_offset);
  intptr_t GetParentOffset(intptr_t offset);
  void GetTypeParameterInfoForClass(intptr_t class_offset,
                                    intptr_t* type_paremeter_counts,
                                    intptr_t* type_paremeter_offset);
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

  void EnterScope(intptr_t kernel_offset);
  void ExitScope(TokenPosition start_position, TokenPosition end_position);

  /**
   * This assumes that the reader is at a FunctionNode,
   * about to read the positional parameters.
   */
  void AddPositionalAndNamedParameters(intptr_t pos = 0);
  /**
   * This assumes that the reader is at a FunctionNode,
   * about to read a parameter (i.e. VariableDeclaration).
   */
  void AddVariableDeclarationParameter(intptr_t pos);

  LocalVariable* MakeVariable(TokenPosition declaration_pos,
                              TokenPosition token_pos,
                              const dart::String& name,
                              const AbstractType& type);

  void AddExceptionVariable(GrowableArray<LocalVariable*>* variables,
                            const char* prefix,
                            intptr_t nesting_depth);

  void AddTryVariables();
  void AddCatchVariables();
  void AddIteratorVariable();
  void AddSwitchVariable();

  StringIndex GetNameFromVariableDeclaration(intptr_t kernel_offset);

  // Record an assignment or reference to a variable.  If the occurrence is
  // in a nested function, ensure that the variable is handled properly as a
  // captured variable.
  void LookupVariable(intptr_t declaration_binary_offest);

  const dart::String& GenerateName(const char* prefix, intptr_t suffix);

  void HandleSpecialLoad(LocalVariable** variable, const dart::String& symbol);
  void LookupCapturedVariableByName(LocalVariable** variable,
                                    const dart::String& name);

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
  intptr_t kernel_offset_;

  ActiveClass active_class_;

  TranslationHelper translation_helper_;
  Zone* zone_;

  FunctionNode::AsyncMarker current_function_async_marker_;
  LocalScope* current_function_scope_;
  LocalScope* scope_;
  DepthState depth_;

  intptr_t name_index_;

  bool needs_expr_temp_;
  TokenPosition first_body_token_position_;

  StreamingFlowGraphBuilder* builder_;
  StreamingDartTypeTranslator type_translator_;

  word unused_word;
  intptr_t unused_intptr;
  TokenPosition unused_tokenposition;
};


class StreamingConstantEvaluator {
 public:
  explicit StreamingConstantEvaluator(StreamingFlowGraphBuilder* builder);

  virtual ~StreamingConstantEvaluator() {}

  Instance& EvaluateExpression(intptr_t offset, bool reset_position = true);
  Instance& EvaluateListLiteral(intptr_t offset, bool reset_position = true);
  Instance& EvaluateMapLiteral(intptr_t offset, bool reset_position = true);
  Instance& EvaluateConstructorInvocation(intptr_t offset,
                                          bool reset_position = true);
  Object& EvaluateExpressionSafe(intptr_t offset);

 private:
  void EvaluateVariableGet();
  void EvaluateVariableGet(uint8_t payload);
  void EvaluatePropertyGet();
  void EvaluateStaticGet();
  void EvaluateMethodInvocation();
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
  void EvaluateBigIntLiteral();
  void EvaluateStringLiteral();
  void EvaluateIntLiteral(uint8_t payload);
  void EvaluateIntLiteral(bool is_negative);
  void EvaluateDoubleLiteral();
  void EvaluateBoolLiteral(bool value);
  void EvaluateNullLiteral();

  const Object& RunFunction(const Function& function,
                            intptr_t argument_count,
                            const Instance* receiver,
                            const TypeArguments* type_args);

  const Object& RunFunction(const Function& function,
                            const Array& arguments,
                            const Array& names);

  RawObject* EvaluateConstConstructorCall(const dart::Class& type_class,
                                          const TypeArguments& type_arguments,
                                          const Function& constructor,
                                          const Object& argument);

  const TypeArguments* TranslateTypeArguments(const Function& target,
                                              dart::Class* target_klass);

  void AssertBoolInCheckedMode() {
    if (isolate_->type_checks() && !result_.IsBool()) {
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
  StreamingDartTypeTranslator& type_translator_;

  Script& script_;
  Instance& result_;
};


class StreamingFlowGraphBuilder {
 public:
  StreamingFlowGraphBuilder(FlowGraphBuilder* flow_graph_builder,
                            const uint8_t* buffer,
                            intptr_t buffer_length)
      : flow_graph_builder_(flow_graph_builder),
        translation_helper_(flow_graph_builder->translation_helper_),
        zone_(flow_graph_builder->zone_),
        reader_(new Reader(buffer, buffer_length)),
        constant_evaluator_(this),
        type_translator_(this, /* finalize= */ true) {}

  ~StreamingFlowGraphBuilder() { delete reader_; }

  Fragment BuildExpressionAt(intptr_t kernel_offset);
  Fragment BuildStatementAt(intptr_t kernel_offset);

 private:
  StreamingFlowGraphBuilder(TranslationHelper* translation_helper,
                            Zone* zone,
                            const uint8_t* buffer,
                            intptr_t buffer_length)
      : flow_graph_builder_(NULL),
        translation_helper_(*translation_helper),
        zone_(zone),
        reader_(new Reader(buffer, buffer_length)),
        constant_evaluator_(this),
        type_translator_(this, /* finalize= */ true) {}

  Fragment BuildExpression(TokenPosition* position = NULL);
  Fragment BuildStatement();

  intptr_t ReaderOffset();
  void SetOffset(intptr_t offset);
  void SkipBytes(intptr_t skip);
  bool ReadBool();
  uint8_t ReadByte();
  uint32_t ReadUInt();
  uint32_t PeekUInt();
  intptr_t ReadListLength();
  StringIndex ReadStringReference();
  NameIndex ReadCanonicalNameReference();
  StringIndex ReadNameAsStringIndex();
  const dart::String& ReadNameAsMethodName();
  const dart::String& ReadNameAsGetterName();
  const dart::String& ReadNameAsSetterName();
  void SkipStringReference();
  void SkipCanonicalNameReference();
  void SkipDartType();
  void SkipOptionalDartType();
  void SkipInterfaceType(bool simple);
  void SkipFunctionType(bool simple);
  void SkipListOfExpressions();
  void SkipListOfDartTypes();
  void SkipListOfVariableDeclarations();
  void SkipTypeParametersList();
  void SkipExpression();
  void SkipStatement();
  void SkipFunctionNode();
  void SkipName();
  void SkipArguments();
  void SkipVariableDeclaration();
  TokenPosition ReadPosition(bool record = true);
  Tag ReadTag(uint8_t* payload = NULL);
  Tag PeekTag(uint8_t* payload = NULL);
  word ReadFlags();

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
  ParsedFunction* parsed_function();
  TryFinallyBlock* try_finally_block();
  SwitchBlock* switch_block();
  BreakableBlock* breakable_block();
  GrowableArray<YieldContinuation>& yield_continuations();
  Value* stack();
  Value* Pop();

  Tag PeekArgumentsFirstPositionalTag();
  const TypeArguments& PeekArgumentsInstantiatedType(const dart::Class& klass);
  intptr_t PeekArgumentsCount();
  intptr_t PeekArgumentsTypeCount();
  void SkipArgumentsBeforeActualArguments();

  LocalVariable* LookupVariable(intptr_t kernel_offset);
  LocalVariable* MakeTemporary();
  Token::Kind MethodKind(const dart::String& name);
  dart::RawFunction* LookupMethodByMember(NameIndex target,
                                          const dart::String& method_name);

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
  Fragment StaticCall(TokenPosition position,
                      const Function& target,
                      intptr_t argument_count);
  Fragment StaticCall(TokenPosition position,
                      const Function& target,
                      intptr_t argument_count,
                      const Array& argument_names);
  Fragment InstanceCall(TokenPosition position,
                        const dart::String& name,
                        Token::Kind kind,
                        intptr_t argument_count,
                        intptr_t num_args_checked = 1);
  Fragment InstanceCall(TokenPosition position,
                        const dart::String& name,
                        Token::Kind kind,
                        intptr_t argument_count,
                        const Array& argument_names,
                        intptr_t num_args_checked);
  Fragment ThrowException(TokenPosition position);
  Fragment BooleanNegate();
  Fragment TranslateInstantiatedTypeArguments(
      const TypeArguments& type_arguments);
  Fragment StrictCompare(Token::Kind kind, bool number_check = false);
  Fragment AllocateObject(const dart::Class& klass, intptr_t argument_count);
  Fragment StoreLocal(TokenPosition position, LocalVariable* variable);
  Fragment StoreStaticField(TokenPosition position, const dart::Field& field);
  Fragment StringInterpolate(TokenPosition position);
  Fragment StringInterpolateSingle(TokenPosition position);
  Fragment ThrowTypeError();
  Fragment LoadInstantiatorTypeArguments();
  Fragment LoadFunctionTypeArguments();
  Fragment InstantiateType(const AbstractType& type);
  Fragment CreateArray();
  Fragment StoreIndexed(intptr_t class_id);
  Fragment CheckStackOverflow();
  Fragment CloneContext();
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
                           bool needs_stacktrace);
  Fragment TryCatch(int try_handler_index);
  Fragment Drop();
  Fragment NullConstant();
  JoinEntryInstr* BuildJoinEntry();
  JoinEntryInstr* BuildJoinEntry(intptr_t try_index);
  Fragment Goto(JoinEntryInstr* destination);
  Fragment BuildImplicitClosureCreation(const Function& target);
  Fragment CheckBooleanInCheckedMode();
  Fragment CheckAssignableInCheckedMode(const dart::AbstractType& dst_type,
                                        const dart::String& dst_name);
  Fragment CheckVariableTypeInCheckedMode(intptr_t variable_kernel_position);
  Fragment CheckVariableTypeInCheckedMode(const AbstractType& dst_type,
                                          const dart::String& name_symbol);
  Fragment EnterScope(intptr_t kernel_offset, bool* new_context = NULL);
  Fragment ExitScope(intptr_t kernel_offset);

  Fragment TranslateCondition(bool* negate);
  const TypeArguments& BuildTypeArguments();
  Fragment BuildArguments(Array* argument_names,
                          intptr_t* argument_count,
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
  Fragment BuildDirectPropertyGet(TokenPosition* position);
  Fragment BuildDirectPropertySet(TokenPosition* position);
  Fragment BuildStaticGet(TokenPosition* position);
  Fragment BuildStaticSet(TokenPosition* position);
  Fragment BuildMethodInvocation(TokenPosition* position);
  Fragment BuildDirectMethodInvocation(TokenPosition* position);
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
  Fragment BuildLet(TokenPosition* position);
  Fragment BuildBigIntLiteral(TokenPosition* position);
  Fragment BuildStringLiteral(TokenPosition* position);
  Fragment BuildIntLiteral(uint8_t payload, TokenPosition* position);
  Fragment BuildIntLiteral(bool is_negative, TokenPosition* position);
  Fragment BuildDoubleLiteral(TokenPosition* position);
  Fragment BuildBoolLiteral(bool value, TokenPosition* position);
  Fragment BuildNullLiteral(TokenPosition* position);

  Fragment BuildInvalidStatement();
  Fragment BuildExpressionStatement();
  Fragment BuildBlock();
  Fragment BuildEmptyStatement();
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

  FlowGraphBuilder* flow_graph_builder_;
  TranslationHelper& translation_helper_;
  Zone* zone_;
  Reader* reader_;
  StreamingConstantEvaluator constant_evaluator_;
  StreamingDartTypeTranslator type_translator_;

  friend class StreamingConstantEvaluator;
  friend class StreamingDartTypeTranslator;
  friend class StreamingScopeBuilder;
};

// A helper class that saves the current reader position, goes to another reader
// position, and upon destruction, resets to the original reader position.
class AlternativeReadingScope {
 public:
  AlternativeReadingScope(Reader* reader, intptr_t new_position)
      : reader_(reader), saved_offset_(reader_->offset()) {
    reader_->set_offset(new_position);
  }

  explicit AlternativeReadingScope(Reader* reader)
      : reader_(reader), saved_offset_(reader_->offset()) {}

  ~AlternativeReadingScope() { reader_->set_offset(saved_offset_); }

 private:
  Reader* reader_;
  intptr_t saved_offset_;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_BINARY_FLOWGRAPH_H_
