// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/constants_kbc.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class BytecodeComponentData;

// Helper class which provides access to bytecode metadata.
class BytecodeMetadataHelper : public MetadataHelper {
 public:
  static const char* tag() { return "vm.bytecode"; }

  explicit BytecodeMetadataHelper(KernelReaderHelper* helper,
                                  ActiveClass* active_class);

  void ParseBytecodeFunction(ParsedFunction* parsed_function);

  // Read all library declarations.
  bool ReadLibraries();

  // Read specific library declaration.
  void ReadLibrary(const Library& library);

  // Scan through libraries in the bytecode component and figure out if any of
  // them will replace libraries which are already loaded.
  // Return true if bytecode component is found.
  bool FindModifiedLibrariesForHotReload(BitVector* modified_libs,
                                         bool* is_empty_program,
                                         intptr_t* p_num_classes,
                                         intptr_t* p_num_procedures);

  LibraryPtr GetMainLibrary();

  ArrayPtr GetBytecodeComponent();
  ArrayPtr ReadBytecodeComponent();

 private:
  ActiveClass* const active_class_;

  DISALLOW_COPY_AND_ASSIGN(BytecodeMetadataHelper);
};

// Helper class for reading bytecode.
class BytecodeReaderHelper : public ValueObject {
 public:
  explicit BytecodeReaderHelper(TranslationHelper* translation_helper,
                                ActiveClass* active_class,
                                BytecodeComponentData* bytecode_component);

  Reader& reader() { return reader_; }

  void ReadCode(const Function& function, intptr_t code_offset);

  ArrayPtr CreateForwarderChecks(const Function& function);

  void ReadMembers(const Class& cls, bool discard_fields);

  void ReadFieldDeclarations(const Class& cls, bool discard_fields);
  void ReadFunctionDeclarations(const Class& cls);
  void ReadClassDeclaration(const Class& cls);
  void ReadLibraryDeclaration(const Library& library, bool lookup_classes);
  void ReadLibraryDeclarations(intptr_t num_libraries);
  void FindAndReadSpecificLibrary(const Library& library,
                                  intptr_t num_libraries);
  void FindModifiedLibrariesForHotReload(BitVector* modified_libs,
                                         intptr_t num_libraries);

  void ParseBytecodeFunction(ParsedFunction* parsed_function,
                             const Function& function);

  LibraryPtr ReadMain();

  ArrayPtr ReadBytecodeComponent(intptr_t md_offset);
  void ResetObjects();

  // Fills in [is_covariant] and [is_generic_covariant_impl] vectors
  // according to covariance attributes of [function] parameters.
  //
  // [function] should be declared in bytecode.
  // [is_covariant] and [is_generic_covariant_impl] should contain bitvectors
  // of function.NumParameters() length.
  void ReadParameterCovariance(const Function& function,
                               BitVector* is_covariant,
                               BitVector* is_generic_covariant_impl);

  // Returns an flattened array of tuples {isFinal, defaultValue, metadata},
  // or an Error.
  ObjectPtr BuildParameterDescriptor(const Function& function);

  // Read bytecode PackedObject.
  ObjectPtr ReadObject();

 private:
  // These constants should match corresponding constants in class ObjectHandle
  // (pkg/vm/lib/bytecode/object_table.dart).
  static const int kReferenceBit = 1 << 0;
  static const int kIndexShift = 1;
  static const int kKindShift = 1;
  static const int kKindMask = 0x0f;
  static const int kFlagBit0 = 1 << 5;
  static const int kFlagBit1 = 1 << 6;
  static const int kFlagBit2 = 1 << 7;
  static const int kFlagBit3 = 1 << 8;
  static const int kFlagBit4 = 1 << 9;
  static const int kFlagBit5 = 1 << 10;
  static const int kTagMask = (kFlagBit0 | kFlagBit1 | kFlagBit2 | kFlagBit3);
  static const int kNullabilityMask = (kFlagBit4 | kFlagBit5);
  static const int kFlagsMask = (kTagMask | kNullabilityMask);

