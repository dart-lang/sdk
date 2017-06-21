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
  // Can return a malformed type.
  AbstractType& BuildTypeWithoutFinalization();
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
  friend class KernelReader;
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

class FunctionNodeHelper;

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

  ~StreamingFlowGraphBuilder() { delete reader_; }

  FlowGraph* BuildGraph(intptr_t kernel_offset);

  Fragment BuildStatementAt(intptr_t kernel_offset);
  RawObject* BuildParameterDescriptor(intptr_t kernel_offset);
  RawObject* EvaluateMetadata(intptr_t kernel_offset);

 private:
  void DiscoverEnclosingElements(Zone* zone,
                                 const Function& function,
                                 Function* outermost_function,
                                 intptr_t* outermost_kernel_offset,
                                 intptr_t* parent_class_offset);
  intptr_t GetParentOffset(intptr_t offset);
  void GetTypeParameterInfoForClass(intptr_t class_offset,
                                    intptr_t* type_paremeter_counts,
                                    intptr_t* type_paremeter_offset);

  void GetTypeParameterInfoForPossibleProcedure(
      intptr_t outermost_kernel_offset,
      bool* member_is_procedure,
      bool* is_factory_procedure,
      intptr_t* member_type_parameters,
      intptr_t* member_type_parameters_offset_start);
  /**
   * Will return kernel offset for parent class if reading a constructor.
   * Will otherwise return -1.
   */
  intptr_t ReadUntilFunctionNode();
  StringIndex GetNameFromVariableDeclaration(intptr_t kernel_offset);

  FlowGraph* BuildGraphOfStaticFieldInitializer();
  FlowGraph* BuildGraphOfFieldAccessor(LocalVariable* setter_value);
  void SetupDefaultParameterValues();
  Fragment BuildFieldInitializer(NameIndex canonical_name);
  Fragment BuildInitializers(intptr_t constructor_class_parent_offset);
  FlowGraph* BuildGraphOfImplicitClosureFunction(const Function& function);
  FlowGraph* BuildGraphOfFunction(
      bool is_in_builtin_library_toplevel,
      intptr_t constructor_class_parent_offset = -1);
  Fragment BuildGetMainClosure();

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
  const dart::String& ReadNameAsFieldName();
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
  void set_scopes(ScopeBuildingResult* scope);
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
  Fragment AllocateObject(TokenPosition position,
                          const dart::Class& klass,
                          intptr_t argument_count);
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
  Fragment BuildFunctionExpression();
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
  Fragment BuildFunctionDeclaration();
  Fragment BuildFunctionNode(intptr_t parent_kernel_offset,
                             TokenPosition parent_position,
                             bool declaration,
                             intptr_t variable_offeset);
  void SetupFunctionParameters(const dart::Class& klass,
                               const dart::Function& function,
                               bool is_method,
                               bool is_closure,
                               FunctionNodeHelper* function_node_helper);

  FlowGraphBuilder* flow_graph_builder_;
  TranslationHelper& translation_helper_;
  Zone* zone_;
  Reader* reader_;
  StreamingConstantEvaluator constant_evaluator_;
  StreamingDartTypeTranslator type_translator_;

  friend class StreamingConstantEvaluator;
  friend class StreamingDartTypeTranslator;
  friend class StreamingScopeBuilder;
  friend class FunctionNodeHelper;
  friend class VariableDeclarationHelper;
  friend class FieldHelper;
  friend class ProcedureHelper;
  friend class ClassHelper;
  friend class ConstructorHelper;
  friend class SimpleExpressionConverter;
  friend class KernelReader;
};

// Helper class that reads a kernel FunctionNode from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// "Dumb" fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a "non-dumb" field (e.g. an expression) it will be skipped.
class FunctionNodeHelper {
 public:
  enum Fields {
    kStart,  // tag.
    kPosition,
    kEndPosition,
    kAsyncMarker,
    kDartAsyncMarker,
    kTypeParameters,
    kTotalParameterCount,
    kRequiredParameterCount,
    kPositionalParameters,
    kNamedParameters,
    kReturnType,
    kBody,
    kEnd
  };

