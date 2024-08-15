// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BYTECODE_READER_H_
#define RUNTIME_VM_BYTECODE_READER_H_

#include "vm/globals.h"
#if defined(DART_DYNAMIC_MODULES)

#include "vm/bit_vector.h"
#include "vm/constants_kbc.h"
#include "vm/hash_table.h"
#include "vm/object.h"

namespace dart {
namespace bytecode {

class BytecodeComponentData;

class BytecodeLoader {
 public:
  BytecodeLoader(Thread* thread, const TypedDataBase& binary);
  ~BytecodeLoader();

  FunctionPtr LoadBytecode();

  TypedDataBasePtr binary() const { return binary_.ptr(); }
  ArrayPtr bytecode_component_array() const {
    return bytecode_component_array_.ptr();
  }

  void SetOffset(const Object& obj, intptr_t offset);
  intptr_t GetOffset(const Object& obj);

 private:
  Thread* thread_;
  const TypedDataBase& binary_;
  Array& bytecode_component_array_;
  Array& bytecode_offsets_map_;

  DISALLOW_COPY_AND_ASSIGN(BytecodeLoader);
};

class Reader : public ValueObject {
 public:
  explicit Reader(const TypedDataBase& typed_data) : typed_data_(&typed_data) {
    Init();
  }

  uint32_t ReadUInt32At(intptr_t offset) const {
    ASSERT((size_ >= 4) && (offset >= 0) && (offset <= size_ - 4));
    uint32_t value =
        LoadUnaligned(reinterpret_cast<const uint32_t*>(raw_buffer_ + offset));
    return Utils::BigEndianToHost32(value);
  }

  uint32_t ReadUInt32() {
    uint32_t value = ReadUInt32At(offset_);
    offset_ += 4;
    return value;
  }

  uint32_t ReadUInt() {
    ASSERT((size_ >= 1) && (offset_ >= 0) && (offset_ <= size_ - 1));

    const uint8_t* buffer = raw_buffer_;
    uword byte0 = buffer[offset_];
    if ((byte0 & 0x80) == 0) {
      // 0...
      offset_++;
      return byte0;
    } else if ((byte0 & 0xc0) == 0x80) {
      // 10...
      ASSERT((size_ >= 2) && (offset_ >= 0) && (offset_ <= size_ - 2));
      uint32_t value =
          ((byte0 & ~static_cast<uword>(0x80)) << 8) | (buffer[offset_ + 1]);
      offset_ += 2;
      return value;
    } else {
      // 11...
      ASSERT((size_ >= 4) && (offset_ >= 0) && (offset_ <= size_ - 4));
      uint32_t value = ((byte0 & ~static_cast<uword>(0xc0)) << 24) |
                       (buffer[offset_ + 1] << 16) |
                       (buffer[offset_ + 2] << 8) | (buffer[offset_ + 3] << 0);
      offset_ += 4;
      return value;
    }
  }

  intptr_t ReadSLEB128() {
    ReadStream stream(raw_buffer_, size_, offset_);
    const intptr_t result = stream.ReadSLEB128();
    offset_ = stream.Position();
    return result;
  }

  int64_t ReadSLEB128AsInt64() {
    ReadStream stream(raw_buffer_, size_, offset_);
    const int64_t result = stream.ReadSLEB128<int64_t>();
    offset_ = stream.Position();
    return result;
  }

  /**
   * Read and return a TokenPosition from this reader.
   */
  TokenPosition ReadPosition() {
    // Position is saved as unsigned,
    // but actually ranges from -1 and up (thus the -1)
    intptr_t value = ReadUInt() - 1;
    TokenPosition result = TokenPosition::Deserialize(value);
    return result;
  }

  intptr_t ReadListLength() { return ReadUInt(); }

  uint8_t ReadByte() { return raw_buffer_[offset_++]; }

  uint8_t PeekByte() { return raw_buffer_[offset_]; }

  void ReadBytes(uint8_t* buffer, uint8_t size) {
    for (int i = 0; i < size; i++) {
      buffer[i] = ReadByte();
    }
  }

  const TypedDataBase* typed_data() { return typed_data_; }

  intptr_t offset() const { return offset_; }
  void set_offset(intptr_t offset) {
    ASSERT(offset <= size_);
    offset_ = offset;
  }
  intptr_t size() const { return size_; }

  TypedDataViewPtr ViewFromTo(intptr_t start, intptr_t end) {
    return typed_data_->ViewFromTo(start, end, Heap::kOld);
  }