  // Code flags, must be in sync with Code constants in
  // pkg/vm/lib/bytecode/declarations.dart.
  struct Code {
    static const int kHasExceptionsTableFlag = 1 << 0;
    static const int kHasSourcePositionsFlag = 1 << 1;
    static const int kHasNullableFieldsFlag = 1 << 2;
    static const int kHasClosuresFlag = 1 << 3;
    static const int kHasParameterFlagsFlag = 1 << 4;
    static const int kHasForwardingStubTargetFlag = 1 << 5;
    static const int kHasDefaultFunctionTypeArgsFlag = 1 << 6;
    static const int kHasLocalVariablesFlag = 1 << 7;
  };

  // Closure code flags, must be in sync with ClosureCode constants in
  // pkg/vm/lib/bytecode/declarations.dart.
  struct ClosureCode {
    static const int kHasExceptionsTableFlag = 1 << 0;
    static const int kHasSourcePositionsFlag = 1 << 1;
    static const int kHasLocalVariablesFlag = 1 << 2;
  };

  // Parameter flags, must be in sync with ParameterDeclaration constants in
  // pkg/vm/lib/bytecode/declarations.dart.
  struct Parameter {
    static const int kIsCovariantFlag = 1 << 0;
    static const int kIsGenericCovariantImplFlag = 1 << 1;
    static const int kIsFinalFlag = 1 << 2;
    static const int kIsRequiredFlag = 1 << 3;
  };

  class FunctionTypeScope : public ValueObject {
   public:
    explicit FunctionTypeScope(BytecodeReaderHelper* bytecode_reader)
        : bytecode_reader_(bytecode_reader),
          saved_type_parameters_(
              bytecode_reader->function_type_type_parameters_) {}

    ~FunctionTypeScope() {
      bytecode_reader_->function_type_type_parameters_ = saved_type_parameters_;
    }

   private:
    BytecodeReaderHelper* bytecode_reader_;
    const TypeArguments* const saved_type_parameters_;
  };

  class FunctionScope : public ValueObject {
   public:
    FunctionScope(BytecodeReaderHelper* bytecode_reader,
                  const Function& function,
                  const String& name,
                  const Class& cls)
        : bytecode_reader_(bytecode_reader) {
      ASSERT(bytecode_reader_->scoped_function_.IsNull());
      ASSERT(bytecode_reader_->scoped_function_name_.IsNull());
      ASSERT(bytecode_reader_->scoped_function_class_.IsNull());
      ASSERT(name.IsSymbol());
      bytecode_reader_->scoped_function_ = function.raw();
      bytecode_reader_->scoped_function_name_ = name.raw();
      bytecode_reader_->scoped_function_class_ = cls.raw();
    }

    ~FunctionScope() {
      bytecode_reader_->scoped_function_ = Function::null();
      bytecode_reader_->scoped_function_name_ = String::null();
      bytecode_reader_->scoped_function_class_ = Class::null();
    }

   private:
    BytecodeReaderHelper* bytecode_reader_;
  };

  void ReadClosureDeclaration(const Function& function, intptr_t closureIndex);
  TypePtr ReadFunctionSignature(const Function& func,
                                bool has_optional_positional_params,
                                bool has_optional_named_params,
                                bool has_type_params,
                                bool has_positional_param_names,
                                bool has_parameter_flags,
                                Nullability nullability);
  void ReadTypeParametersDeclaration(const Class& parameterized_class,
                                     const Function& parameterized_function);

  // Read portion of constant pool corresponding to one function/closure.
  // Start with [start_index], and stop when reaching EndClosureFunctionScope.
  // Return index of the last read constant pool entry.
  intptr_t ReadConstantPool(const Function& function,
                            const ObjectPool& pool,
                            intptr_t start_index);

  BytecodePtr ReadBytecode(const ObjectPool& pool);
  void ReadExceptionsTable(const Bytecode& bytecode, bool has_exceptions_table);
  void ReadSourcePositions(const Bytecode& bytecode, bool has_source_positions);
  void ReadLocalVariables(const Bytecode& bytecode, bool has_local_variables);
  TypedDataPtr NativeEntry(const Function& function,
                           const String& external_name);
  StringPtr ConstructorName(const Class& cls, const String& name);

  ObjectPtr ReadObjectContents(uint32_t header);
  ObjectPtr ReadConstObject(intptr_t tag);
  ObjectPtr ReadType(intptr_t tag, Nullability nullability);
  StringPtr ReadString(bool is_canonical = true);
  ScriptPtr ReadSourceFile(const String& uri, intptr_t offset);
  TypeArgumentsPtr ReadTypeArguments();
  void ReadAttributes(const Object& key);
  PatchClassPtr GetPatchClass(const Class& cls, const Script& script);
  void ParseForwarderFunction(ParsedFunction* parsed_function,
                              const Function& function,
                              const Function& target);