  explicit FunctionNodeHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kStart;
  }

  void ReadUntilIncluding(Fields field) {
    ReadUntilExcluding(static_cast<Fields>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Fields field) {
    if (field <= next_read_) return;

    // Ordered with fall-through.
    switch (next_read_) {
      case kStart: {
        Tag tag = builder_->ReadTag();  // read tag.
        ASSERT(tag == kFunctionNode);
        if (++next_read_ == field) return;
      }
      case kPosition:
        position_ = builder_->ReadPosition();  // read position.
        if (++next_read_ == field) return;
      case kEndPosition:
        end_position_ = builder_->ReadPosition();  // read end position.
        if (++next_read_ == field) return;
      case kAsyncMarker:
        async_marker_ = static_cast<FunctionNode::AsyncMarker>(
            builder_->ReadByte());  // read async marker.
        if (++next_read_ == field) return;
      case kDartAsyncMarker:
        dart_async_marker_ = static_cast<FunctionNode::AsyncMarker>(
            builder_->ReadByte());  // read dart async marker.
        if (++next_read_ == field) return;
      case kTypeParameters:
        builder_->SkipTypeParametersList();  // read type parameters.
        if (++next_read_ == field) return;
      case kTotalParameterCount:
        total_parameter_count_ =
            builder_->ReadUInt();  // read total parameter count.
        if (++next_read_ == field) return;
      case kRequiredParameterCount:
        required_parameter_count_ =
            builder_->ReadUInt();  // read required parameter count.
        if (++next_read_ == field) return;
      case kPositionalParameters:
        builder_->SkipListOfVariableDeclarations();  // read positionals.
        if (++next_read_ == field) return;
      case kNamedParameters:
        builder_->SkipListOfVariableDeclarations();  // read named.
        if (++next_read_ == field) return;
      case kReturnType:
        builder_->SkipDartType();  // read return type.
        if (++next_read_ == field) return;
      case kBody:
        if (builder_->ReadTag() == kSomething)
          builder_->SkipStatement();  // read body.
        if (++next_read_ == field) return;
      case kEnd:
        return;
    }
  }

  void SetNext(Fields field) { next_read_ = field; }
  void SetJustRead(Fields field) {
    next_read_ = field;
    ++next_read_;
  }

  TokenPosition position_;
  TokenPosition end_position_;
  FunctionNode::AsyncMarker async_marker_;
  FunctionNode::AsyncMarker dart_async_marker_;
  intptr_t total_parameter_count_;
  intptr_t required_parameter_count_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
};

// Helper class that reads a kernel VariableDeclaration from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// "Dumb" fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a "non-dumb" field (e.g. an expression) it will be skipped.
class VariableDeclarationHelper {
 public:
  enum Fields {
    kPosition,
    kEqualPosition,
    kFlags,
    kNameIndex,
    kType,
    kInitializer,
    kEnd
  };

  explicit VariableDeclarationHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kPosition;
  }

  void ReadUntilIncluding(Fields field) {
    ReadUntilExcluding(static_cast<Fields>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Fields field) {
    if (field <= next_read_) return;

    // Ordered with fall-through.
    switch (next_read_) {
      case kPosition:
        position_ = builder_->ReadPosition();  // read position.
        if (++next_read_ == field) return;
      case kEqualPosition:
        equals_position_ = builder_->ReadPosition();  // read equals position.
        if (++next_read_ == field) return;
      case kFlags:
        flags_ = builder_->ReadFlags();  // read flags.
        if (++next_read_ == field) return;
      case kNameIndex:
        name_index_ = builder_->ReadStringReference();  // read name index.
        if (++next_read_ == field) return;
      case kType:
        builder_->SkipDartType();  // read type.
        if (++next_read_ == field) return;
      case kInitializer:
        if (builder_->ReadTag() == kSomething)
          builder_->SkipExpression();  // read initializer.
        if (++next_read_ == field) return;
      case kEnd:
        return;
    }
  }

  void SetNext(Fields field) { next_read_ = field; }
  void SetJustRead(Fields field) {
    next_read_ = field;
    ++next_read_;
  }

  bool IsConst() {
    return (flags_ & VariableDeclaration::kFlagConst) ==
           VariableDeclaration::kFlagConst;
  }
  bool IsFinal() {
    return (flags_ & VariableDeclaration::kFlagFinal) ==
           VariableDeclaration::kFlagFinal;
  }

  TokenPosition position_;
  TokenPosition equals_position_;
  word flags_;
  StringIndex name_index_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
};

// Helper class that reads a kernel Field from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// "Dumb" fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a "non-dumb" field (e.g. an expression) it will be skipped.
class FieldHelper {
 public:
  enum Fields {
    kStart,  // tag.
    kCanonicalName,
    kPosition,
    kEndPosition,
    kFlags,
    kParentClassBinaryOffset,
    kName,
    kSourceUriIndex,
    kAnnotations,
    kType,
    kInitializer,
    kEnd
  };

