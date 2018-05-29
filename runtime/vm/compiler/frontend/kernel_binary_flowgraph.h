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

class KernelReaderHelper;

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

  explicit FunctionNodeHelper(KernelReaderHelper* helper) {
    helper_ = helper;
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
  KernelReaderHelper* helper_;
  intptr_t next_read_;
};

class TypeParameterHelper {
 public:
  enum Field {
    kStart,  // tag.
    kFlags,
    kAnnotations,
    kName,
    kBound,
    kDefaultType,
    kEnd,
  };

  enum Flag {
    kIsGenericCovariantImpl = 1 << 0,
  };

  explicit TypeParameterHelper(KernelReaderHelper* helper) {
    helper_ = helper;
    next_read_ = kStart;
  }

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  void ReadUntilExcludingAndSetJustRead(Field field) {
    ReadUntilExcluding(field);
    SetJustRead(field);
  }

  void Finish() { ReadUntilExcluding(kEnd); }

  TokenPosition position_;
  uint8_t flags_;
  StringIndex name_index_;

 private:
  KernelReaderHelper* helper_;
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
    kAnnotations,
    kFlags,
    kNameIndex,
    kType,
    kInitializer,
    kEnd,
  };

  enum Flag {
    kFinal = 1 << 0,
    kConst = 1 << 1,
    kCovariant = 1 << 3,
    kIsGenericCovariantImpl = 1 << 5,
  };

  explicit VariableDeclarationHelper(KernelReaderHelper* helper)
      : helper_(helper), next_read_(kPosition) {}

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsConst() { return (flags_ & kConst) != 0; }
  bool IsFinal() { return (flags_ & kFinal) != 0; }
  bool IsCovariant() { return (flags_ & kCovariant) != 0; }

  bool IsGenericCovariantImpl() {
    return (flags_ & kIsGenericCovariantImpl) != 0;
  }

  TokenPosition position_;
  TokenPosition equals_position_;
  uint8_t flags_;
  StringIndex name_index_;

 private:
  KernelReaderHelper* helper_;
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
    kSourceUriIndex,
    kPosition,
    kEndPosition,
    kFlags,
    kName,
    kAnnotations,
    kType,
    kInitializer,
    kEnd,
  };

  enum Flag {
    kFinal = 1 << 0,
    kConst = 1 << 1,
    kStatic = 1 << 2,
    kIsCovariant = 1 << 5,
    kIsGenericCovariantImpl = 1 << 6,
  };

  explicit FieldHelper(KernelReaderHelper* helper)
      : helper_(helper),
        next_read_(kStart),
        has_function_literal_initializer_(false) {}

  FieldHelper(KernelReaderHelper* helper, intptr_t offset);

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
  bool IsCovariant() const { return (flags_ & kIsCovariant) != 0; }
  bool IsGenericCovariantImpl() {
    return (flags_ & kIsGenericCovariantImpl) != 0;
  }

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
  KernelReaderHelper* helper_;
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
    kSourceUriIndex,
    kPosition,
    kEndPosition,
    kKind,
    kFlags,
    kName,
    kAnnotations,
    kForwardingStubSuperTarget,
    kForwardingStubInterfaceTarget,
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
    kForwardingStub = 1 << 4,

    // TODO(29841): Remove this line after the issue is resolved.
    kRedirectingFactoryConstructor = 1 << 6,
    kNoSuchMethodForwarder = 1 << 7,
  };

  explicit ProcedureHelper(KernelReaderHelper* helper)
      : helper_(helper), next_read_(kStart) {}

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
  bool IsForwardingStub() { return (flags_ & kForwardingStub) != 0; }
  bool IsRedirectingFactoryConstructor() {
    return (flags_ & kRedirectingFactoryConstructor) != 0;
  }

  NameIndex canonical_name_;
  TokenPosition position_;
  TokenPosition end_position_;
  Kind kind_;
  uint8_t flags_;
  intptr_t source_uri_index_;
  intptr_t annotation_count_;

  // Only valid if the 'isForwardingStub' flag is set.
  NameIndex forwarding_stub_super_target_;

 private:
  KernelReaderHelper* helper_;
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
    kSourceUriIndex,
    kPosition,
    kEndPosition,
    kFlags,
    kName,
    kAnnotations,
    kFunction,
    kInitializers,
    kEnd,
  };

  enum Flag {
    kConst = 1 << 0,
    kExternal = 1 << 1,
    kSynthetic = 1 << 2,
  };

  explicit ConstructorHelper(KernelReaderHelper* helper)
      : helper_(helper), next_read_(kStart) {}

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsExternal() { return (flags_ & kExternal) != 0; }
  bool IsConst() { return (flags_ & kConst) != 0; }
  bool IsSynthetic() { return (flags_ & kSynthetic) != 0; }

  NameIndex canonical_name_;
  TokenPosition position_;
  TokenPosition end_position_;
  uint8_t flags_;
  intptr_t source_uri_index_;
  intptr_t annotation_count_;

 private:
  KernelReaderHelper* helper_;
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
    kSourceUriIndex,
    kPosition,
    kEndPosition,
    kFlags,
    kNameIndex,
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

  enum Flag {
    kIsAbstract = 1 << 2,
    kIsEnumClass = 1 << 3,
    kIsAnonymousMixin = 1 << 4,
    kIsEliminatedMixin = 1 << 5,
  };

  explicit ClassHelper(KernelReaderHelper* helper)
      : helper_(helper), next_read_(kStart) {}

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool is_abstract() const { return flags_ & Flag::kIsAbstract; }

  bool is_enum_class() const { return flags_ & Flag::kIsEnumClass; }

  bool is_transformed_mixin_application() const {
    return flags_ & Flag::kIsEliminatedMixin;
  }

  NameIndex canonical_name_;
  TokenPosition position_;
  TokenPosition end_position_;
  StringIndex name_index_;
  intptr_t source_uri_index_;
  intptr_t annotation_count_;
  intptr_t procedure_count_;
  uint8_t flags_;

 private:
  KernelReaderHelper* helper_;
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

  explicit LibraryHelper(KernelReaderHelper* helper)
      : helper_(helper), next_read_(kFlags) {}

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
  KernelReaderHelper* helper_;
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

  explicit LibraryDependencyHelper(KernelReaderHelper* helper)
      : helper_(helper), next_read_(kFileOffset) {}

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  uint8_t flags_;
  StringIndex name_index_;
  NameIndex target_library_canonical_name_;

 private:
  KernelReaderHelper* helper_;
  intptr_t next_read_;
};