  bool IsExpressionEvaluationLibrary(const Library& library) const {
    return expression_evaluation_library_ != nullptr &&
           expression_evaluation_library_->raw() == library.raw();
  }

  // Similar to cls.EnsureClassDeclaration, but may be more efficient if
  // class is from the current kernel binary.
  void LoadReferencedClass(const Class& cls);

  Reader reader_;
  TranslationHelper& translation_helper_;
  ActiveClass* const active_class_;
  Thread* const thread_;
  Zone* const zone_;
  BytecodeComponentData* bytecode_component_;
  Array* closures_ = nullptr;
  const TypeArguments* function_type_type_parameters_ = nullptr;
  GrowableObjectArray* pending_recursive_types_ = nullptr;
  PatchClass* patch_class_ = nullptr;
  Array* functions_ = nullptr;
  intptr_t function_index_ = 0;
  Function& scoped_function_;
  String& scoped_function_name_;
  Class& scoped_function_class_;
  Library* expression_evaluation_library_ = nullptr;
  bool loading_native_wrappers_library_ = false;
  bool reading_type_arguments_of_recursive_type_ = false;

  DISALLOW_COPY_AND_ASSIGN(BytecodeReaderHelper);
};

class BytecodeComponentData : ValueObject {
 public:
  enum {
    kVersion,
    kStringsHeaderOffset,
    kStringsContentsOffset,
    kObjectOffsetsOffset,
    kNumObjects,
    kObjectsContentsOffset,
    kMainOffset,
    kNumLibraries,
    kLibraryIndexOffset,
    kLibrariesOffset,
    kNumClasses,
    kClassesOffset,
    kMembersOffset,
    kNumCodes,
    kCodesOffset,
    kSourcePositionsOffset,
    kSourceFilesOffset,
    kLineStartsOffset,
    kLocalVariablesOffset,
    kAnnotationsOffset,
    kNumFields
  };

  explicit BytecodeComponentData(Array* data) : data_(*data) {}

  void Init(const Array& data) { data_ = data.raw(); }

  intptr_t GetVersion() const;
  intptr_t GetStringsHeaderOffset() const;
  intptr_t GetStringsContentsOffset() const;
  intptr_t GetObjectOffsetsOffset() const;
  intptr_t GetNumObjects() const;
  intptr_t GetObjectsContentsOffset() const;
  intptr_t GetMainOffset() const;
  intptr_t GetNumLibraries() const;
  intptr_t GetLibraryIndexOffset() const;
  intptr_t GetLibrariesOffset() const;
  intptr_t GetNumClasses() const;
  intptr_t GetClassesOffset() const;
  intptr_t GetMembersOffset() const;
  intptr_t GetNumCodes() const;
  intptr_t GetCodesOffset() const;
  intptr_t GetSourcePositionsOffset() const;
  intptr_t GetSourceFilesOffset() const;
  intptr_t GetLineStartsOffset() const;
  intptr_t GetLocalVariablesOffset() const;
  intptr_t GetAnnotationsOffset() const;
  void SetObject(intptr_t index, const Object& obj) const;
  ObjectPtr GetObject(intptr_t index) const;

  bool IsNull() const { return data_.IsNull(); }

  static ArrayPtr New(Zone* zone,
                      intptr_t version,
                      intptr_t num_objects,
                      intptr_t strings_header_offset,
                      intptr_t strings_contents_offset,
                      intptr_t object_offsets_offset,
                      intptr_t objects_contents_offset,
                      intptr_t main_offset,
                      intptr_t num_libraries,
                      intptr_t library_index_offset,
                      intptr_t libraries_offset,
                      intptr_t num_classes,
                      intptr_t classes_offset,
                      intptr_t members_offset,
                      intptr_t num_codes,
                      intptr_t codes_offset,
                      intptr_t source_positions_offset,
                      intptr_t source_files_offset,
                      intptr_t line_starts_offset,
                      intptr_t local_variables_offset,
                      intptr_t annotations_offset,
                      Heap::Space space);

 private:
  Array& data_;
};

