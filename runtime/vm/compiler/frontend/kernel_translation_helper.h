// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_KERNEL_TRANSLATION_HELPER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_KERNEL_TRANSLATION_HELPER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/il.h"  // For CompileType.
#include "vm/kernel.h"
#include "vm/kernel_binary.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class ConstantReader;
class KernelReaderHelper;
class TypeTranslator;

class TranslationHelper {
 public:
  explicit TranslationHelper(Thread* thread);

  TranslationHelper(Thread* thread, Heap::Space space);

  virtual ~TranslationHelper() {}

  void Reset();

  void InitFromScript(const Script& script);

  void InitFromKernelProgramInfo(const KernelProgramInfo& info);

  Thread* thread() { return thread_; }

  Zone* zone() { return zone_; }

  Isolate* isolate() { return isolate_; }

  Heap::Space allocation_space() { return allocation_space_; }

  // Access to strings.
  const TypedData& string_offsets() const { return string_offsets_; }
  void SetStringOffsets(const TypedData& string_offsets);

  const ExternalTypedData& string_data() const { return string_data_; }
  void SetStringData(const ExternalTypedData& string_data);

  const TypedData& canonical_names() const { return canonical_names_; }
  void SetCanonicalNames(const TypedData& canonical_names);

  const ExternalTypedData& metadata_payloads() const {
    return metadata_payloads_;
  }
  void SetMetadataPayloads(const ExternalTypedData& metadata_payloads);

  const ExternalTypedData& metadata_mappings() const {
    return metadata_mappings_;
  }
  void SetMetadataMappings(const ExternalTypedData& metadata_mappings);

  // Access to previously evaluated constants from the constants table.
  const Array& constants() { return constants_; }
  void SetConstants(const Array& constants);

  // Access to the raw bytes of the constants table.
  const ExternalTypedData& constants_table() const { return constants_table_; }
  void SetConstantsTable(const ExternalTypedData& constants_table);

  KernelProgramInfo& info() { return info_; }

  GrowableObjectArrayPtr EnsurePotentialPragmaFunctions();

  void AddPotentialExtensionLibrary(const Library& library);
  GrowableObjectArrayPtr GetPotentialExtensionLibraries();

  void SetKernelProgramInfo(const KernelProgramInfo& info);
  const KernelProgramInfo& GetKernelProgramInfo() const { return info_; }

  intptr_t StringOffset(StringIndex index) const;
  intptr_t StringSize(StringIndex index) const;

  // The address of the backing store of the string with a given index.  If the
  // backing store is in the VM's heap this address is not safe for GC (call the
  // function and use the result within a NoSafepointScope).
  uint8_t* StringBuffer(StringIndex index) const;

  uint8_t CharacterAt(StringIndex string_index, intptr_t index);
  bool StringEquals(StringIndex string_index, const char* other);

  // Accessors and predicates for canonical names.
  NameIndex CanonicalNameParent(NameIndex name);
  StringIndex CanonicalNameString(NameIndex name);
  bool IsAdministrative(NameIndex name);
  bool IsPrivate(NameIndex name);
  bool IsRoot(NameIndex name);
  bool IsLibrary(NameIndex name);
  bool IsClass(NameIndex name);
  bool IsMember(NameIndex name);
  bool IsField(NameIndex name);
  bool IsConstructor(NameIndex name);
  bool IsProcedure(NameIndex name);
  bool IsMethod(NameIndex name);
  bool IsGetter(NameIndex name);
  bool IsSetter(NameIndex name);
  bool IsFactory(NameIndex name);

  // For a member (field, constructor, or procedure) return the canonical name
  // of the enclosing class or library.
  NameIndex EnclosingName(NameIndex name);

  InstancePtr Canonicalize(const Instance& instance);

  const String& DartString(const char* content) {
    return DartString(content, allocation_space_);
  }
  const String& DartString(const char* content, Heap::Space space);

  String& DartString(StringIndex index) {
    return DartString(index, allocation_space_);
  }
  String& DartString(StringIndex string_index, Heap::Space space);

  String& DartString(const uint8_t* utf8_array,
                     intptr_t len,
                     Heap::Space space);

  const String& DartString(const GrowableHandlePtrArray<const String>& pieces);

  const String& DartSymbolPlain(const char* content) const;
  String& DartSymbolPlain(StringIndex string_index) const;
  const String& DartSymbolObfuscate(const char* content) const;
  String& DartSymbolObfuscate(StringIndex string_index) const;

  String& DartIdentifier(const Library& lib, StringIndex string_index);

  const String& DartClassName(NameIndex kernel_class);

  const String& DartConstructorName(NameIndex constructor);

  const String& DartProcedureName(NameIndex procedure);

  const String& DartSetterName(NameIndex setter);
  const String& DartSetterName(NameIndex parent, StringIndex setter);

  const String& DartGetterName(NameIndex getter);
  const String& DartGetterName(NameIndex parent, StringIndex getter);