// Base class for helpers accessing metadata of a certain kind.
// Assumes that metadata is accessed in linear order.
class MetadataHelper {
 public:
  explicit MetadataHelper(StreamingFlowGraphBuilder* builder);

  void SetMetadataMappings(intptr_t mappings_offset, intptr_t mappings_num);

 protected:
  // Look for metadata mapping with node offset greater or equal than the given.
  intptr_t FindMetadataMapping(intptr_t node_offset);

  // Return offset of the metadata payload corresponding to the given node,
  // or -1 if there is no metadata.
  // Assumes metadata is accesses for nodes in linear order most of the time.
  intptr_t GetNextMetadataPayloadOffset(intptr_t node_offset);

  StreamingFlowGraphBuilder* builder_;
  TranslationHelper& translation_helper_;

 private:
  intptr_t mappings_offset_;
  intptr_t mappings_num_;
  intptr_t last_node_offset_;
  intptr_t last_mapping_index_;
};

struct DirectCallMetadata {
  DirectCallMetadata(const Function& target, bool check_receiver_for_null)
      : target_(target), check_receiver_for_null_(check_receiver_for_null) {}

  const Function& target_;
  const bool check_receiver_for_null_;
};

// Helper class which provides access to direct call metadata.
class DirectCallMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.direct-call.metadata"; }

  explicit DirectCallMetadataHelper(StreamingFlowGraphBuilder* builder)
      : MetadataHelper(builder) {}

  DirectCallMetadata GetDirectTargetForPropertyGet(intptr_t node_offset);
  DirectCallMetadata GetDirectTargetForPropertySet(intptr_t node_offset);
  DirectCallMetadata GetDirectTargetForMethodInvocation(intptr_t node_offset);

 private:
  bool ReadMetadata(intptr_t node_offset,
                    NameIndex* target_name,
                    bool* check_receiver_for_null);
};

struct InferredTypeMetadata {
  InferredTypeMetadata(intptr_t cid_, bool nullable_)
      : cid(cid_), nullable(nullable_) {}

  const intptr_t cid;
  const bool nullable;

  bool IsTrivial() const { return (cid == kDynamicCid) && nullable; }
};

// Helper class which provides access to inferred type metadata.
class InferredTypeMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.inferred-type.metadata"; }

  explicit InferredTypeMetadataHelper(StreamingFlowGraphBuilder* builder)
      : MetadataHelper(builder) {}

  InferredTypeMetadata GetInferredType(intptr_t node_offset);
};

