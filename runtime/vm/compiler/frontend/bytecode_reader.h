// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_

#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/constants_kbc.h"
#include "vm/object.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

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
  void ParseBytecodeImplicitClosureFunction(ParsedFunction* parsed_function);

  // Reads members associated with given [node_offset] and fills in [cls].
  // Discards fields if [discard_fields] is true.
  // Returns true if class members are loaded.
  bool ReadMembers(intptr_t node_offset, const Class& cls, bool discard_fields);

  RawLibrary* GetMainLibrary();

  RawArray* GetBytecodeComponent();
  RawArray* ReadBytecodeComponent();

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

  RawArray* CreateForwarderChecks(const Function& function);

  void ReadMembers(const Class& cls,
                   intptr_t members_offset,
                   bool discard_fields);

  void ReadFieldDeclarations(const Class& cls, bool discard_fields);
  void ReadFunctionDeclarations(const Class& cls);

  void ParseBytecodeFunction(ParsedFunction* parsed_function,
                             const Function& function);

  RawLibrary* ReadMain();

  RawArray* ReadBytecodeComponent(intptr_t md_offset);

  // Fills in [is_covariant] and [is_generic_covariant_impl] vectors
  // according to covariance attributes of [function] parameters.
  //
  // [function] should be declared in bytecode.
  // [is_covariant] and [is_generic_covariant_impl] should contain bitvectors
  // of function.NumParameters() length.
  void ReadParameterCovariance(const Function& function,
                               BitVector* is_covariant,
                               BitVector* is_generic_covariant_impl);

  // Read bytecode PackedObject.
  RawObject* ReadObject();

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
  static const int kFlagsMask = (kFlagBit0 | kFlagBit1 | kFlagBit2 | kFlagBit3);

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
  RawType* ReadFunctionSignature(const Function& func,
                                 bool has_optional_positional_params,
                                 bool has_optional_named_params,
                                 bool has_type_params,
                                 bool has_positional_param_names);
  void ReadTypeParametersDeclaration(const Class& parameterized_class,
                                     const Function& parameterized_function);

  void ReadConstantPool(const Function& function, const ObjectPool& pool);
  RawBytecode* ReadBytecode(const ObjectPool& pool);
  void ReadExceptionsTable(const Bytecode& bytecode, bool has_exceptions_table);
  void ReadSourcePositions(const Bytecode& bytecode, bool has_source_positions);
  void ReadLocalVariables(const Bytecode& bytecode, bool has_local_variables);
  RawTypedData* NativeEntry(const Function& function,
                            const String& external_name);
  RawString* ConstructorName(const Class& cls, const String& name);

  RawObject* ReadObjectContents(uint32_t header);
  RawObject* ReadConstObject(intptr_t tag);
  RawString* ReadString(bool is_canonical = true);
  RawTypeArguments* ReadTypeArguments(const Class& instantiator);
  RawPatchClass* GetPatchClass(const Class& cls, const Script& script);
  void ParseForwarderFunction(ParsedFunction* parsed_function,
                              const Function& function,
                              const Function& target);

  Reader reader_;
  TranslationHelper& translation_helper_;
  ActiveClass* const active_class_;
  Thread* const thread_;
  Zone* const zone_;
  BytecodeComponentData* const bytecode_component_;
  Array* closures_ = nullptr;
  const TypeArguments* function_type_type_parameters_ = nullptr;
  PatchClass* patch_class_ = nullptr;
  Array* functions_ = nullptr;
  intptr_t function_index_ = 0;
  Function& scoped_function_;
  String& scoped_function_name_;
  Class& scoped_function_class_;

  DISALLOW_COPY_AND_ASSIGN(BytecodeReaderHelper);
};

class BytecodeComponentData : ValueObject {
 public:
  enum {
    kVersion,
    kStringsHeaderOffset,
    kStringsContentsOffset,
    kObjectsContentsOffset,
    kMainOffset,
    kMembersOffset,
    kCodesOffset,
    kSourcePositionsOffset,
    kLocalVariablesOffset,
    kAnnotationsOffset,
    kNumFields
  };