  const String& DartFieldName(NameIndex field);
  const String& DartFieldName(NameIndex parent, StringIndex field);

  const String& DartMethodName(NameIndex method);
  const String& DartMethodName(NameIndex parent, StringIndex method);

  const String& DartFactoryName(NameIndex factory);

  // A subclass overrides these when reading in the Kernel program in order to
  // support recursive type expressions (e.g. for "implements X" ...
  // annotations).
  virtual LibraryPtr LookupLibraryByKernelLibrary(NameIndex library);
  virtual ClassPtr LookupClassByKernelClass(NameIndex klass);

  FieldPtr LookupFieldByKernelField(NameIndex field);
  FunctionPtr LookupStaticMethodByKernelProcedure(NameIndex procedure);
  FunctionPtr LookupConstructorByKernelConstructor(NameIndex constructor);
  FunctionPtr LookupConstructorByKernelConstructor(const Class& owner,
                                                   NameIndex constructor);
  FunctionPtr LookupConstructorByKernelConstructor(
      const Class& owner,
      StringIndex constructor_name);
  FunctionPtr LookupMethodByMember(NameIndex target, const String& method_name);
  FunctionPtr LookupDynamicFunction(const Class& klass, const String& name);

  Type& GetDeclarationType(const Class& klass);

  void SetupFieldAccessorFunction(const Class& klass,
                                  const Function& function,
                                  const AbstractType& field_type);

  void ReportError(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  void ReportError(const Script& script,
                   const TokenPosition position,
                   const char* format,
                   ...) PRINTF_ATTRIBUTE(4, 5);
  void ReportError(const Error& prev_error, const char* format, ...)
      PRINTF_ATTRIBUTE(3, 4);
  void ReportError(const Error& prev_error,
                   const Script& script,
                   const TokenPosition position,
                   const char* format,
                   ...) PRINTF_ATTRIBUTE(5, 6);

  void SetExpressionEvaluationFunction(const Function& function) {
    ASSERT(expression_evaluation_function_ == nullptr);
    expression_evaluation_function_ = &Function::Handle(zone_, function.raw());
  }
  const Function& GetExpressionEvaluationFunction() {
    if (expression_evaluation_function_ == nullptr) {
      return Function::null_function();
    }
    return *expression_evaluation_function_;
  }
  void SetExpressionEvaluationRealClass(const Class& real_class) {
    ASSERT(expression_evaluation_real_class_ == nullptr);
    ASSERT(!real_class.IsNull());
    expression_evaluation_real_class_ = &Class::Handle(zone_, real_class.raw());
  }
  ClassPtr GetExpressionEvaluationRealClass() {
    ASSERT(expression_evaluation_real_class_ != nullptr);
    return expression_evaluation_real_class_->raw();
  }

 private:
  // This will mangle [name_to_modify] if necessary and make the result a symbol
  // if asked.  The result will be available in [name_to_modify] and it is also
  // returned.  If the name is private, the canonical name [parent] will be used
  // to get the import URI of the library where the name is visible.
  String& ManglePrivateName(NameIndex parent,
                            String* name_to_modify,
                            bool symbolize = true,
                            bool obfuscate = true);
  String& ManglePrivateName(const Library& library,
                            String* name_to_modify,
                            bool symbolize = true,
                            bool obfuscate = true);

  Thread* thread_;
  Zone* zone_;
  Isolate* isolate_;
  Heap::Space allocation_space_;

  TypedData& string_offsets_;
  ExternalTypedData& string_data_;
  TypedData& canonical_names_;
  ExternalTypedData& metadata_payloads_;
  ExternalTypedData& metadata_mappings_;
  Array& constants_;
  ExternalTypedData& constants_table_;
  KernelProgramInfo& info_;
  Smi& name_index_handle_;
  GrowableObjectArray* potential_extension_libraries_ = nullptr;
  Function* expression_evaluation_function_ = nullptr;
  Class* expression_evaluation_real_class_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(TranslationHelper);
};

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

  enum AsyncMarker : intptr_t {
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

  TokenPosition position_ = TokenPosition::kNoSource;
  TokenPosition end_position_ = TokenPosition::kNoSource;
  AsyncMarker async_marker_;
  AsyncMarker dart_async_marker_;
  intptr_t total_parameter_count_ = 0;
  intptr_t required_parameter_count_ = 0;

 private:
  KernelReaderHelper* helper_;
  intptr_t next_read_;

  DISALLOW_COPY_AND_ASSIGN(FunctionNodeHelper);
};

class TypeParameterHelper {
 public:
  enum Field {
    kStart,  // tag.
    kFlags,
    kAnnotations,
    kVariance,
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

  bool IsGenericCovariantImpl() {
    return (flags_ & kIsGenericCovariantImpl) != 0;
  }

  TokenPosition position_ = TokenPosition::kNoSource;
  uint8_t flags_ = 0;
  StringIndex name_index_;