struct ProcedureAttributesMetadata {
  ProcedureAttributesMetadata(bool has_dynamic_invocations = true,
                              bool has_non_this_uses = true,
                              bool has_tearoff_uses = true)
      : has_dynamic_invocations(has_dynamic_invocations),
        has_non_this_uses(has_non_this_uses),
        has_tearoff_uses(has_tearoff_uses) {}
  bool has_dynamic_invocations;
  bool has_non_this_uses;
  bool has_tearoff_uses;
};

// Helper class which provides access to direct call metadata.
class ProcedureAttributesMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.procedure-attributes.metadata"; }

  explicit ProcedureAttributesMetadataHelper(StreamingFlowGraphBuilder* builder)
      : MetadataHelper(builder) {}

  ProcedureAttributesMetadata GetProcedureAttributes(intptr_t node_offset);

 private:
  bool ReadMetadata(intptr_t node_offset,
                    ProcedureAttributesMetadata* metadata);
};

// Helper class which provides access to bytecode metadata.
class BytecodeMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.bytecode"; }

  explicit BytecodeMetadataHelper(StreamingFlowGraphBuilder* builder)
      : MetadataHelper(builder) {}

#if defined(DART_USE_INTERPRETER)
  void ReadMetadata(const Function& function);

 private:
  // Returns the index of the last read pool entry.
  intptr_t ReadPoolEntries(const Function& function,
                           const Function& inner_function,
                           const ObjectPool& pool,
                           intptr_t from_index);
  RawCode* ReadBytecode(const ObjectPool& pool);
  void ReadExceptionsTable(const Code& bytecode);
#endif
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

  void set_active_class(ActiveClass* active_class) {
    active_class_ = active_class;
  }

 private:
  // Can build a malformed type.
  void BuildTypeInternal(bool invalid_as_dynamic = false);
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
  explicit StreamingScopeBuilder(ParsedFunction* parsed_function);

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
    // Inverse of kTypeCheckOnlyGenericCovariantImplParameters.
    kTypeCheckForTearOffOfNonDynamicallyInvokedMethod,

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
  void EvaluateVariableGet();
  void EvaluateVariableGet(uint8_t payload);
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
  StreamingDartTypeTranslator& type_translator_;

  const Script& script_;
  Instance& result_;
};

class KernelReaderHelper {
 public:
  KernelReaderHelper(Zone* zone,
                     TranslationHelper* translation_helper,
                     const Script& script,
                     const TypedData& data,
                     intptr_t data_program_offset)
      : zone_(zone),
        translation_helper_(*translation_helper),
        reader_(data),
        script_(script),
        data_program_offset_(data_program_offset) {}

  KernelReaderHelper(Zone* zone,
                     TranslationHelper* translation_helper,
                     const uint8_t* data_buffer,
                     intptr_t buffer_length,
                     intptr_t data_program_offset)
      : zone_(zone),
        translation_helper_(*translation_helper),
        reader_(data_buffer, buffer_length),
        script_(Script::Handle(zone_)),
        data_program_offset_(data_program_offset) {}

  virtual ~KernelReaderHelper() {}

  void SetOffset(intptr_t offset);

  intptr_t ReadListLength();
  virtual void ReportUnexpectedTag(const char* variant, Tag tag);

 protected:
  const Script& script() const { return script_; }

  virtual void set_current_script_id(intptr_t id) {
    // Do nothing by default. This is overridden in StreamingFlowGraphBuilder.
    USE(id);
  }

  virtual void RecordYieldPosition(TokenPosition position) {
    // Do nothing by default. This is overridden in StreamingFlowGraphBuilder.
    USE(position);
  }

  virtual void RecordTokenPosition(TokenPosition position) {
    // Do nothing by default. This is overridden in StreamingFlowGraphBuilder.
    USE(position);
  }

