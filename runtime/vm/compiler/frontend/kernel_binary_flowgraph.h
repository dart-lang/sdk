// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_
#define RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include <map>

#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/kernel.h"
#include "vm/kernel_binary.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

// Helper class that reads a kernel FunctionNode from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// Simple fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a compound field (e.g. an expression) it will be skipped.
class FunctionNodeHelper {
 public:
  enum Field {
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
    kEnd,
  };

  enum AsyncMarker {
    kSync = 0,
    kSyncStar = 1,
    kAsync = 2,
    kAsyncStar = 3,
    kSyncYielding = 4,
  };

  explicit FunctionNodeHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kStart;
  }

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  TokenPosition position_;
  TokenPosition end_position_;
  AsyncMarker async_marker_;
  AsyncMarker dart_async_marker_;
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
// Simple fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a compound field (e.g. an expression) it will be skipped.
class VariableDeclarationHelper {
 public:
  enum Field {
    kPosition,
    kEqualPosition,
    kFlags,
    kNameIndex,
    kType,
    kInitializer,
    kEnd,
  };

  enum Flag {
    kFinal = 1 << 0,
    kConst = 1 << 1,
  };

  explicit VariableDeclarationHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kPosition;
  }

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsConst() { return (flags_ & kConst) != 0; }
  bool IsFinal() { return (flags_ & kFinal) != 0; }

  TokenPosition position_;
  TokenPosition equals_position_;
  uint8_t flags_;
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
// Simple fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a compound field (e.g. an expression) it will be skipped.
class FieldHelper {
 public:
  enum Field {
    kStart,  // tag.
    kCanonicalName,
    kPosition,
    kEndPosition,
    kFlags,
    kName,
    kSourceUriIndex,
    kDocumentationCommentIndex,
    kAnnotations,
    kType,
    kInitializer,
    kEnd,
  };

  enum Flag {
    kFinal = 1 << 0,
    kConst = 1 << 1,
    kStatic = 1 << 2,
  };

  explicit FieldHelper(StreamingFlowGraphBuilder* builder)
      : builder_(builder),
        next_read_(kStart),
        has_function_literal_initializer_(false) {}

  FieldHelper(StreamingFlowGraphBuilder* builder, intptr_t offset);

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field,
                          bool detect_function_literal_initializer = false);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsConst() { return (flags_ & kConst) != 0; }
  bool IsFinal() { return (flags_ & kFinal) != 0; }
  bool IsStatic() { return (flags_ & kStatic) != 0; }

  bool FieldHasFunctionLiteralInitializer(TokenPosition* start,
                                          TokenPosition* end) {
    if (has_function_literal_initializer_) {
      *start = function_literal_start_;
      *end = function_literal_end_;
    }
    return has_function_literal_initializer_;
  }

  NameIndex canonical_name_;
  TokenPosition position_;
  TokenPosition end_position_;
  uint8_t flags_;
  intptr_t source_uri_index_;
  intptr_t annotation_count_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;

  bool has_function_literal_initializer_;
  TokenPosition function_literal_start_;
  TokenPosition function_literal_end_;
};

// Helper class that reads a kernel Procedure from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// Simple fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a compound field (e.g. an expression) it will be skipped.
class ProcedureHelper {
 public:
  enum Field {
    kStart,  // tag.
    kCanonicalName,
    kPosition,
    kEndPosition,
    kKind,
    kFlags,
    kName,
    kSourceUriIndex,
    kDocumentationCommentIndex,
    kAnnotations,
    kFunction,
    kEnd,
  };

  enum Kind {
    kMethod,
    kGetter,
    kSetter,
    kOperator,
    kFactory,
  };

  enum Flag {
    kStatic = 1 << 0,
    kAbstract = 1 << 1,
    kExternal = 1 << 2,
    kConst = 1 << 3,  // Only for external const factories.
  };