 private:
  KernelReaderHelper* helper_;
  intptr_t next_read_;

  DISALLOW_COPY_AND_ASSIGN(TypeParameterHelper);
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
    kIsGenericCovariantImpl = 1 << 4,
    kLate = 1 << 5,
    kRequired = 1 << 6,
    kLowered = 1 << 7,
  };

  explicit VariableDeclarationHelper(KernelReaderHelper* helper)
      : annotation_count_(0), helper_(helper), next_read_(kPosition) {}

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsConst() const { return (flags_ & kConst) != 0; }
  bool IsFinal() const { return (flags_ & kFinal) != 0; }
  bool IsCovariant() const { return (flags_ & kCovariant) != 0; }
  bool IsLate() const { return (flags_ & kLate) != 0; }
  bool IsRequired() const { return (flags_ & kRequired) != 0; }

  bool IsGenericCovariantImpl() const {
    return (flags_ & kIsGenericCovariantImpl) != 0;
  }

  TokenPosition position_ = TokenPosition::kNoSource;
  TokenPosition equals_position_ = TokenPosition::kNoSource;
  uint8_t flags_ = 0;
  StringIndex name_index_;
  intptr_t annotation_count_ = 0;

 private:
  KernelReaderHelper* helper_;
  intptr_t next_read_;

  DISALLOW_COPY_AND_ASSIGN(VariableDeclarationHelper);
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
    kCanonicalNameGetter,
    kCanonicalNameSetter,
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
    kIsLate = 1 << 7,
    kExtensionMember = 1 << 8,
  };

  explicit FieldHelper(KernelReaderHelper* helper)
      : helper_(helper), next_read_(kStart) {}

  FieldHelper(KernelReaderHelper* helper, intptr_t offset);

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsConst() { return (flags_ & kConst) != 0; }
  bool IsFinal() { return (flags_ & kFinal) != 0; }
  bool IsStatic() { return (flags_ & kStatic) != 0; }
  bool IsCovariant() const { return (flags_ & kIsCovariant) != 0; }
  bool IsGenericCovariantImpl() {
    return (flags_ & kIsGenericCovariantImpl) != 0;
  }
  bool IsLate() const { return (flags_ & kIsLate) != 0; }
  bool IsExtensionMember() const { return (flags_ & kExtensionMember) != 0; }

  NameIndex canonical_name_getter_;
  NameIndex canonical_name_setter_;
  TokenPosition position_ = TokenPosition::kNoSource;
  TokenPosition end_position_ = TokenPosition::kNoSource;
  uint32_t flags_ = 0;
  intptr_t source_uri_index_ = 0;
  intptr_t annotation_count_ = 0;

 private:
  KernelReaderHelper* helper_;
  intptr_t next_read_;

  DISALLOW_COPY_AND_ASSIGN(FieldHelper);
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
    kStartPosition,
    kPosition,
    kEndPosition,
    kKind,
    kStubKind,
    kFlags,
    kName,
    kAnnotations,
    kStubTarget,
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

  enum StubKind {
    kRegularStubKind,
    kForwardingStubKind,
    kForwardingSuperStubKind,
    kNoSuchMethodForwarderStubKind,
    kMemberSignatureStubKind,
    kMixinStubKind,
    kMixinSuperStubKind,
  };

  enum Flag {
    kStatic = 1 << 0,
    kAbstract = 1 << 1,
    kExternal = 1 << 2,
    kConst = 1 << 3,  // Only for external const factories.

    // TODO(29841): Remove this line after the issue is resolved.
    kRedirectingFactoryConstructor = 1 << 4,
    kExtensionMember = 1 << 5,
    kSyntheticProcedure = 1 << 7,
  };

  explicit ProcedureHelper(KernelReaderHelper* helper)
      : helper_(helper), next_read_(kStart) {}

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsStatic() const { return (flags_ & kStatic) != 0; }
  bool IsAbstract() const { return (flags_ & kAbstract) != 0; }
  bool IsExternal() const { return (flags_ & kExternal) != 0; }
  bool IsConst() const { return (flags_ & kConst) != 0; }
  bool IsForwardingStub() const {
    return stub_kind_ == kForwardingStubKind ||
           stub_kind_ == kForwardingSuperStubKind;
  }
  bool IsRedirectingFactoryConstructor() const {
    return (flags_ & kRedirectingFactoryConstructor) != 0;
  }
  bool IsNoSuchMethodForwarder() const {
    return stub_kind_ == kNoSuchMethodForwarderStubKind;
  }
  bool IsExtensionMember() const { return (flags_ & kExtensionMember) != 0; }
  bool IsMemberSignature() const {
    return stub_kind_ == kMemberSignatureStubKind;
  }