  intptr_t ReaderOffset() const;
  void SkipBytes(intptr_t skip);
  bool ReadBool();
  uint8_t ReadByte();
  uint32_t ReadUInt();
  uint32_t ReadUInt32();
  uint32_t PeekUInt();
  double ReadDouble();
  uint32_t PeekListLength();
  StringIndex ReadStringReference();
  NameIndex ReadCanonicalNameReference();
  StringIndex ReadNameAsStringIndex();
  const String& ReadNameAsMethodName();
  const String& ReadNameAsGetterName();
  const String& ReadNameAsSetterName();
  const String& ReadNameAsFieldName();
  void SkipFlags();
  void SkipStringReference();
  void SkipConstantReference();
  void SkipCanonicalNameReference();
  void SkipDartType();
  void SkipOptionalDartType();
  void SkipInterfaceType(bool simple);
  void SkipFunctionType(bool simple);
  void SkipStatementList();
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
  Tag ReadTag(uint8_t* payload = NULL);
  Tag PeekTag(uint8_t* payload = NULL);
  uint8_t ReadFlags() { return reader_.ReadFlags(); }

  Zone* zone_;
  TranslationHelper& translation_helper_;
  Reader reader_;
  const Script& script_;
  // Some items like variables are specified in the kernel binary as
  // absolute offsets (as in, offsets within the whole kernel program)
  // of their declaration nodes. Hence, to cache and/or access them
  // uniquely from within a function's kernel data, we need to
  // add/subtract the offset of the kernel data in the over all
  // kernel program.
  intptr_t data_program_offset_;

  friend class ClassHelper;
  friend class ConstantHelper;
  friend class ConstructorHelper;
  friend class DirectCallMetadataHelper;
  friend class ProcedureAttributesMetadataHelper;
  friend class FieldHelper;
  friend class FunctionNodeHelper;
  friend class InferredTypeMetadataHelper;
  friend class KernelLoader;
  friend class LibraryDependencyHelper;
  friend class LibraryHelper;
  friend class MetadataHelper;
  friend class ProcedureHelper;
  friend class SimpleExpressionConverter;
  friend class StreamingConstantEvaluator;
  friend class StreamingDartTypeTranslator;
  friend class StreamingScopeBuilder;
  friend class VariableDeclarationHelper;
  friend class TypeParameterHelper;
};

class KernelFingerprintHelper : public KernelReaderHelper {
 public:
  KernelFingerprintHelper(Zone* zone,
                          TranslationHelper* translation_helper,
                          const Script& script,
                          const TypedData& data,
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
                            const TypedData& data,
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
        constant_evaluator_(this),
        type_translator_(this, /* finalize= */ true),
        current_script_id_(-1),
        record_for_script_id_(-1),
        record_token_positions_into_(NULL),
        record_yield_positions_into_(NULL),
        direct_call_metadata_helper_(this),
        inferred_type_metadata_helper_(this),
        procedure_attributes_metadata_helper_(this),
        bytecode_metadata_helper_(this),
        metadata_scanned_(false) {}

  StreamingFlowGraphBuilder(TranslationHelper* translation_helper,
                            Zone* zone,
                            const uint8_t* data_buffer,
                            intptr_t buffer_length,
                            intptr_t data_program_offset)
      : KernelReaderHelper(zone,
                           translation_helper,
                           data_buffer,
                           buffer_length,
                           data_program_offset),
        flow_graph_builder_(NULL),
        constant_evaluator_(this),
        type_translator_(this, /* finalize= */ true),
        current_script_id_(-1),
        record_for_script_id_(-1),
        record_token_positions_into_(NULL),
        record_yield_positions_into_(NULL),
        direct_call_metadata_helper_(this),
        inferred_type_metadata_helper_(this),
        procedure_attributes_metadata_helper_(this),
        bytecode_metadata_helper_(this),
        metadata_scanned_(false) {}

  StreamingFlowGraphBuilder(TranslationHelper* translation_helper,
                            const Script& script,
                            Zone* zone,
                            const TypedData& data,
                            intptr_t data_program_offset)
      : KernelReaderHelper(zone,
                           translation_helper,
                           script,
                           data,
                           data_program_offset),
        flow_graph_builder_(NULL),
        constant_evaluator_(this),
        type_translator_(this, /* finalize= */ true),
        current_script_id_(-1),
        record_for_script_id_(-1),
        record_token_positions_into_(NULL),
        record_yield_positions_into_(NULL),
        direct_call_metadata_helper_(this),
        inferred_type_metadata_helper_(this),
        procedure_attributes_metadata_helper_(this),
        bytecode_metadata_helper_(this),
        metadata_scanned_(false) {}

  virtual ~StreamingFlowGraphBuilder() {}

  FlowGraph* BuildGraph(intptr_t kernel_offset);

  void ReportUnexpectedTag(const char* variant, Tag tag) override;

  Fragment BuildStatementAt(intptr_t kernel_offset);
  RawObject* BuildParameterDescriptor(intptr_t kernel_offset);
  RawObject* EvaluateMetadata(intptr_t kernel_offset, const Class& owner_class);
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

  // If a 'ParsedFunction' is provided for 'set_forwarding_stub', this method
  // will attach the forwarding stub target reference to the parsed function if
  // it crosses a procedure node for a concrete forwarding stub.
  void ReadUntilFunctionNode(ParsedFunction* set_forwarding_stub = NULL);

  enum DispatchCategory { Interface, ViaThis, Closure, DynamicDispatch };

 private:
  void LoadAndSetupTypeParameters(ActiveClass* active_class,
                                  const Object& set_on,
                                  intptr_t type_parameter_count,
                                  const Function& parameterized_function);

  void DiscoverEnclosingElements(Zone* zone,
                                 const Function& function,
                                 Function* outermost_function);

  StringIndex GetNameFromVariableDeclaration(intptr_t kernel_offset,
                                             const Function& function);

  bool optimizing();

  FlowGraph* BuildGraphOfFieldInitializer();
  FlowGraph* BuildGraphOfFieldAccessor(LocalVariable* setter_value);
  void SetupDefaultParameterValues();
  Fragment BuildFieldInitializer(NameIndex canonical_name);
  Fragment BuildInitializers(const Class& parent_class);
  FlowGraph* BuildGraphOfImplicitClosureFunction(const Function& function);
  FlowGraph* BuildGraphOfFunction(bool constructor);
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
  RawFunction* LookupMethodByMember(NameIndex target,
                                    const String& method_name);
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
    kDefaultTypeChecks,
    kTypeChecksForNoDynamicInvocationsTearOff
  };