  const uint8_t* BufferAt(intptr_t offset) {
    ASSERT((offset >= 0) && (offset < size_));
    return &raw_buffer_[offset];
  }

 private:
  friend class AlternativeReadingScope;

  void Init() {
    ASSERT(typed_data_->IsExternalOrExternalView());
    raw_buffer_ = reinterpret_cast<uint8_t*>(typed_data_->DataAddr(0));
    size_ = typed_data_->LengthInBytes();
    offset_ = 0;
  }

  // A external typed data or a view on an external typed data.
  const TypedDataBase* typed_data_ = nullptr;

  // The raw data size/length of [typed_data_].
  const uint8_t* raw_buffer_ = nullptr;
  intptr_t size_ = 0;

  intptr_t offset_ = 0;
};

// A helper class that saves the current reader position, goes to another reader
// position, and upon destruction, resets to the original reader position.
class AlternativeReadingScope {
 public:
  AlternativeReadingScope(Reader* reader, intptr_t new_position)
      : reader_(reader), saved_offset_(reader_->offset_) {
    reader_->offset_ = new_position;
  }

  ~AlternativeReadingScope() { reader_->offset_ = saved_offset_; }

 private:
  Reader* const reader_;
  const intptr_t saved_offset_;

  DISALLOW_COPY_AND_ASSIGN(AlternativeReadingScope);
};

// Helper class for reading bytecode.
class BytecodeReaderHelper : public ValueObject {
 public:
  explicit BytecodeReaderHelper(Thread* thread,
                                const TypedDataBase& typed_data);

  explicit BytecodeReaderHelper(Thread* thread,
                                BytecodeComponentData* bytecode_component);

  Reader& reader() { return reader_; }

  void ReadCode(const Function& function, intptr_t code_offset);

  void ReadMembers(const Class& cls, bool discard_fields);

  void ReadFieldDeclarations(const Class& cls, bool discard_fields);
  void ReadFunctionDeclarations(const Class& cls);
  void ReadClassDeclaration(const Class& cls);
  void ReadLibraryDeclaration(const Library& library,
                              bool lookup_classes,
                              const GrowableObjectArray& pending_classes);
  void ReadLibraryDeclarations(intptr_t num_libraries);

  LibraryPtr ReadMain();

  ArrayPtr ReadBytecodeComponent();
  void ResetObjects();

  // Fills in [is_covariant] and [is_generic_covariant_impl] vectors
  // according to covariance attributes of [function] parameters.
  //
  // [function] should be declared in bytecode.
  // [is_covariant] and [is_generic_covariant_impl] should contain bitvectors
  // of function.NumParameters() length.
  void ReadParameterCovariance(const Function& function,
                               intptr_t code_offset,
                               BitVector* is_covariant,
                               BitVector* is_generic_covariant_impl);

  // Read bytecode PackedObject.
  ObjectPtr ReadObject();

 private:
  // These constants should match corresponding constants in class ObjectHandle
  // (pkg/dart2bytecode/lib/object_table.dart).
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
  static const int kFlagIsNullable = kFlagBit4;
  static const int kFlagsMask = (kTagMask | kFlagBit4 | kFlagBit5);

  // Code flags, must be in sync with Code constants in
  // pkg/dart2bytecode/lib/declarations.dart.
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
  // pkg/dart2bytecode/lib/declarations.dart.
  struct ClosureCode {
    static const int kHasExceptionsTableFlag = 1 << 0;
    static const int kHasSourcePositionsFlag = 1 << 1;
    static const int kHasLocalVariablesFlag = 1 << 2;
  };

  // Parameter flags, must be in sync with ParameterDeclaration constants in
  // pkg/dart2bytecode/lib/declarations.dart.
  struct Parameter {
    static const int kIsCovariantFlag = 1 << 0;
    static const int kIsGenericCovariantImplFlag = 1 << 1;
    static const int kIsFinalFlag = 1 << 2;
    static const int kIsRequiredFlag = 1 << 3;
  };

  class FunctionTypeScope : public ValueObject {
   public:
    explicit FunctionTypeScope(BytecodeReaderHelper* bytecode_reader,
                               const FunctionType& type)
        : bytecode_reader_(bytecode_reader) {
      bytecode_reader_->enclosing_function_types_.Add(&type);
    }

    ~FunctionTypeScope() {
      bytecode_reader_->enclosing_function_types_.RemoveLast();
    }