  NameIndex canonical_name_;
  TokenPosition start_position_ = TokenPosition::kNoSource;
  TokenPosition position_ = TokenPosition::kNoSource;
  TokenPosition end_position_ = TokenPosition::kNoSource;
  Kind kind_;
  uint32_t flags_ = 0;
  intptr_t source_uri_index_ = 0;
  intptr_t annotation_count_ = 0;
  StubKind stub_kind_;

  // Only valid if the 'isForwardingStub' flag is set.
  NameIndex forwarding_stub_super_target_;

 private:
  KernelReaderHelper* helper_;
  intptr_t next_read_;

  DISALLOW_COPY_AND_ASSIGN(ProcedureHelper);
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
    kStartPosition,
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
  TokenPosition start_position_ = TokenPosition::kNoSource;
  TokenPosition position_ = TokenPosition::kNoSource;
  TokenPosition end_position_ = TokenPosition::kNoSource;
  uint8_t flags_ = 0;
  intptr_t source_uri_index_ = 0;
  intptr_t annotation_count_ = 0;

 private:
  KernelReaderHelper* helper_;
  intptr_t next_read_;

  DISALLOW_COPY_AND_ASSIGN(ConstructorHelper);
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
    kStartPosition,
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
    kIsAbstract = 1 << 0,
    kIsEnumClass = 1 << 1,
    kIsAnonymousMixin = 1 << 2,
    kIsEliminatedMixin = 1 << 3,
    kFlagMixinDeclaration = 1 << 4,
    kHasConstConstructor = 1 << 5,
  };

  explicit ClassHelper(KernelReaderHelper* helper)
      : helper_(helper), next_read_(kStart) {}

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool is_abstract() const { return (flags_ & Flag::kIsAbstract) != 0; }

  bool is_enum_class() const { return (flags_ & Flag::kIsEnumClass) != 0; }

  bool is_transformed_mixin_application() const {
    return (flags_ & Flag::kIsEliminatedMixin) != 0;
  }

  bool has_const_constructor() const {
    return (flags_ & Flag::kHasConstConstructor) != 0;
  }

  NameIndex canonical_name_;
  TokenPosition start_position_ = TokenPosition::kNoSource;
  TokenPosition position_ = TokenPosition::kNoSource;
  TokenPosition end_position_ = TokenPosition::kNoSource;
  StringIndex name_index_;
  intptr_t source_uri_index_ = 0;
  intptr_t annotation_count_ = 0;
  intptr_t procedure_count_ = 0;
  uint8_t flags_ = 0;

 private:
  KernelReaderHelper* helper_;
  intptr_t next_read_;

  DISALLOW_COPY_AND_ASSIGN(ClassHelper);
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
    kLanguageVersion /* from binary version 27 */,
    kCanonicalName,
    kName,
    kSourceUriIndex,
    kProblemsAsJson,
    kAnnotations,
    kDependencies,
    // There are other fields in a library:
    // * kAdditionalExports
    // * kParts
    // * kTypedefs
    // * kClasses
    // * kToplevelField
    // * kToplevelProcedures
    // * kSourceReferences
    // * kLibraryIndex
    // but we never read them via this helper and it makes extending the format
    // harder to keep the code around.
  };

  enum Flag {
    kSynthetic = 1 << 0,
    kIsNonNullableByDefault = 1 << 1,
    kNonNullableByDefaultCompiledModeBit1 = 1 << 2,
    kNonNullableByDefaultCompiledModeBit2 = 1 << 3,
  };

  explicit LibraryHelper(KernelReaderHelper* helper, uint32_t binary_version)
      : helper_(helper), binary_version_(binary_version), next_read_(kFlags) {}

  void ReadUntilIncluding(Field field) {
    ReadUntilExcluding(static_cast<Field>(static_cast<int>(field) + 1));
  }

  void ReadUntilExcluding(Field field);

  void SetNext(Field field) { next_read_ = field; }
  void SetJustRead(Field field) { next_read_ = field + 1; }

  bool IsSynthetic() const { return (flags_ & kSynthetic) != 0; }
  bool IsNonNullableByDefault() const {
    return (flags_ & kIsNonNullableByDefault) != 0;
  }
  NNBDCompiledMode GetNonNullableByDefaultCompiledMode() const {
    bool bit1 = (flags_ & kNonNullableByDefaultCompiledModeBit1) != 0;
    bool bit2 = (flags_ & kNonNullableByDefaultCompiledModeBit2) != 0;
    if (!bit1 && !bit2) return NNBDCompiledMode::kWeak;
    if (bit1 && !bit2) return NNBDCompiledMode::kStrong;
    if (bit1 && bit2) return NNBDCompiledMode::kAgnostic;
    if (!bit1 && bit2) return NNBDCompiledMode::kInvalid;
    UNREACHABLE();
  }

  uint8_t flags_ = 0;
  NameIndex canonical_name_;
  StringIndex name_index_;
  intptr_t source_uri_index_ = 0;

 private:
  KernelReaderHelper* helper_;
  uint32_t binary_version_;
  intptr_t next_read_;

  DISALLOW_COPY_AND_ASSIGN(LibraryHelper);
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

  uint8_t flags_ = 0;
  StringIndex name_index_;
  NameIndex target_library_canonical_name_;
  intptr_t annotation_count_ = 0;

 private:
  KernelReaderHelper* helper_;
  intptr_t next_read_;

  DISALLOW_COPY_AND_ASSIGN(LibraryDependencyHelper);
};