  explicit ProcedureHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kStart;
  }

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsStatic() { return (flags_ & kStatic) != 0; }
  bool IsAbstract() { return (flags_ & kAbstract) != 0; }
  bool IsExternal() { return (flags_ & kExternal) != 0; }
  bool IsConst() { return (flags_ & kConst) != 0; }

  NameIndex canonical_name_;
  TokenPosition position_;
  TokenPosition end_position_;
  Kind kind_;
  uint8_t flags_;
  intptr_t source_uri_index_;
  intptr_t annotation_count_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
};

// Helper class that reads a kernel Constructor from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// Simple fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a compound field (e.g. an expression) it will be skipped.
class ConstructorHelper {
 public:
  enum Field {
    kStart,  // tag.
    kCanonicalName,
    kPosition,
    kEndPosition,
    kFlags,
    kName,
    kDocumentationCommentIndex,
    kAnnotations,
    kFunction,
    kInitializers,
    kEnd,
  };

  enum Flag {
    kConst = 1 << 0,
    kExternal = 1 << 1,
  };

  explicit ConstructorHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kStart;
  }

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsExternal() { return (flags_ & kExternal) != 0; }
  bool IsConst() { return (flags_ & kConst) != 0; }

  NameIndex canonical_name_;
  TokenPosition position_;
  TokenPosition end_position_;
  uint8_t flags_;
  intptr_t annotation_count_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
};

// Helper class that reads a kernel Class from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// Simple fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a compound field (e.g. an expression) it will be skipped.
class ClassHelper {
 public:
  enum Field {
    kStart,  // tag.
    kCanonicalName,
    kPosition,
    kEndPosition,
    kIsAbstract,
    kNameIndex,
    kSourceUriIndex,
    kDocumentationCommentIndex,
    kAnnotations,
    kTypeParameters,
    kSuperClass,
    kMixinType,
    kImplementedClasses,
    kFields,
    kConstructors,
    kProcedures,
    kClassIndex,
    kEnd,
  };

  explicit ClassHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kStart;
  }

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  NameIndex canonical_name_;
  TokenPosition position_;
  TokenPosition end_position_;
  bool is_abstract_;
  StringIndex name_index_;
  intptr_t source_uri_index_;
  intptr_t annotation_count_;
  intptr_t procedure_count_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
};

// Helper class that reads a kernel Library from binary.
//
// Use ReadUntilExcluding to read up to but not including a field.
// One can then for instance read the field from the call-site (and remember to
// call SetAt to inform this helper class), and then use this to read more.
// Simple fields are stored (e.g. integers) and can be fetched from this class.
// If asked to read a compound field (e.g. an expression) it will be skipped.
class LibraryHelper {
 public:
  enum Field {
    kFlags,
    kCanonicalName,
    kName,
    kDocumentation,
    kSourceUriIndex,
    kAnnotations,
    kDependencies,
    kAdditionalExports,
    kParts,
    kTypedefs,
    kClasses,
    kToplevelField,
    kToplevelProcedures,
    kLibraryIndex,
    kEnd,
  };

  enum Flag {
    kExternal = 1,
  };

  explicit LibraryHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kFlags;
  }

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsExternal() const { return (flags_ & kExternal) != 0; }

  uint8_t flags_;
  NameIndex canonical_name_;
  StringIndex name_index_;
  intptr_t source_uri_index_;
  intptr_t class_count_;
  intptr_t procedure_count_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
};

class LibraryDependencyHelper {
 public:
  enum Field {
    kFileOffset,
    kFlags,
    kAnnotations,
    kTargetLibrary,
    kName,
    kCombinators,
    kEnd,
  };

  enum Flag {
    Export = 1 << 0,
    Deferred = 1 << 1,
  };

  enum CombinatorFlag {
    Show = 1 << 0,
  };

  explicit LibraryDependencyHelper(StreamingFlowGraphBuilder* builder) {
    builder_ = builder;
    next_read_ = kFileOffset;
  }

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  uint8_t flags_;
  StringIndex name_index_;
  NameIndex target_library_canonical_name_;