  explicit FieldHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kStart;
  }

  void ReadUntilIncluding(Fields field) {
    ReadUntilExcluding(static_cast<Fields>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Fields field) {
    if (field <= next_read_) return;

    // Ordered with fall-through.
    switch (next_read_) {
      case kStart: {
        Tag tag = builder_->ReadTag();  // read tag.
        ASSERT(tag == kField);
        if (++next_read_ == field) return;
      }
      case kCanonicalName:
        canonical_name_ =
            builder_->ReadCanonicalNameReference();  // read canonical_name.
        if (++next_read_ == field) return;
      case kPosition:
        position_ = builder_->ReadPosition();  // read position.
        if (++next_read_ == field) return;
      case kEndPosition:
        end_position_ = builder_->ReadPosition();  // read end position.
        if (++next_read_ == field) return;
      case kFlags:
        flags_ = builder_->ReadFlags();  // read flags.
        if (++next_read_ == field) return;
      case kParentClassBinaryOffset:
        parent_class_binary_offset_ =
            builder_->ReadUInt();  // read parent class binary offset.
        if (++next_read_ == field) return;
      case kName:
        builder_->SkipName();  // read name.
        if (++next_read_ == field) return;
      case kSourceUriIndex:
        source_uri_index_ = builder_->ReadUInt();  // read source_uri_index.
        if (++next_read_ == field) return;
      case kAnnotations:
        builder_->SkipListOfExpressions();  // read annotations.
        if (++next_read_ == field) return;
      case kType:
        builder_->SkipDartType();  // read type.
        if (++next_read_ == field) return;
      case kInitializer:
        if (builder_->ReadTag() == kSomething)
          builder_->SkipExpression();  // read initializer.
        if (++next_read_ == field) return;
      case kEnd:
        return;
    }
  }

  void SetNext(Fields field) { next_read_ = field; }
  void SetJustRead(Fields field) {
    next_read_ = field;
    ++next_read_;
  }

  bool IsConst() { return (flags_ & Field::kFlagConst) == Field::kFlagConst; }
  bool IsFinal() { return (flags_ & Field::kFlagFinal) == Field::kFlagFinal; }
  bool IsStatic() {
    return (flags_ & Field::kFlagStatic) == Field::kFlagStatic;
  }

  NameIndex canonical_name_;
  TokenPosition position_;
  TokenPosition end_position_;
  word flags_;
  intptr_t parent_class_binary_offset_;
  intptr_t source_uri_index_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
};


// Helper class that reads a kernel Procedure from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// "Dumb" fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a "non-dumb" field (e.g. an expression) it will be skipped.
class ProcedureHelper {
 public:
  enum Fields {
    kStart,  // tag.
    kCanonicalName,
    kPosition,
    kEndPosition,
    kKind,
    kFlags,
    kParentClassBinaryOffset,
    kName,
    kSourceUriIndex,
    kAnnotations,
    kFunction,
    kEnd
  };

  explicit ProcedureHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kStart;
  }

  void ReadUntilIncluding(Fields field) {
    ReadUntilExcluding(static_cast<Fields>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Fields field) {
    if (field <= next_read_) return;

    // Ordered with fall-through.
    switch (next_read_) {
      case kStart: {
        Tag tag = builder_->ReadTag();  // read tag.
        ASSERT(tag == kProcedure);
        if (++next_read_ == field) return;
      }
      case kCanonicalName:
        canonical_name_ =
            builder_->ReadCanonicalNameReference();  // read canonical_name.
        if (++next_read_ == field) return;
      case kPosition:
        position_ = builder_->ReadPosition();  // read position.
        if (++next_read_ == field) return;
      case kEndPosition:
        end_position_ = builder_->ReadPosition();  // read end position.
        if (++next_read_ == field) return;
      case kKind:
        kind_ = static_cast<Procedure::ProcedureKind>(
            builder_->ReadByte());  // read kind.
        if (++next_read_ == field) return;
      case kFlags:
        flags_ = builder_->ReadFlags();  // read flags.
        if (++next_read_ == field) return;
      case kParentClassBinaryOffset:
        parent_class_binary_offset_ =
            builder_->ReadUInt();  // read parent class binary offset.
        if (++next_read_ == field) return;
      case kName:
        builder_->SkipName();  // read name.
        if (++next_read_ == field) return;
      case kSourceUriIndex:
        source_uri_index_ = builder_->ReadUInt();  // read source_uri_index.
        if (++next_read_ == field) return;
      case kAnnotations:
        builder_->SkipListOfExpressions();  // read annotations.
        if (++next_read_ == field) return;
      case kFunction:
        if (builder_->ReadTag() == kSomething)
          builder_->SkipFunctionNode();  // read function node.
        if (++next_read_ == field) return;
      case kEnd:
        return;
    }
  }

  void SetNext(Fields field) { next_read_ = field; }
  void SetJustRead(Fields field) {
    next_read_ = field;
    ++next_read_;
  }

  bool IsStatic() {
    return (flags_ & Procedure::kFlagStatic) == Procedure::kFlagStatic;
  }
  bool IsAbstract() {
    return (flags_ & Procedure::kFlagAbstract) == Procedure::kFlagAbstract;
  }
  bool IsExternal() {
    return (flags_ & Procedure::kFlagExternal) == Procedure::kFlagExternal;
  }
  bool IsConst() {
    return (flags_ & Procedure::kFlagConst) == Procedure::kFlagConst;
  }

  NameIndex canonical_name_;
  TokenPosition position_;
  TokenPosition end_position_;
  Procedure::ProcedureKind kind_;
  word flags_;
  intptr_t parent_class_binary_offset_;
  intptr_t source_uri_index_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
};