// Base class for helpers accessing metadata of a certain kind.
// Assumes that metadata is accessed in linear order.
class MetadataHelper {
 public:
  MetadataHelper(KernelReaderHelper* helper,
                 const char* tag,
                 bool precompiler_only);

#if defined(DEBUG)
  static void VerifyMetadataMappings(
      const ExternalTypedData& metadata_mappings);
#endif

 protected:
  // Look for metadata mapping with node offset greater or equal than the given.
  intptr_t FindMetadataMapping(intptr_t node_offset);

  // Return offset of the metadata payload corresponding to the given node,
  // or -1 if there is no metadata.
  // Assumes metadata is accesses for nodes in linear order most of the time.
  intptr_t GetNextMetadataPayloadOffset(intptr_t node_offset);

  // Returns metadata associated with component.
  intptr_t GetComponentMetadataPayloadOffset();

  KernelReaderHelper* helper_;
  TranslationHelper& translation_helper_;

 private:
  MetadataHelper();

  void SetMetadataMappings(intptr_t mappings_offset, intptr_t mappings_num);
  void ScanMetadataMappings();

  const char* tag_;
  bool mappings_scanned_;
  bool precompiler_only_;
  intptr_t mappings_offset_;
  intptr_t mappings_num_;
  intptr_t last_node_offset_;
  intptr_t last_mapping_index_;

  DISALLOW_COPY_AND_ASSIGN(MetadataHelper);
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

  explicit DirectCallMetadataHelper(KernelReaderHelper* helper);

  DirectCallMetadata GetDirectTargetForPropertyGet(intptr_t node_offset);
  DirectCallMetadata GetDirectTargetForPropertySet(intptr_t node_offset);
  DirectCallMetadata GetDirectTargetForMethodInvocation(intptr_t node_offset);

 private:
  bool ReadMetadata(intptr_t node_offset,
                    NameIndex* target_name,
                    bool* check_receiver_for_null);

  DISALLOW_COPY_AND_ASSIGN(DirectCallMetadataHelper);
};

struct InferredTypeMetadata {
  enum Flag {
    kFlagNullable = 1 << 0,
    kFlagInt = 1 << 1,
    kFlagSkipCheck = 1 << 2,
    kFlagConstant = 1 << 3,
    kFlagReceiverNotInt = 1 << 4,
  };

  InferredTypeMetadata(intptr_t cid_,
                       uint8_t flags_,
                       const Object& constant_value_ = Object::null_object())
      : cid(cid_), flags(flags_), constant_value(constant_value_) {}

  const intptr_t cid;
  const uint8_t flags;
  const Object& constant_value;

  bool IsTrivial() const {
    return (cid == kDynamicCid) && (flags == kFlagNullable);
  }
  bool IsNullable() const { return (flags & kFlagNullable) != 0; }
  bool IsInt() const {
    return (flags & kFlagInt) != 0 || cid == kMintCid || cid == kSmiCid;
  }
  bool IsSkipCheck() const { return (flags & kFlagSkipCheck) != 0; }
  bool IsConstant() const { return (flags & kFlagConstant) != 0; }
  bool ReceiverNotInt() const { return (flags & kFlagReceiverNotInt) != 0; }

  CompileType ToCompileType(Zone* zone) const {
    if (IsInt() && cid == kDynamicCid) {
      return CompileType::FromAbstractType(
          Type::ZoneHandle(
              zone, (IsNullable() ? Type::NullableIntType() : Type::IntType())),
          IsNullable());
    } else {
      return CompileType::CreateNullable(IsNullable(), cid);
    }
  }
};

// Helper class which provides access to inferred type metadata.
class InferredTypeMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.inferred-type.metadata"; }

  explicit InferredTypeMetadataHelper(KernelReaderHelper* helper,
                                      ConstantReader* constant_reader);

  InferredTypeMetadata GetInferredType(intptr_t node_offset,
                                       bool read_constant = true);

 private:
  ConstantReader* constant_reader_;

  DISALLOW_COPY_AND_ASSIGN(InferredTypeMetadataHelper);
};

struct ProcedureAttributesMetadata {
  static const int32_t kInvalidSelectorId = 0;

  bool method_or_setter_called_dynamically = true;
  bool getter_called_dynamically = true;
  bool has_this_uses = true;
  bool has_non_this_uses = true;
  bool has_tearoff_uses = true;
  int32_t method_or_setter_selector_id = kInvalidSelectorId;
  int32_t getter_selector_id = kInvalidSelectorId;