 private:
  StreamingFlowGraphBuilder* builder_;
  intptr_t next_read_;
};

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
      const Class& receiver_class,
      intptr_t length);

  const Type& ReceiverType(const Class& klass);

 private:
  // Can build a malformed type.
  void BuildTypeInternal();
  void BuildInterfaceType(bool simple);
  void BuildFunctionType(bool simple);
  void BuildTypeParameterType();

  class TypeParameterScope {
   public:
    TypeParameterScope(StreamingDartTypeTranslator* translator,
                       intptr_t parameter_count)
        : parameter_count_(parameter_count),
          outer_(translator->type_parameter_scope_),
          translator_(translator) {
      outer_parameter_count_ = 0;
      if (outer_ != NULL) {
        outer_parameter_count_ =
            outer_->outer_parameter_count_ + outer_->parameter_count_;
      }
      translator_->type_parameter_scope_ = this;
    }
    ~TypeParameterScope() { translator_->type_parameter_scope_ = outer_; }

    TypeParameterScope* outer() const { return outer_; }
    intptr_t parameter_count() const { return parameter_count_; }
    intptr_t outer_parameter_count() const { return outer_parameter_count_; }

   private:
    intptr_t parameter_count_;
    intptr_t outer_parameter_count_;
    TypeParameterScope* outer_;
    StreamingDartTypeTranslator* translator_;
  };

  StreamingFlowGraphBuilder* builder_;
  TranslationHelper& translation_helper_;
  ActiveClass* active_class_;
  TypeParameterScope* type_parameter_scope_;
  Zone* zone_;
  AbstractType& result_;
  bool finalize_;

  friend class StreamingScopeBuilder;
  friend class KernelLoader;
};

class StreamingScopeBuilder {
 public:
  StreamingScopeBuilder(ParsedFunction* parsed_function,
                        intptr_t relative_kernel_offset,
                        const TypedData& data);

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
  void VisitVectorType();
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
                              const String& name,
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
  void LookupVariable(intptr_t declaration_binary_offset);

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
  intptr_t relative_kernel_offset_;

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
  void EvaluateDirectPropertyGet();
  void EvaluateStaticGet();
  void EvaluateMethodInvocation();
  void EvaluateDirectMethodInvocation();
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

  void EvaluateGetStringLength(intptr_t expression_offset);

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
  StreamingDartTypeTranslator& type_translator_;

  Script& script_;
  Instance& result_;
};

class StreamingFlowGraphBuilder {
 public:
  StreamingFlowGraphBuilder(FlowGraphBuilder* flow_graph_builder,
                            intptr_t relative_kernel_offset,
                            const TypedData& data)
      : flow_graph_builder_(flow_graph_builder),
        translation_helper_(flow_graph_builder->translation_helper_),
        zone_(flow_graph_builder->zone_),
        reader_(new Reader(data)),
        constant_evaluator_(this),
        type_translator_(this, /* finalize= */ true),
        relative_kernel_offset_(relative_kernel_offset),
        current_script_id_(-1),
        record_for_script_id_(-1),
        record_token_positions_into_(NULL),
        record_yield_positions_into_(NULL) {}

  StreamingFlowGraphBuilder(TranslationHelper* translation_helper,
                            Zone* zone,
                            const uint8_t* buffer,
                            intptr_t buffer_length)
      : flow_graph_builder_(NULL),
        translation_helper_(*translation_helper),
        zone_(zone),
        reader_(new Reader(buffer, buffer_length)),
        constant_evaluator_(this),
        type_translator_(this, /* finalize= */ true),
        relative_kernel_offset_(0),
        current_script_id_(-1),
        record_for_script_id_(-1),
        record_token_positions_into_(NULL),
        record_yield_positions_into_(NULL) {}

  StreamingFlowGraphBuilder(TranslationHelper* translation_helper,
                            Zone* zone,
                            intptr_t relative_kernel_offset,
                            const TypedData& data)
      : flow_graph_builder_(NULL),
        translation_helper_(*translation_helper),
        zone_(zone),
        reader_(new Reader(data)),
        constant_evaluator_(this),
        type_translator_(this, /* finalize= */ true),
        relative_kernel_offset_(relative_kernel_offset),
        current_script_id_(-1),
        record_for_script_id_(-1),
        record_token_positions_into_(NULL),
        record_yield_positions_into_(NULL) {}