// Helper class that reads a kernel Constructor from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// "Dumb" fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a "non-dumb" field (e.g. an expression) it will be skipped.
class ConstructorHelper {
 public:
  enum Fields {
    kStart,  // tag.
    kCanonicalName,
    kPosition,
    kEndPosition,
    kFlags,
    kParentClassBinaryOffset,
    kName,
    kAnnotations,
    kFunction,
    kInitializers,
    kEnd
  };

  explicit ConstructorHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kStart;
  }

  void ReadUntilIncluding(Fields field) {
    ReadUntilExcluding(static_cast<Fields>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Fields field) {
    if (field <= next_read_) return;

    // Ordered with fall-through.
    switch (next_read_) {
      case kStart: {
        Tag tag = builder_->ReadTag();  // read tag.
        ASSERT(tag == kConstructor);
        if (++next_read_ == field) return;
      }
      case kCanonicalName:
        canonical_name_ =
            builder_->ReadCanonicalNameReference();  // read canonical_name.
        if (++next_read_ == field) return;
      case kPosition:
        position_ = builder_->ReadPosition();  // read position.
        if (++next_read_ == field) return;
      case kEndPosition:
        end_position_ = builder_->ReadPosition();  // read end position.
        if (++next_read_ == field) return;
      case kFlags:
        flags_ = builder_->ReadFlags();  // read flags.
        if (++next_read_ == field) return;
      case kParentClassBinaryOffset:
        parent_class_binary_offset_ =
            builder_->ReadUInt();  // read parent class binary offset.
        if (++next_read_ == field) return;
      case kName:
        builder_->SkipName();  // read name.
        if (++next_read_ == field) return;
      case kAnnotations:
        builder_->SkipListOfExpressions();  // read annotations.
        if (++next_read_ == field) return;
      case kFunction:
        builder_->SkipFunctionNode();  // read function.
        if (++next_read_ == field) return;
      case kInitializers: {
        intptr_t list_length =
            builder_->ReadListLength();  // read initializers list length.
        for (intptr_t i = 0; i < list_length; i++) {
          Tag tag = builder_->ReadTag();
          switch (tag) {
            case kInvalidInitializer:
              continue;
            case kFieldInitializer:
              builder_->SkipCanonicalNameReference();  // read field_reference.
              builder_->SkipExpression();              // read value.
              continue;
            case kSuperInitializer:
              builder_->SkipCanonicalNameReference();  // read target_reference.
              builder_->SkipArguments();               // read arguments.
              continue;
            case kRedirectingInitializer:
              builder_->SkipCanonicalNameReference();  // read target_reference.
              builder_->SkipArguments();               // read arguments.
              continue;
            case kLocalInitializer:
              builder_->SkipVariableDeclaration();  // read variable.
              continue;
            default:
              UNREACHABLE();
          }
        }
        if (++next_read_ == field) return;
      }
      case kEnd:
        return;
    }
  }

  void SetNext(Fields field) { next_read_ = field; }
  void SetJustRead(Fields field) {
    next_read_ = field;
    ++next_read_;
  }

  bool IsExternal() {
    return (flags_ & Constructor::kFlagExternal) == Constructor::kFlagExternal;
  }
  bool IsConst() {
    return (flags_ & Constructor::kFlagConst) == Constructor::kFlagConst;
  }

  NameIndex canonical_name_;
  TokenPosition position_;
  TokenPosition end_position_;
  word flags_;
  intptr_t parent_class_binary_offset_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
};