  void InitializeFromFlags(uint8_t flags);
};

// Helper class which provides access to direct call metadata.
class ProcedureAttributesMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.procedure-attributes.metadata"; }

  explicit ProcedureAttributesMetadataHelper(KernelReaderHelper* helper);

  ProcedureAttributesMetadata GetProcedureAttributes(intptr_t node_offset);

 private:
  bool ReadMetadata(intptr_t node_offset,
                    ProcedureAttributesMetadata* metadata);

  DISALLOW_COPY_AND_ASSIGN(ProcedureAttributesMetadataHelper);
};

class ObfuscationProhibitionsMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.obfuscation-prohibitions.metadata"; }

  explicit ObfuscationProhibitionsMetadataHelper(KernelReaderHelper* helper);

  void ReadProhibitions() { ReadMetadata(0); }

 private:
  void ReadMetadata(intptr_t node_offset);

  DISALLOW_COPY_AND_ASSIGN(ObfuscationProhibitionsMetadataHelper);
};

class LoadingUnitsMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.loading-units.metadata"; }

  explicit LoadingUnitsMetadataHelper(KernelReaderHelper* helper);

  void ReadLoadingUnits() { ReadMetadata(0); }

 private:
  void ReadMetadata(intptr_t node_offset);

  DISALLOW_COPY_AND_ASSIGN(LoadingUnitsMetadataHelper);
};

struct CallSiteAttributesMetadata {
  const AbstractType* receiver_type = nullptr;
};

// Helper class which provides access to direct call metadata.
class CallSiteAttributesMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.call-site-attributes.metadata"; }

  CallSiteAttributesMetadataHelper(KernelReaderHelper* helper,
                                   TypeTranslator* type_translator);

  CallSiteAttributesMetadata GetCallSiteAttributes(intptr_t node_offset);

 private:
  bool ReadMetadata(intptr_t node_offset, CallSiteAttributesMetadata* metadata);

  TypeTranslator& type_translator_;

  DISALLOW_COPY_AND_ASSIGN(CallSiteAttributesMetadataHelper);
};

// Information about a table selector computed by the TFA.
struct TableSelectorInfo {
  int call_count = 0;
  bool called_on_null = true;
  bool torn_off = true;
};

// Collection of table selector information for all selectors in the program.
class TableSelectorMetadata : public ZoneAllocated {
 public:
  explicit TableSelectorMetadata(intptr_t num_selectors)
      : selectors(num_selectors) {
    selectors.FillWith(TableSelectorInfo(), 0, num_selectors);
  }

  GrowableArray<TableSelectorInfo> selectors;

  DISALLOW_COPY_AND_ASSIGN(TableSelectorMetadata);
};

// Helper class which provides access to table selector metadata.
class TableSelectorMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.table-selector.metadata"; }

  explicit TableSelectorMetadataHelper(KernelReaderHelper* helper);

  TableSelectorMetadata* GetTableSelectorMetadata(Zone* zone);

 private:
  static const uint8_t kCalledOnNullBit = 1 << 0;
  static const uint8_t kTornOffBit = 1 << 1;

  void ReadTableSelectorInfo(TableSelectorInfo* info);

  DISALLOW_COPY_AND_ASSIGN(TableSelectorMetadataHelper);
};

// Information about a function regarding unboxed parameters and return value.
class UnboxingInfoMetadata : public ZoneAllocated {
 public:
  enum UnboxingInfoTag {
    kBoxed = 0,
    kUnboxedIntCandidate = 1 << 0,
    kUnboxedDoubleCandidate = 1 << 1,
    kUnboxingCandidate = kUnboxedIntCandidate | kUnboxedDoubleCandidate,
  };

  UnboxingInfoMetadata() : unboxed_args_info(0) { return_info = kBoxed; }

  void SetArgsCount(intptr_t num_args) {
    ASSERT(unboxed_args_info.is_empty());
    unboxed_args_info.SetLength(num_args);
    unboxed_args_info.FillWith(kBoxed, 0, num_args);
  }

  GrowableArray<UnboxingInfoTag> unboxed_args_info;
  UnboxingInfoTag return_info;

  DISALLOW_COPY_AND_ASSIGN(UnboxingInfoMetadata);
};

// Helper class which provides access to unboxing information metadata.
class UnboxingInfoMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.unboxing-info.metadata"; }

  explicit UnboxingInfoMetadataHelper(KernelReaderHelper* helper);

  UnboxingInfoMetadata* GetUnboxingInfoMetadata(intptr_t node_offset);

  DISALLOW_COPY_AND_ASSIGN(UnboxingInfoMetadataHelper);
};