class BytecodeReader : public AllStatic {
 public:
  // Reads bytecode for the given function and sets its bytecode field.
  // Returns error (if any), or null.
  static ErrorPtr ReadFunctionBytecode(Thread* thread,
                                       const Function& function);

  // Read annotations for the given annotation field.
  static ObjectPtr ReadAnnotation(const Field& annotation_field);
  // Read the |count| annotations following given annotation field.
  static ArrayPtr ReadExtendedAnnotations(const Field& annotation_field,
                                          intptr_t count);

  static void ResetObjectTable(const KernelProgramInfo& info);

  // Read declaration of the given library.
  static void LoadLibraryDeclaration(const Library& library);

  // Read declaration of the given class.
  static void LoadClassDeclaration(const Class& cls);

  // Read members of the given class.
  static void FinishClassLoading(const Class& cls);

  // Value of attribute [name] of Function/Field [key].
  static ObjectPtr GetBytecodeAttribute(const Object& key, const String& name);

#if !defined(PRODUCT)
  // Compute local variable descriptors for [function] with [bytecode].
  static LocalVarDescriptorsPtr ComputeLocalVarDescriptors(
      Zone* zone,
      const Function& function,
      const Bytecode& bytecode);
#endif
};

class InferredTypeBytecodeAttribute : public AllStatic {
 public:
  // Number of array elements per entry in InferredType bytecode
  // attribute (PC, type, flags).
  static constexpr intptr_t kNumElements = 3;

  // Field type is the first entry with PC = -1.
  static constexpr intptr_t kFieldTypePC = -1;

  // Returns PC at given index.
  static intptr_t GetPCAt(const Array& attr, intptr_t index) {
    return Smi::Value(Smi::RawCast(attr.At(index)));
  }

  // Returns InferredType metadata at given index.
  static InferredTypeMetadata GetInferredTypeAt(Zone* zone,
                                                const Array& attr,
                                                intptr_t index);
};

class BytecodeSourcePositionsIterator : ValueObject {
 public:
  // These constants should match corresponding constants in class
  // SourcePositions (pkg/vm/lib/bytecode/source_positions.dart).
  static const intptr_t kSyntheticCodeMarker = -1;
  static const intptr_t kYieldPointMarker = -2;

  BytecodeSourcePositionsIterator(Zone* zone, const Bytecode& bytecode)
      : reader_(ExternalTypedData::Handle(zone, bytecode.GetBinary(zone))) {
    if (bytecode.HasSourcePositions()) {
      reader_.set_offset(bytecode.source_positions_binary_offset());
      pairs_remaining_ = reader_.ReadUInt();
    }
  }

  bool MoveNext() {
    if (pairs_remaining_ == 0) {
      return false;
    }
    ASSERT(pairs_remaining_ > 0);
    --pairs_remaining_;
    cur_bci_ += reader_.ReadUInt();
    cur_token_pos_ += reader_.ReadSLEB128();
    is_yield_point_ = false;
    if (cur_token_pos_ == kYieldPointMarker) {
      const bool result = MoveNext();
      is_yield_point_ = true;
      return result;
    }
    return true;
  }

  uword PcOffset() const { return cur_bci_; }

  TokenPosition TokenPos() const {
    return (cur_token_pos_ == kSyntheticCodeMarker)
               ? TokenPosition::kNoSource
               : TokenPosition(cur_token_pos_);
  }

  bool IsYieldPoint() const { return is_yield_point_; }

 private:
  Reader reader_;
  intptr_t pairs_remaining_ = 0;
  intptr_t cur_bci_ = 0;
  intptr_t cur_token_pos_ = 0;
  bool is_yield_point_ = false;
};

class BytecodeLocalVariablesIterator : ValueObject {
 public:
  // These constants should match corresponding constants in
  // pkg/vm/lib/bytecode/local_variable_table.dart.
  enum {
    kInvalid,
    kScope,
    kVariableDeclaration,
    kContextVariable,
  };

  static const intptr_t kKindMask = 0xF;
  static const intptr_t kIsCapturedFlag = 1 << 4;

  BytecodeLocalVariablesIterator(Zone* zone, const Bytecode& bytecode)
      : reader_(ExternalTypedData::Handle(zone, bytecode.GetBinary(zone))),
        object_pool_(ObjectPool::Handle(zone, bytecode.object_pool())) {
    if (bytecode.HasLocalVariablesInfo()) {
      reader_.set_offset(bytecode.local_variables_binary_offset());
      entries_remaining_ = reader_.ReadUInt();
    }
  }