  // Does not move the cursor.
  Fragment BuildDefaultTypeHandling(const Function& function,
                                    intptr_t type_parameters_offset);

  Fragment BuildArgumentTypeChecks(TypeChecksToBuild mode = kDefaultTypeChecks);

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
  Fragment CheckBoolean();
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

  // Scan through metadata mappings section and cache offsets for recognized
  // metadata kinds.
  void EnsureMetadataIsScanned();

  FlowGraphBuilder* flow_graph_builder_;
  StreamingConstantEvaluator constant_evaluator_;
  StreamingDartTypeTranslator type_translator_;
  intptr_t current_script_id_;
  intptr_t record_for_script_id_;
  GrowableArray<intptr_t>* record_token_positions_into_;
  GrowableArray<intptr_t>* record_yield_positions_into_;
  DirectCallMetadataHelper direct_call_metadata_helper_;
  InferredTypeMetadataHelper inferred_type_metadata_helper_;
  ProcedureAttributesMetadataHelper procedure_attributes_metadata_helper_;
  BytecodeMetadataHelper bytecode_metadata_helper_;
  bool metadata_scanned_;

  friend class ClassHelper;
  friend class ConstantHelper;
  friend class ConstructorHelper;
  friend class DirectCallMetadataHelper;
  friend class ProcedureAttributesMetadataHelper;
  friend class BytecodeMetadataHelper;
  friend class FieldHelper;
  friend class FunctionNodeHelper;
  friend class InferredTypeMetadataHelper;
  friend class KernelLoader;
  friend class KernelReaderHelper;
  friend class LibraryDependencyHelper;
  friend class LibraryHelper;
  friend class MetadataHelper;
  friend class ProcedureHelper;
  friend class SimpleExpressionConverter;
  friend class StreamingConstantEvaluator;
  friend class StreamingDartTypeTranslator;
  friend class StreamingScopeBuilder;
  friend class VariableDeclarationHelper;
  friend class TypeParameterHelper;
};

class AlternativeScriptScope {
 public:
  AlternativeScriptScope(TranslationHelper* helper,
                         const Script& new_script,
                         const Script& old_script)
      : helper_(helper), old_script_(old_script) {
    helper_->Reset();
    helper_->InitFromScript(new_script);
  }
  ~AlternativeScriptScope() {
    helper_->Reset();
    helper_->InitFromScript(old_script_);
  }

  TranslationHelper* helper_;
  const Script& old_script_;
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

// Helper class that reads a kernel Constant from binary.
class ConstantHelper {
 public:
  ConstantHelper(ActiveClass* active_class,
                 StreamingFlowGraphBuilder* builder,
                 StreamingDartTypeTranslator* type_translator,
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
  ActiveClass* active_class_;
  StreamingFlowGraphBuilder& builder_;
  StreamingDartTypeTranslator& type_translator_;
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