class KernelReaderHelper {
 public:
  KernelReaderHelper(Zone* zone,
                     TranslationHelper* translation_helper,
                     const Script& script,
                     const ExternalTypedData& data,
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

  virtual ~KernelReaderHelper() = default;

  void SetOffset(intptr_t offset);

  intptr_t ReadListLength();
  virtual void ReportUnexpectedTag(const char* variant, Tag tag);

  void ReadUntilFunctionNode();

  Tag PeekTag(uint8_t* payload = NULL);

 protected:
  const Script& script() const { return script_; }

  virtual void set_current_script_id(intptr_t id) {
    // Do nothing by default.
    // This is overridden in KernelTokenPositionCollector.
    USE(id);
  }

  virtual void RecordTokenPosition(TokenPosition position) {
    // Do nothing by default.
    // This is overridden in KernelTokenPositionCollector.
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
  NameIndex ReadInterfaceMemberNameReference();
  StringIndex ReadNameAsStringIndex();
  const String& ReadNameAsMethodName();
  const String& ReadNameAsGetterName();
  const String& ReadNameAsSetterName();
  const String& ReadNameAsFieldName();
  void SkipFlags();
  void SkipStringReference();
  void SkipConstantReference();
  void SkipCanonicalNameReference();
  void SkipInterfaceMemberNameReference();
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
  TokenPosition ReadPosition();
  Tag ReadTag(uint8_t* payload = NULL);
  uint8_t ReadFlags() { return reader_.ReadFlags(); }
  Nullability ReadNullability();
  Variance ReadVariance();

  intptr_t SourceTableFieldCountFromFirstLibraryOffset();
  intptr_t SourceTableSize();
  intptr_t GetOffsetForSourceInfo(intptr_t index);
  String& SourceTableUriFor(intptr_t index);
  const String& GetSourceFor(intptr_t index);
  TypedDataPtr GetLineStartsFor(intptr_t index);
  String& SourceTableImportUriFor(intptr_t index, uint32_t binaryVersion);
  ExternalTypedDataPtr GetConstantCoverageFor(intptr_t index);

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
  friend class CallSiteAttributesMetadataHelper;
  friend class ConstantReader;
  friend class ConstantHelper;
  friend class ConstructorHelper;
  friend class DirectCallMetadataHelper;
  friend class FieldHelper;
  friend class FunctionNodeHelper;
  friend class InferredTypeMetadataHelper;
  friend class KernelLoader;
  friend class LibraryDependencyHelper;
  friend class LibraryHelper;
  friend class MetadataHelper;
  friend class ProcedureAttributesMetadataHelper;
  friend class ProcedureHelper;
  friend class SimpleExpressionConverter;
  friend class ScopeBuilder;
  friend class TableSelectorMetadataHelper;
  friend class TypeParameterHelper;
  friend class TypeTranslator;
  friend class UnboxingInfoMetadataHelper;
  friend class VariableDeclarationHelper;
  friend class ObfuscationProhibitionsMetadataHelper;
  friend class LoadingUnitsMetadataHelper;
  friend bool NeedsDynamicInvocationForwarder(const Function& function);
  friend ArrayPtr CollectConstConstructorCoverageFrom(
      const Script& interesting_script);

 private:
  DISALLOW_COPY_AND_ASSIGN(KernelReaderHelper);
};

class ActiveClass {
 public:
  ActiveClass()
      : klass(NULL),
        member(NULL),
        enclosing(NULL),
        local_type_parameters(NULL) {}

  bool HasMember() { return member != NULL; }

  bool MemberIsProcedure() {
    ASSERT(member != NULL);
    FunctionLayout::Kind function_kind = member->kind();
    return function_kind == FunctionLayout::kRegularFunction ||
           function_kind == FunctionLayout::kGetterFunction ||
           function_kind == FunctionLayout::kSetterFunction ||
           function_kind == FunctionLayout::kMethodExtractor ||
           function_kind == FunctionLayout::kDynamicInvocationForwarder ||
           member->IsFactory();
  }

  bool MemberIsFactoryProcedure() {
    ASSERT(member != NULL);
    return member->IsFactory();
  }

  bool RequireLegacyErasure(bool null_safety) const {
    return klass != nullptr && !null_safety &&
           Library::Handle(klass->library()).nnbd_compiled_mode() ==
               NNBDCompiledMode::kAgnostic;
  }

  intptr_t MemberTypeParameterCount(Zone* zone);

  intptr_t ClassNumTypeArguments() {
    ASSERT(klass != NULL);
    return klass->NumTypeArguments();
  }

  void RecordDerivedTypeParameter(Zone* zone,
                                  const TypeParameter& original,
                                  const TypeParameter& derived) {
    if (original.raw() != derived.raw() &&
        original.bound() == AbstractType::null()) {
      if (derived_type_parameters == nullptr) {
        derived_type_parameters = &GrowableObjectArray::Handle(
            zone, GrowableObjectArray::New(Heap::kOld));
      }
      derived_type_parameters->Add(derived);
    }
  }

  const char* ToCString() {
    return member != NULL ? member->ToCString() : klass->ToCString();
  }

  // The current enclosing class (or the library top-level class).
  const Class* klass;

  const Function* member;

  // The innermost enclosing function. This is used for building types, as a
  // parent for function types.
  const Function* enclosing;

  const TypeArguments* local_type_parameters;

  GrowableObjectArray* derived_type_parameters = nullptr;
};

class ActiveClassScope {
 public:
  ActiveClassScope(ActiveClass* active_class, const Class* klass)
      : active_class_(active_class), saved_(*active_class) {
    active_class_->klass = klass;
  }

  ~ActiveClassScope() { *active_class_ = saved_; }

 private:
  ActiveClass* active_class_;
  ActiveClass saved_;

  DISALLOW_COPY_AND_ASSIGN(ActiveClassScope);
};

class ActiveMemberScope {
 public:
  ActiveMemberScope(ActiveClass* active_class, const Function* member)
      : active_class_(active_class), saved_(*active_class) {
    // The class is inherited.
    active_class_->member = member;
  }

  ~ActiveMemberScope() { *active_class_ = saved_; }

 private:
  ActiveClass* active_class_;
  ActiveClass saved_;

  DISALLOW_COPY_AND_ASSIGN(ActiveMemberScope);
};

class ActiveEnclosingFunctionScope {
 public:
  ActiveEnclosingFunctionScope(ActiveClass* active_class,
                               const Function* enclosing)
      : active_class_(active_class), saved_(*active_class) {
    active_class_->enclosing = enclosing;
  }

  ~ActiveEnclosingFunctionScope() { *active_class_ = saved_; }

 private:
  ActiveClass* active_class_;
  ActiveClass saved_;

  DISALLOW_COPY_AND_ASSIGN(ActiveEnclosingFunctionScope);
};

class ActiveTypeParametersScope {
 public:
  // Set the local type parameters of the ActiveClass to be exactly all type
  // parameters defined by 'innermost' and any enclosing *closures* (but not
  // enclosing methods/top-level functions/classes).
  //
  // Also, the enclosing function is set to 'innermost'.
  ActiveTypeParametersScope(ActiveClass* active_class,
                            const Function& innermost,
                            Zone* Z);

  // Append the list of the local type parameters to the list in ActiveClass.
  //
  // Also, the enclosing function is set to 'function'.
  ActiveTypeParametersScope(ActiveClass* active_class,
                            const Function* function,
                            const TypeArguments& new_params,
                            Zone* Z);

  ~ActiveTypeParametersScope() { *active_class_ = saved_; }

 private:
  ActiveClass* active_class_;
  ActiveClass saved_;

  DISALLOW_COPY_AND_ASSIGN(ActiveTypeParametersScope);
};

class TypeTranslator {
 public:
  TypeTranslator(KernelReaderHelper* helper,
                 ConstantReader* constant_reader,
                 ActiveClass* active_class,
                 bool finalize = false,
                 bool apply_legacy_erasure = false);

  AbstractType& BuildType();
  AbstractType& BuildTypeWithoutFinalization();

  const TypeArguments& BuildTypeArguments(intptr_t length);

  const TypeArguments& BuildInstantiatedTypeArguments(
      const Class& receiver_class,
      intptr_t length);

  void LoadAndSetupTypeParameters(ActiveClass* active_class,
                                  const Object& set_on,
                                  intptr_t type_parameter_count,
                                  const Function& parameterized_function);

  const Type& ReceiverType(const Class& klass);

  void SetupFunctionParameters(const Class& klass,
                               const Function& function,
                               bool is_method,
                               bool is_closure,
                               FunctionNodeHelper* function_node_helper);

 private:
  void SetupUnboxingInfoMetadata(const Function& function,
                                 intptr_t library_kernel_offset);
  void SetupUnboxingInfoMetadataForFieldAccessors(
      const Function& field_accessor,
      intptr_t library_kernel_offset);

  void BuildTypeInternal();
  void BuildInterfaceType(bool simple);
  void BuildFunctionType(bool simple);
  void BuildTypeParameterType();

  class TypeParameterScope {
   public:
    TypeParameterScope(TypeTranslator* translator, intptr_t parameter_count)
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
    TypeTranslator* translator_;
  };

  KernelReaderHelper* helper_;
  ConstantReader* constant_reader_;
  TranslationHelper& translation_helper_;
  ActiveClass* const active_class_;
  TypeParameterScope* type_parameter_scope_;
  InferredTypeMetadataHelper inferred_type_metadata_helper_;
  UnboxingInfoMetadataHelper unboxing_info_metadata_helper_;
  Zone* zone_;
  AbstractType& result_;
  bool finalize_;
  const bool apply_legacy_erasure_;

  friend class ScopeBuilder;
  friend class KernelLoader;

  DISALLOW_COPY_AND_ASSIGN(TypeTranslator);
};

}  // namespace kernel
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_KERNEL_TRANSLATION_HELPER_H_