  bool MoveNext() {
    if (entries_remaining_ <= 0) {
      // Finished looking at the last entry, now we're done.
      entries_remaining_ = -1;
      return false;
    }
    --entries_remaining_;
    cur_kind_and_flags_ = reader_.ReadByte();
    cur_start_pc_ += reader_.ReadSLEB128();
    switch (Kind()) {
      case kScope:
        cur_end_pc_ = cur_start_pc_ + reader_.ReadUInt();
        cur_index_ = reader_.ReadSLEB128();
        cur_token_pos_ = reader_.ReadPosition();
        cur_end_token_pos_ = reader_.ReadPosition();
        break;
      case kVariableDeclaration:
        cur_index_ = reader_.ReadSLEB128();
        cur_name_ = reader_.ReadUInt();
        cur_type_ = reader_.ReadUInt();
        cur_declaration_token_pos_ = reader_.ReadPosition();
        cur_token_pos_ = reader_.ReadPosition();
        break;
      case kContextVariable:
        cur_index_ = reader_.ReadSLEB128();
        break;
    }
    return true;
  }

  // Returns true after iterator moved past the last entry and
  // MoveNext() returned false.
  bool IsDone() const { return entries_remaining_ < 0; }

  intptr_t Kind() const { return cur_kind_and_flags_ & kKindMask; }
  bool IsScope() const { return Kind() == kScope; }
  bool IsVariableDeclaration() const { return Kind() == kVariableDeclaration; }
  bool IsContextVariable() const { return Kind() == kContextVariable; }

  intptr_t StartPC() const { return cur_start_pc_; }
  intptr_t EndPC() const {
    ASSERT(IsScope() || IsVariableDeclaration());
    return cur_end_pc_;
  }
  intptr_t ContextLevel() const {
    ASSERT(IsScope());
    return cur_index_;
  }
  TokenPosition StartTokenPos() const {
    ASSERT(IsScope() || IsVariableDeclaration());
    return cur_token_pos_;
  }
  TokenPosition EndTokenPos() const {
    ASSERT(IsScope() || IsVariableDeclaration());
    return cur_end_token_pos_;
  }
  intptr_t Index() const {
    ASSERT(IsVariableDeclaration() || IsContextVariable());
    return cur_index_;
  }
  StringPtr Name() const {
    ASSERT(IsVariableDeclaration());
    return String::RawCast(object_pool_.ObjectAt(cur_name_));
  }
  AbstractTypePtr Type() const {
    ASSERT(IsVariableDeclaration());
    return AbstractType::RawCast(object_pool_.ObjectAt(cur_type_));
  }
  TokenPosition DeclarationTokenPos() const {
    ASSERT(IsVariableDeclaration());
    return cur_declaration_token_pos_;
  }
  bool IsCaptured() const {
    ASSERT(IsVariableDeclaration());
    return (cur_kind_and_flags_ & kIsCapturedFlag) != 0;
  }

 private:
  Reader reader_;
  const ObjectPool& object_pool_;
  intptr_t entries_remaining_ = 0;
  intptr_t cur_kind_and_flags_ = 0;
  intptr_t cur_start_pc_ = 0;
  intptr_t cur_end_pc_ = 0;
  intptr_t cur_index_ = -1;
  intptr_t cur_name_ = -1;
  intptr_t cur_type_ = -1;
  TokenPosition cur_token_pos_ = TokenPosition::kNoSource;
  TokenPosition cur_declaration_token_pos_ = TokenPosition::kNoSource;
  TokenPosition cur_end_token_pos_ = TokenPosition::kNoSource;
};

class BytecodeAttributesMapTraits {
 public:
  static const char* Name() { return "BytecodeAttributesMapTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    return a.raw() == b.raw();
  }

  static uword Hash(const Object& key) {
    return String::HashRawSymbol(key.IsFunction() ? Function::Cast(key).name()
                                                  : Field::Cast(key).name());
  }
};
typedef UnorderedHashMap<BytecodeAttributesMapTraits> BytecodeAttributesMap;

bool IsStaticFieldGetterGeneratedAsInitializer(const Function& function,
                                               Zone* zone);

}  // namespace kernel
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_