  ~StreamingFlowGraphBuilder() { delete reader_; }

  FlowGraph* BuildGraph(intptr_t kernel_offset);

  Fragment BuildStatementAt(intptr_t kernel_offset);
  RawObject* BuildParameterDescriptor(intptr_t kernel_offset);
  RawObject* EvaluateMetadata(intptr_t kernel_offset);
  void CollectTokenPositionsFor(
      intptr_t script_index,
      intptr_t initial_script_index,
      GrowableArray<intptr_t>* record_token_positions_in,
      GrowableArray<intptr_t>* record_yield_positions_in);
  intptr_t SourceTableSize();
  String& SourceTableUriFor(intptr_t index);
  String& GetSourceFor(intptr_t index);
  Array& GetLineStartsFor(intptr_t index);

 private:
  void DiscoverEnclosingElements(Zone* zone,
                                 const Function& function,
                                 Function* outermost_function);

  void ReadUntilFunctionNode();
  StringIndex GetNameFromVariableDeclaration(intptr_t kernel_offset,
                                             const Function& function);

  FlowGraph* BuildGraphOfStaticFieldInitializer();
  FlowGraph* BuildGraphOfFieldAccessor(LocalVariable* setter_value);
  void SetupDefaultParameterValues();
  Fragment BuildFieldInitializer(NameIndex canonical_name);
  Fragment BuildInitializers(const Class& parent_class);
  FlowGraph* BuildGraphOfImplicitClosureFunction(const Function& function);
  FlowGraph* BuildGraphOfFunction(bool constructor);

  intptr_t GetOffsetForSourceInfo(intptr_t index);

  Fragment BuildExpression(TokenPosition* position = NULL);
  Fragment BuildStatement();

  intptr_t ReaderOffset();
  void SetOffset(intptr_t offset);
  void SkipBytes(intptr_t skip);
  bool ReadBool();
  uint8_t ReadByte();
  uint32_t ReadUInt();
  uint32_t ReadUInt32();
  uint32_t PeekUInt();
  uint32_t PeekListLength();
  intptr_t ReadListLength();
  StringIndex ReadStringReference();
  NameIndex ReadCanonicalNameReference();
  StringIndex ReadNameAsStringIndex();
  const String& ReadNameAsMethodName();
  const String& ReadNameAsGetterName();
  const String& ReadNameAsSetterName();
  const String& ReadNameAsFieldName();
  void SkipFlags();
  void SkipStringReference();
  void SkipCanonicalNameReference();
  void SkipDartType();
  void SkipOptionalDartType();
  void SkipInterfaceType(bool simple);
  void SkipFunctionType(bool simple);
  void SkipListOfExpressions();
  void SkipListOfDartTypes();
  void SkipListOfStrings();
  void SkipListOfVariableDeclarations();
  void SkipTypeParametersList();
  void SkipInitializer();
  void SkipExpression();
  void SkipStatement();
  void SkipFunctionNode();
  void SkipName();
  void SkipArguments();
  void SkipVariableDeclaration();
  void SkipLibraryCombinator();
  void SkipLibraryDependency();
  void SkipLibraryPart();
  void SkipLibraryTypedef();
  TokenPosition ReadPosition(bool record = true);
  void record_token_position(TokenPosition position);
  void record_yield_position(TokenPosition position);
  Tag ReadTag(uint8_t* payload = NULL);
  Tag PeekTag(uint8_t* payload = NULL);
  uint8_t ReadFlags() { return reader_->ReadFlags(); }

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

  Tag PeekArgumentsFirstPositionalTag();
  const TypeArguments& PeekArgumentsInstantiatedType(const Class& klass);
  intptr_t PeekArgumentsCount();