// Helper class that reads a kernel Class from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// "Dumb" fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a "non-dumb" field (e.g. an expression) it will be skipped.
class ClassHelper {
 public:
  enum Fields {
    kStart,  // tag.
    kCanonicalName,
    kPosition,
    kIsAbstract,
    kNameIndex,
    kSourceUriIndex,
    kAnnotations,
    kTypeParameters,
    kSuperClass,
    kMixinType,
    kImplementedClasses,
    kFields,
    kConstructors,
    kProcedures,
    kEnd
  };

  explicit ClassHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kStart;
  }

  void ReadUntilIncluding(Fields field) {
    ReadUntilExcluding(static_cast<Fields>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Fields field) {
    if (field <= next_read_) return;

    // Ordered with fall-through.
    switch (next_read_) {
      case kStart: {
        Tag tag = builder_->ReadTag();  // read tag.
        ASSERT(tag == kClass);
        if (++next_read_ == field) return;
      }
      case kCanonicalName:
        canonical_name_ =
            builder_->ReadCanonicalNameReference();  // read canonical_name.
        if (++next_read_ == field) return;
      case kPosition:
        position_ = builder_->ReadPosition();  // read position.
        if (++next_read_ == field) return;
      case kIsAbstract:
        is_abstract_ = builder_->ReadBool();  // read is_abstract.
        if (++next_read_ == field) return;
      case kNameIndex:
        name_index_ = builder_->ReadStringReference();  // read name index.
        if (++next_read_ == field) return;
      case kSourceUriIndex:
        source_uri_index_ = builder_->ReadUInt();  // read source_uri_index.
        if (++next_read_ == field) return;
      case kAnnotations:
        builder_->SkipListOfExpressions();  // read annotations.
        if (++next_read_ == field) return;
      case kTypeParameters:
        builder_->SkipTypeParametersList();  // read type parameters.
        if (++next_read_ == field) return;
      case kSuperClass: {
        Tag type_tag = builder_->ReadTag();  // read super class type (part 1).
        if (type_tag == kSomething) {
          builder_->SkipDartType();  // read super class type (part 2).
        }
        if (++next_read_ == field) return;
      }
      case kMixinType: {
        Tag type_tag = builder_->ReadTag();  // read mixin type (part 1).
        if (type_tag == kSomething) {
          builder_->SkipDartType();  // read mixin type (part 2).
        }
        if (++next_read_ == field) return;
      }
      case kImplementedClasses:
        builder_->SkipListOfDartTypes();  // read implemented_classes.
        if (++next_read_ == field) return;
      case kFields: {
        intptr_t list_length =
            builder_->ReadListLength();  // read fields list length.
        for (intptr_t i = 0; i < list_length; i++) {
          FieldHelper field_helper(builder_);
          field_helper.ReadUntilExcluding(FieldHelper::kEnd);  // read field.
        }
        if (++next_read_ == field) return;
      }
      case kConstructors: {
        intptr_t list_length =
            builder_->ReadListLength();  // read constructors list length.
        for (intptr_t i = 0; i < list_length; i++) {
          ConstructorHelper constructor_helper(builder_);
          constructor_helper.ReadUntilExcluding(
              ConstructorHelper::kEnd);  // read constructor.
        }
        if (++next_read_ == field) return;
      }
      case kProcedures: {
        intptr_t list_length =
            builder_->ReadListLength();  // read procedures list length.
        for (intptr_t i = 0; i < list_length; i++) {
          ProcedureHelper procedure_helper(builder_);
          procedure_helper.ReadUntilExcluding(
              ProcedureHelper::kEnd);  // read procedure.
        }
        if (++next_read_ == field) return;
      }
      case kEnd:
        return;
    }
  }

  void SetNext(Fields field) { next_read_ = field; }
  void SetJustRead(Fields field) {
    next_read_ = field;
    ++next_read_;
  }

  NameIndex canonical_name_;
  TokenPosition position_;
  bool is_abstract_;
  StringIndex name_index_;
  intptr_t source_uri_index_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
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

  intptr_t saved_offset() { return saved_offset_; }

 private:
  Reader* reader_;
  intptr_t saved_offset_;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_BINARY_FLOWGRAPH_H_
