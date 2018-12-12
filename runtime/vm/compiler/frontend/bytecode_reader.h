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
                                  TypeTranslator* type_translator,
                                  ActiveClass* active_class);

  bool HasBytecode(intptr_t node_offset);

  void ReadMetadata(const Function& function);

  RawArray* ReadBytecodeComponent();

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
  static const int kFlagsMask = (kFlagBit0 | kFlagBit1 | kFlagBit2);

  class FunctionTypeScope : public ValueObject {
   public:
    explicit FunctionTypeScope(BytecodeMetadataHelper* bytecode_reader)
        : bytecode_reader_(bytecode_reader),
          saved_type_parameters_(
              bytecode_reader->function_type_type_parameters_) {}

    ~FunctionTypeScope() {
      bytecode_reader_->function_type_type_parameters_ = saved_type_parameters_;
    }

   private:
    BytecodeMetadataHelper* bytecode_reader_;
    TypeArguments* const saved_type_parameters_;
  };

  void ReadClosureDeclaration(const Function& function, intptr_t closureIndex);
  RawType* ReadFunctionSignature(const Function& func,
                                 bool has_optional_positional_params,
                                 bool has_optional_named_params,
                                 bool has_type_params,
                                 bool has_positional_param_names);
  void ReadTypeParametersDeclaration(const Class& parameterized_class,
                                     const Function& parameterized_function,
                                     intptr_t num_type_params);

  void ReadConstantPool(const Function& function, const ObjectPool& pool);
  RawBytecode* ReadBytecode(const ObjectPool& pool);
  void ReadExceptionsTable(const Bytecode& bytecode, bool has_exceptions_table);
  void ReadSourcePositions(const Bytecode& bytecode, bool has_source_positions);
  RawTypedData* NativeEntry(const Function& function,
                            const String& external_name);

  RawObject* ReadObject();
  RawObject* ReadObjectContents(uint32_t header);
  RawString* ReadString(bool is_canonical = true);
  RawTypeArguments* ReadTypeArguments(const Class& instantiator);

  TypeTranslator& type_translator_;
  ActiveClass* const active_class_;
  BytecodeComponentData* bytecode_component_;
  Array* closures_;
  TypeArguments* function_type_type_parameters_;

  DISALLOW_COPY_AND_ASSIGN(BytecodeMetadataHelper);
};

class BytecodeComponentData : ValueObject {
 public:
  enum {
    kVersion,
    kStringsHeaderOffset,
    kStringsContentsOffset,
    kObjectsContentsOffset,
    kNumFields
  };

  explicit BytecodeComponentData(const Array& data) : data_(data) {}

  intptr_t GetVersion() const;
  intptr_t GetStringsHeaderOffset() const;
  intptr_t GetStringsContentsOffset() const;
  intptr_t GetObjectsContentsOffset() const;
  void SetObject(intptr_t index, const Object& obj) const;
  RawObject* GetObject(intptr_t index) const;

  bool IsNull() const { return data_.IsNull(); }

  static RawArray* New(Zone* zone,
                       intptr_t version,
                       intptr_t num_objects,
                       intptr_t strings_header_offset,
                       intptr_t strings_contents_offset,
                       intptr_t objects_contents_offset,
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
    cur_bci_ += reader_.ReadUInt();
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

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_READER_H_