  LocalVariable* LookupParameterDirect(intptr_t kernel_offset,
                                       intptr_t parameter_index);
  LocalVariable* LookupVariable(intptr_t kernel_offset);
  LocalVariable* MakeTemporary();
  RawFunction* LookupMethodByMember(NameIndex target,
                                    const String& method_name);

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
                      intptr_t argument_count,
                      ICData::RebindRule rebind_rule);
  Fragment StaticCall(TokenPosition position,
                      const Function& target,
                      intptr_t argument_count,
                      const Array& argument_names,
                      ICData::RebindRule rebind_rule,
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
                        const Function& interface_target);
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
  Fragment CheckAssignableInCheckedMode(const AbstractType& dst_type,
                                        const String& dst_name);
  Fragment CheckVariableTypeInCheckedMode(intptr_t variable_kernel_position);
  Fragment CheckVariableTypeInCheckedMode(const AbstractType& dst_type,
                                          const String& name_symbol);
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
  Fragment BuildVectorCreation(TokenPosition* position);
  Fragment BuildVectorGet(TokenPosition* position);
  Fragment BuildVectorSet(TokenPosition* position);
  Fragment BuildVectorCopy(TokenPosition* position);
  Fragment BuildClosureCreation(TokenPosition* position);

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
  Fragment BuildFunctionNode(TokenPosition parent_position,
                             StringIndex name_index);
  void SetupFunctionParameters(const Class& klass,
                               const Function& function,
                               bool is_method,
                               bool is_closure,
                               FunctionNodeHelper* function_node_helper);

  FlowGraphBuilder* flow_graph_builder_;
  TranslationHelper& translation_helper_;
  Zone* zone_;
  Reader* reader_;
  StreamingConstantEvaluator constant_evaluator_;
  StreamingDartTypeTranslator type_translator_;
  intptr_t relative_kernel_offset_;
  intptr_t current_script_id_;
  intptr_t record_for_script_id_;
  GrowableArray<intptr_t>* record_token_positions_into_;
  GrowableArray<intptr_t>* record_yield_positions_into_;

  friend class StreamingConstantEvaluator;
  friend class StreamingDartTypeTranslator;
  friend class StreamingScopeBuilder;
  friend class FunctionNodeHelper;
  friend class VariableDeclarationHelper;
  friend class FieldHelper;
  friend class ProcedureHelper;
  friend class ClassHelper;
  friend class LibraryHelper;
  friend class LibraryDependencyHelper;
  friend class ConstructorHelper;
  friend class SimpleExpressionConverter;
  friend class KernelLoader;
};

// A helper class that saves the current reader position, goes to another reader
// position, and upon destruction, resets to the original reader position.
class AlternativeReadingScope {
 public:
  AlternativeReadingScope(Reader* reader, intptr_t new_position)
      : reader_(reader),
        saved_size_(reader_->size()),
        saved_raw_buffer_(reader_->raw_buffer()),
        saved_typed_data_(reader_->typed_data()),
        saved_offset_(reader_->offset()) {
    reader_->set_offset(new_position);
  }

  AlternativeReadingScope(Reader* reader,
                          const TypedData* new_typed_data,
                          intptr_t new_position)
      : reader_(reader),
        saved_size_(reader_->size()),
        saved_raw_buffer_(reader_->raw_buffer()),
        saved_typed_data_(reader_->typed_data()),
        saved_offset_(reader_->offset()) {
    reader_->set_raw_buffer(NULL);
    reader_->set_typed_data(new_typed_data);
    reader_->set_size(new_typed_data->Length());
    reader_->set_offset(new_position);
  }

  explicit AlternativeReadingScope(Reader* reader)
      : reader_(reader),
        saved_size_(reader_->size()),
        saved_raw_buffer_(reader_->raw_buffer()),
        saved_typed_data_(reader_->typed_data()),
        saved_offset_(reader_->offset()) {}

  ~AlternativeReadingScope() {
    reader_->set_raw_buffer(saved_raw_buffer_);
    reader_->set_typed_data(saved_typed_data_);
    reader_->set_size(saved_size_);
    reader_->set_offset(saved_offset_);
  }

  intptr_t saved_offset() { return saved_offset_; }

 private:
  Reader* reader_;
  intptr_t saved_size_;
  const uint8_t* saved_raw_buffer_;
  const TypedData* saved_typed_data_;
  intptr_t saved_offset_;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_KERNEL_BINARY_FLOWGRAPH_H_
