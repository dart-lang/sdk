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

  bool HasBytecode(intptr_t node_offset);

  void ReadMetadata(const Function& function);

  void ParseBytecodeFunction(ParsedFunction* parsed_function);
  void ParseBytecodeImplicitClosureFunction(ParsedFunction* parsed_function);

  // Reads members associated with given [node_offset] and fills in [cls].
  // Discards fields if [discard_fields] is true.
  // Returns true if class members are loaded.
  bool ReadMembers(intptr_t node_offset, const Class& cls, bool discard_fields);

  // Read annotation at given offset.
  RawObject* ReadAnnotation(intptr_t annotation_offset);

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
  explicit BytecodeReaderHelper(KernelReaderHelper* helper,
                                ActiveClass* active_class,
                                BytecodeComponentData* bytecode_component);

  void ReadCode(const Function& function, intptr_t code_offset);

  void ReadMembers(const Class& cls,
                   intptr_t members_offset,
                   bool discard_fields);

  void ReadFieldDeclarations(const Class& cls, bool discard_fields);
  void ReadFunctionDeclarations(const Class& cls);

  void ParseBytecodeFunction(ParsedFunction* parsed_function,
                             const Function& function);

  RawLibrary* ReadMain();

  RawArray* ReadBytecodeComponent(intptr_t md_offset);
  RawArray* ReadBytecodeComponentV2(intptr_t md_offset);

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
    TypeArguments* const saved_type_parameters_;
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

  KernelReaderHelper* const helper_;
  TranslationHelper& translation_helper_;
  ActiveClass* const active_class_;
  Zone* const zone_;
  BytecodeComponentData* const bytecode_component_;
  Array* closures_ = nullptr;
  TypeArguments* function_type_type_parameters_ = nullptr;
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
};

class BytecodeSourcePositionsIterator : ValueObject {
 public:
  BytecodeSourcePositionsIterator(Zone* zone, const Bytecode& bytecode)
      : reader_(ExternalTypedData::Handle(zone, bytecode.GetBinary(zone))),
        pairs_remaining_(0),
        cur_bci_(0),
        cur_token_pos_(TokenPosition::kNoSource.value()) {
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
    const int kPCMultiplier = 4;
    cur_bci_ += reader_.ReadUInt() * kPCMultiplier;
    cur_token_pos_ += reader_.ReadSLEB128();
    return true;
  }

  intptr_t BytecodeInstructionIndex() const { return cur_bci_; }

  uword PcOffset() const {
    return KernelBytecode::BytecodePcToOffset(BytecodeInstructionIndex(),
                                              /* is_return_address = */ true);
  }

  TokenPosition TokenPos() const { return TokenPosition(cur_token_pos_); }

 private:
  Reader reader_;
  intptr_t pairs_remaining_;
  intptr_t cur_bci_;
  intptr_t cur_token_pos_;
};

bool IsStaticFieldGetterGeneratedAsInitializer(const Function& function,
                                               Zone* zone);

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_
