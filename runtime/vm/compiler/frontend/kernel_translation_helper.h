// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_KERNEL_TRANSLATION_HELPER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_KERNEL_TRANSLATION_HELPER_H_

#include "vm/kernel.h"
#include "vm/kernel_binary.h"
#include "vm/object.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

class KernelReaderHelper;

class TranslationHelper {
 public:
  explicit TranslationHelper(Thread* thread);

  virtual ~TranslationHelper() {}

  void Reset();

  void InitFromScript(const Script& script);

  void InitFromKernelProgramInfo(const KernelProgramInfo& info);

  Thread* thread() { return thread_; }

  Zone* zone() { return zone_; }

  Isolate* isolate() { return isolate_; }

  Heap::Space allocation_space() { return allocation_space_; }

  // Access to strings.
  const TypedData& string_offsets() { return string_offsets_; }
  void SetStringOffsets(const TypedData& string_offsets);

  const ExternalTypedData& string_data() { return string_data_; }
  void SetStringData(const ExternalTypedData& string_data);

  const TypedData& canonical_names() { return canonical_names_; }
  void SetCanonicalNames(const TypedData& canonical_names);

  const ExternalTypedData& metadata_payloads() { return metadata_payloads_; }
  void SetMetadataPayloads(const ExternalTypedData& metadata_payloads);

  const ExternalTypedData& metadata_mappings() { return metadata_mappings_; }
  void SetMetadataMappings(const ExternalTypedData& metadata_mappings);

  const Array& constants() { return constants_; }
  void SetConstants(const Array& constants);

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

  RawInstance* Canonicalize(const Instance& instance);

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
  virtual RawLibrary* LookupLibraryByKernelLibrary(NameIndex library);
  virtual RawClass* LookupClassByKernelClass(NameIndex klass);

  RawField* LookupFieldByKernelField(NameIndex field);
  RawFunction* LookupStaticMethodByKernelProcedure(NameIndex procedure);
  RawFunction* LookupConstructorByKernelConstructor(NameIndex constructor);
  RawFunction* LookupConstructorByKernelConstructor(const Class& owner,
                                                    NameIndex constructor);
  RawFunction* LookupConstructorByKernelConstructor(
      const Class& owner,
      StringIndex constructor_name);
  RawFunction* LookupMethodByMember(NameIndex target,
                                    const String& method_name);

  Type& GetCanonicalType(const Class& klass);

  void ReportError(const char* format, ...);
  void ReportError(const Script& script,
                   const TokenPosition position,
                   const char* format,
                   ...);
  void ReportError(const Error& prev_error, const char* format, ...);
  void ReportError(const Error& prev_error,
                   const Script& script,
                   const TokenPosition position,
                   const char* format,
                   ...);

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

  bool IsGenericCovariantImpl() {
    return (flags_ & kIsGenericCovariantImpl) != 0;
  }

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
      : annotation_count_(0), helper_(helper), next_read_(kPosition) {}

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
  intptr_t annotation_count_;

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
    kStartPosition,
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
  TokenPosition start_position_;
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
  TokenPosition start_position_;
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
  TokenPosition start_position_;
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
  MetadataHelper(KernelReaderHelper* helper,
                 const char* tag,
                 bool precompiler_only);

 protected:
  // Look for metadata mapping with node offset greater or equal than the given.
  intptr_t FindMetadataMapping(intptr_t node_offset);

  // Return offset of the metadata payload corresponding to the given node,
  // or -1 if there is no metadata.
  // Assumes metadata is accesses for nodes in linear order most of the time.
  intptr_t GetNextMetadataPayloadOffset(intptr_t node_offset);

  KernelReaderHelper* helper_;
  TranslationHelper& translation_helper_;

 private:
  void SetMetadataMappings(intptr_t mappings_offset, intptr_t mappings_num);
  void ScanMetadataMappings();

  const char* tag_;
  bool mappings_scanned_;
  bool precompiler_only_;
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

  explicit DirectCallMetadataHelper(KernelReaderHelper* helper);

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

  explicit InferredTypeMetadataHelper(KernelReaderHelper* helper);

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

  explicit ProcedureAttributesMetadataHelper(KernelReaderHelper* helper);

  ProcedureAttributesMetadata GetProcedureAttributes(intptr_t node_offset);

 private:
  bool ReadMetadata(intptr_t node_offset,
                    ProcedureAttributesMetadata* metadata);
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
  friend class StreamingConstantEvaluator;
  friend class StreamingScopeBuilder;
  friend class TypeParameterHelper;
  friend class TypeTranslator;
  friend class VariableDeclarationHelper;

#if defined(DART_USE_INTERPRETER)
  friend class BytecodeMetadataHelper;
#endif  // defined(DART_USE_INTERPRETER)
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
    RawFunction::Kind function_kind = member->kind();
    return function_kind == RawFunction::kRegularFunction ||
           function_kind == RawFunction::kGetterFunction ||
           function_kind == RawFunction::kSetterFunction ||
           function_kind == RawFunction::kMethodExtractor ||
           function_kind == RawFunction::kDynamicInvocationForwarder ||
           member->IsFactory();
  }

  bool MemberIsFactoryProcedure() {
    ASSERT(member != NULL);
    return member->IsFactory();
  }

  intptr_t MemberTypeParameterCount(Zone* zone);

  intptr_t ClassNumTypeArguments() {
    ASSERT(klass != NULL);
    return klass->NumTypeArguments();
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
};

class TypeTranslator {
 public:
  TypeTranslator(KernelReaderHelper* helper,
                 ActiveClass* active_class,
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

  void LoadAndSetupTypeParameters(ActiveClass* active_class,
                                  const Object& set_on,
                                  intptr_t type_parameter_count,
                                  const Function& parameterized_function);

  const Type& ReceiverType(const Class& klass);

 private:
  // Can build a malformed type.
  void BuildTypeInternal(bool invalid_as_dynamic = false);
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
  TranslationHelper& translation_helper_;
  ActiveClass* const active_class_;
  TypeParameterScope* type_parameter_scope_;
  Zone* zone_;
  AbstractType& result_;
  bool finalize_;

  friend class StreamingScopeBuilder;
  friend class KernelLoader;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_KERNEL_TRANSLATION_HELPER_H_