  explicit BytecodeComponentData(const Array& data) : data_(data) {}

  intptr_t GetVersion() const;
  intptr_t GetStringsHeaderOffset() const;
  intptr_t GetStringsContentsOffset() const;
  intptr_t GetObjectsContentsOffset() const;
  intptr_t GetMainOffset() const;
  intptr_t GetMembersOffset() const;
  intptr_t GetCodesOffset() const;
  intptr_t GetSourcePositionsOffset() const;
  intptr_t GetLocalVariablesOffset() const;
  intptr_t GetAnnotationsOffset() const;
  void SetObject(intptr_t index, const Object& obj) const;
  RawObject* GetObject(intptr_t index) const;

  bool IsNull() const { return data_.IsNull(); }

  static RawArray* New(Zone* zone,
                       intptr_t version,
                       intptr_t num_objects,
                       intptr_t strings_header_offset,
                       intptr_t strings_contents_offset,
                       intptr_t objects_contents_offset,
                       intptr_t main_offset,
                       intptr_t members_offset,
                       intptr_t codes_offset,
                       intptr_t source_positions_offset,
                       intptr_t local_variables_offset,
                       intptr_t annotations_offset,
                       Heap::Space space);

 private:
  const Array& data_;
};

class BytecodeReader : public AllStatic {
 public:
  // Reads bytecode for the given function and sets its bytecode field.
  // Returns error (if any), or null.
  static RawError* ReadFunctionBytecode(Thread* thread,
                                        const Function& function);

  // Read annotation for the given annotation field.
  static RawObject* ReadAnnotation(const Field& annotation_field);

#if !defined(PRODUCT)
  // Compute local variable descriptors for [function] with [bytecode].
  static RawLocalVarDescriptors* ComputeLocalVarDescriptors(
      Zone* zone,
      const Function& function,
      const Bytecode& bytecode);
#endif

  static void UseBytecodeVersion(intptr_t version);
};

class BytecodeSourcePositionsIterator : ValueObject {
 public:
  BytecodeSourcePositionsIterator(Zone* zone, const Bytecode& bytecode)
      : reader_(ExternalTypedData::Handle(zone, bytecode.GetBinary(zone))) {
    if (bytecode.HasSourcePositions()) {
      reader_.set_offset(bytecode.source_positions_binary_offset());
      pairs_remaining_ = reader_.ReadUInt();
      if (Isolate::Current()->is_using_old_bytecode_instructions()) {
        pc_shifter_ = 2;
      }
    }
  }

  bool MoveNext() {
    if (pairs_remaining_ == 0) {
      return false;
    }
    ASSERT(pairs_remaining_ > 0);
    --pairs_remaining_;
    cur_bci_ += reader_.ReadUInt() << pc_shifter_;
    cur_token_pos_ += reader_.ReadSLEB128();
    return true;
  }

  uword PcOffset() const { return cur_bci_; }

  TokenPosition TokenPos() const { return TokenPosition(cur_token_pos_); }

 private:
  Reader reader_;
  intptr_t pairs_remaining_ = 0;
  intptr_t pc_shifter_ = 0;
  intptr_t cur_bci_ = 0;
  intptr_t cur_token_pos_ = 0;
};

#if !defined(PRODUCT)
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
    if (entries_remaining_ == 0) {
      return false;
    }
    ASSERT(entries_remaining_ > 0);
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
  RawString* Name() const {
    ASSERT(IsVariableDeclaration());
    return String::RawCast(object_pool_.ObjectAt(cur_name_));
  }
  RawAbstractType* Type() const {
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
#endif  // !defined(PRODUCT)

bool IsStaticFieldGetterGeneratedAsInitializer(const Function& function,
                                               Zone* zone);

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_