   private:
    BytecodeReaderHelper* const bytecode_reader_;
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
      bytecode_reader_->scoped_function_ = function.ptr();
      bytecode_reader_->scoped_function_name_ = name.ptr();
      bytecode_reader_->scoped_function_class_ = cls.ptr();
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
  FunctionTypePtr ReadFunctionSignature(const FunctionType& signature,
                                        bool has_optional_positional_params,
                                        bool has_optional_named_params,
                                        bool has_type_params,
                                        bool has_positional_param_names,
                                        bool has_parameter_flags);
  void ReadTypeParametersDeclaration(
      const Class& parameterized_class,
      const FunctionType& parameterized_signature);

  // Read portion of constant pool corresponding to one function/closure.
  // Start with [start_index], and stop when reaching EndClosureFunctionScope.
  // Return index of the last read constant pool entry.
  intptr_t ReadConstantPool(const Function& function,
                            const ObjectPool& pool,
                            intptr_t start_index);

  BytecodePtr ReadBytecode(const ObjectPool& pool);
  void ReadExceptionsTable(const Function& function,
                           const Bytecode& bytecode,
                           bool has_exceptions_table);
  void ReadSourcePositions(const Bytecode& bytecode, bool has_source_positions);
  void ReadLocalVariables(const Bytecode& bytecode, bool has_local_variables);
  StringPtr ConstructorName(const Class& cls, const String& name);

  ObjectPtr ReadObjectContents(uint32_t header);
  ObjectPtr ReadConstObject(intptr_t tag);
  ObjectPtr ReadType(intptr_t tag, Nullability nullability);
  StringPtr ReadString(bool is_canonical = true);
  TypeArgumentsPtr ReadTypeArguments();
  void SetupFieldAccessorFunction(const Class& klass,
                                  const Function& function,
                                  const AbstractType& field_type);
  PatchClassPtr GetPatchClass(const Class& cls, const Script& script);
  InstancePtr Canonicalize(const Instance& instance);

  // Similar to cls.EnsureClassDeclaration, but may be more efficient if
  // class is from the current kernel binary.
  void LoadReferencedClass(const Class& cls);

  Reader reader_;
  Thread* const thread_;
  Zone* const zone_;
  BytecodeComponentData* bytecode_component_;
  Array* closures_ = nullptr;
  PatchClass* patch_class_ = nullptr;
  Array* functions_ = nullptr;
  intptr_t function_index_ = 0;
  GrowableArray<const FunctionType*> enclosing_function_types_;
  Function& scoped_function_;
  String& scoped_function_name_;
  Class& scoped_function_class_;

  DISALLOW_COPY_AND_ASSIGN(BytecodeReaderHelper);
};

class BytecodeComponentData : ValueObject {
 public:
  enum {
    kTypedData,
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

  explicit BytecodeComponentData(const Array& data) : data_(data) {}

  TypedDataBasePtr GetTypedData() const;
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
                      const TypedDataBase& typed_data,
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
  const Array& data_;
};

class BytecodeReader : public AllStatic {
 public:
  // Read declaration of the given class.
  static void LoadClassDeclaration(const Class& cls);

  // Read members of the given class.
  static void FinishClassLoading(const Class& cls);

  static void ReadParameterCovariance(const Function& function,
                                      BitVector* is_covariant,
                                      BitVector* is_generic_covariant_impl);
};

class BytecodeSourcePositionsIterator : ValueObject {
 public:
  // These constants should match corresponding constants in class
  // SourcePositions (pkg/dart2bytecode/lib/source_positions.dart).
  static const intptr_t kSyntheticCodeMarker = -1;
  static const intptr_t kYieldPointMarker = -2;

  BytecodeSourcePositionsIterator(Zone* zone, const Bytecode& bytecode)
      : reader_(TypedDataBase::Handle(zone, bytecode.binary())) {
    ASSERT(bytecode.HasSourcePositions());
    reader_.set_offset(bytecode.source_positions_binary_offset());
    pairs_remaining_ = reader_.ReadUInt();
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
               : TokenPosition::Deserialize(cur_token_pos_);
  }

  bool IsYieldPoint() const { return is_yield_point_; }

 private:
  Reader reader_;
  intptr_t pairs_remaining_ = 0;
  intptr_t cur_bci_ = 0;
  intptr_t cur_token_pos_ = 0;
  bool is_yield_point_ = false;
};

}  // namespace bytecode
}  // namespace dart

#endif  // defined(DART_DYNAMIC_MODULES)
#endif  // RUNTIME_VM_BYTECODE_READER_H_
