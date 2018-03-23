// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_BINARY_H_
#define RUNTIME_VM_KERNEL_BINARY_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include <map>

#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/kernel.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

// Keep in sync with package:kernel/lib/binary/tag.dart.

static const uint32_t kMagicProgramFile = 0x90ABCDEFu;
static const uint32_t kBinaryFormatVersion = 3;

// Keep in sync with package:kernel/lib/binary/tag.dart
#define KERNEL_TAG_LIST(V)                                                     \
  V(Nothing, 0)                                                                \
  V(Something, 1)                                                              \
  V(Class, 2)                                                                  \
  V(FunctionNode, 3)                                                           \
  V(Field, 4)                                                                  \
  V(Constructor, 5)                                                            \
  V(Procedure, 6)                                                              \
  V(RedirectingFactoryConstructor, 108)                                        \
  V(InvalidInitializer, 7)                                                     \
  V(FieldInitializer, 8)                                                       \
  V(SuperInitializer, 9)                                                       \
  V(RedirectingInitializer, 10)                                                \
  V(LocalInitializer, 11)                                                      \
  V(AssertInitializer, 12)                                                     \
  V(CheckLibraryIsLoaded, 13)                                                  \
  V(LoadLibrary, 14)                                                           \
  V(DirectPropertyGet, 15)                                                     \
  V(DirectPropertySet, 16)                                                     \
  V(DirectMethodInvocation, 17)                                                \
  V(ConstStaticInvocation, 18)                                                 \
  V(InvalidExpression, 19)                                                     \
  V(VariableGet, 20)                                                           \
  V(VariableSet, 21)                                                           \
  V(PropertyGet, 22)                                                           \
  V(PropertySet, 23)                                                           \
  V(SuperPropertyGet, 24)                                                      \
  V(SuperPropertySet, 25)                                                      \
  V(StaticGet, 26)                                                             \
  V(StaticSet, 27)                                                             \
  V(MethodInvocation, 28)                                                      \
  V(SuperMethodInvocation, 29)                                                 \
  V(StaticInvocation, 30)                                                      \
  V(ConstructorInvocation, 31)                                                 \
  V(ConstConstructorInvocation, 32)                                            \
  V(Not, 33)                                                                   \
  V(LogicalExpression, 34)                                                     \
  V(ConditionalExpression, 35)                                                 \
  V(StringConcatenation, 36)                                                   \
  V(IsExpression, 37)                                                          \
  V(AsExpression, 38)                                                          \
  V(StringLiteral, 39)                                                         \
  V(DoubleLiteral, 40)                                                         \
  V(TrueLiteral, 41)                                                           \
  V(FalseLiteral, 42)                                                          \
  V(NullLiteral, 43)                                                           \
  V(SymbolLiteral, 44)                                                         \
  V(TypeLiteral, 45)                                                           \
  V(ThisExpression, 46)                                                        \
  V(Rethrow, 47)                                                               \
  V(Throw, 48)                                                                 \
  V(ListLiteral, 49)                                                           \
  V(MapLiteral, 50)                                                            \
  V(AwaitExpression, 51)                                                       \
  V(FunctionExpression, 52)                                                    \
  V(Let, 53)                                                                   \
  V(Instantiation, 54)                                                         \
  V(PositiveIntLiteral, 55)                                                    \
  V(NegativeIntLiteral, 56)                                                    \
  V(BigIntLiteral, 57)                                                         \
  V(ConstListLiteral, 58)                                                      \
  V(ConstMapLiteral, 59)                                                       \
  V(ExpressionStatement, 61)                                                   \
  V(Block, 62)                                                                 \
  V(EmptyStatement, 63)                                                        \
  V(AssertStatement, 64)                                                       \
  V(LabeledStatement, 65)                                                      \
  V(BreakStatement, 66)                                                        \
  V(WhileStatement, 67)                                                        \
  V(DoStatement, 68)                                                           \
  V(ForStatement, 69)                                                          \
  V(ForInStatement, 70)                                                        \
  V(SwitchStatement, 71)                                                       \
  V(ContinueSwitchStatement, 72)                                               \
  V(IfStatement, 73)                                                           \
  V(ReturnStatement, 74)                                                       \
  V(TryCatch, 75)                                                              \
  V(TryFinally, 76)                                                            \
  V(YieldStatement, 77)                                                        \
  V(VariableDeclaration, 78)                                                   \
  V(FunctionDeclaration, 79)                                                   \
  V(AsyncForInStatement, 80)                                                   \
  V(AssertBlock, 81)                                                           \
  V(TypedefType, 87)                                                           \
  V(VectorType, 88)                                                            \
  V(BottomType, 89)                                                            \
  V(InvalidType, 90)                                                           \
  V(DynamicType, 91)                                                           \
  V(VoidType, 92)                                                              \
  V(InterfaceType, 93)                                                         \
  V(FunctionType, 94)                                                          \
  V(TypeParameterType, 95)                                                     \
  V(SimpleInterfaceType, 96)                                                   \
  V(SimpleFunctionType, 97)                                                    \
  V(NullReference, 99)                                                         \
  V(ClassReference, 100)                                                       \
  V(MemberReference, 101)                                                      \
  V(VectorCreation, 102)                                                       \
  V(VectorGet, 103)                                                            \
  V(VectorSet, 104)                                                            \
  V(VectorCopy, 105)                                                           \
  V(ClosureCreation, 106)                                                      \
  V(ConstantExpression, 107)                                                   \
  V(SpecializedVariableGet, 128)                                               \
  V(SpecializedVariableSet, 136)                                               \
  V(SpecializedIntLiteral, 144)

static const intptr_t kSpecializedTagHighBit = 0x80;
static const intptr_t kSpecializedTagMask = 0xf8;
static const intptr_t kSpecializedPayloadMask = 0x7;

enum Tag {
#define DECLARE(Name, value) k##Name = value,
  KERNEL_TAG_LIST(DECLARE)
#undef DECLARE
};

// Keep in sync with package:kernel/lib/binary/tag.dart
enum ConstantTag {
  kNullConstant = 0,
  kBoolConstant = 1,
  kIntConstant = 2,
  kDoubleConstant = 3,
  kStringConstant = 4,
  kMapConstant = 5,
  kListConstant = 6,
  kInstanceConstant = 7,
  kTearOffConstant = 8,
  kTypeLiteralConstant = 9,
};

static const int SpecializedIntLiteralBias = 3;
static const int LibraryCountFieldCountFromEnd = 1;
static const int SourceTableFieldCountFromFirstLibraryOffset = 4;

static const int HeaderSize = 8;  // 'magic', 'formatVersion'.
static const int MetadataPayloadOffset = HeaderSize;  // Right after header.

class Reader {
 public:
  Reader(const uint8_t* buffer, intptr_t size)
      : thread_(NULL),
        raw_buffer_(buffer),
        typed_data_(NULL),
        size_(size),
        offset_(0) {}

  explicit Reader(const TypedData& typed_data)
      : thread_(Thread::Current()),
        raw_buffer_(NULL),
        typed_data_(&typed_data),
        size_(typed_data.IsNull() ? 0 : typed_data.Length()),
        offset_(0) {}

  uint32_t ReadFromIndex(intptr_t end_offset,
                         intptr_t fields_before,
                         intptr_t list_size,
                         intptr_t list_index) {
    intptr_t org_offset = offset();
    uint32_t result =
        ReadFromIndexNoReset(end_offset, fields_before, list_size, list_index);
    set_offset(org_offset);
    return result;
  }

  uint32_t ReadUInt32At(intptr_t offset) const {
    ASSERT((size_ >= 4) && (offset >= 0) && (offset <= size_ - 4));
    uint32_t value;
    if (raw_buffer_ != NULL) {
      value = *reinterpret_cast<const uint32_t*>(raw_buffer_ + offset);
    } else {
      value = typed_data_->GetUint32(offset);
    }
    return Utils::BigEndianToHost32(value);
  }

  uint32_t ReadFromIndexNoReset(intptr_t end_offset,
                                intptr_t fields_before,
                                intptr_t list_size,
                                intptr_t list_index) {
    set_offset(end_offset - (fields_before + list_size - list_index) * 4);
    return ReadUInt32();
  }

  uint32_t ReadUInt32() {
    uint32_t value = ReadUInt32At(offset_);
    offset_ += 4;
    return value;
  }

  uint32_t ReadUInt() {
    ASSERT((size_ >= 1) && (offset_ >= 0) && (offset_ <= size_ - 1));

    const uint8_t* buffer = this->buffer();
    uint8_t byte0 = buffer[offset_];
    if ((byte0 & 0x80) == 0) {
      // 0...
      offset_++;
      return byte0;
    } else if ((byte0 & 0xc0) == 0x80) {
      // 10...
      ASSERT((size_ >= 2) && (offset_ >= 0) && (offset_ <= size_ - 2));
      uint32_t value = ((byte0 & ~0x80) << 8) | (buffer[offset_ + 1]);
      offset_ += 2;
      return value;
    } else {
      // 11...
      ASSERT((size_ >= 4) && (offset_ >= 0) && (offset_ <= size_ - 4));
      uint32_t value = ((byte0 & ~0xc0) << 24) | (buffer[offset_ + 1] << 16) |
                       (buffer[offset_ + 2] << 8) | (buffer[offset_ + 3] << 0);
      offset_ += 4;
      return value;
    }
  }

  /**
   * Read and return a TokenPosition from this reader.
   */
  TokenPosition ReadPosition() {
    // Position is saved as unsigned,
    // but actually ranges from -1 and up (thus the -1)
    intptr_t value = ReadUInt() - 1;
    TokenPosition result = TokenPosition(value);
    max_position_ = Utils::Maximum(max_position_, result);
    if (min_position_.IsNoSource()) {
      min_position_ = result;
    } else if (result.IsReal()) {
      min_position_ = Utils::Minimum(min_position_, result);
    }

    return result;
  }

  intptr_t ReadListLength() { return ReadUInt(); }

  uint8_t ReadByte() { return buffer()[offset_++]; }

  uint8_t PeekByte() { return buffer()[offset_]; }

  bool ReadBool() { return (ReadByte() & 1) == 1; }

  uint8_t ReadFlags() { return ReadByte(); }

  static const char* TagName(Tag tag);

  Tag ReadTag(uint8_t* payload = NULL) {
    uint8_t byte = ReadByte();
    bool has_payload = (byte & kSpecializedTagHighBit) != 0;
    if (has_payload) {
      if (payload != NULL) {
        *payload = byte & kSpecializedPayloadMask;
      }
      return static_cast<Tag>(byte & kSpecializedTagMask);
    } else {
      return static_cast<Tag>(byte);
    }
  }

  Tag PeekTag(uint8_t* payload = NULL) {
    uint8_t byte = PeekByte();
    bool has_payload = (byte & kSpecializedTagHighBit) != 0;
    if (has_payload) {
      if (payload != NULL) {
        *payload = byte & kSpecializedPayloadMask;
      }
      return static_cast<Tag>(byte & kSpecializedTagMask);
    } else {
      return static_cast<Tag>(byte);
    }
  }

  void EnsureEnd() {
    if (offset_ != size_) {
      FATAL2(
          "Reading Kernel file: Expected to be at EOF "
          "(offset: %" Pd ", size: %" Pd ")",
          offset_, size_);
    }
  }

  // The largest position read yet (since last reset).
  // This is automatically updated when calling ReadPosition,
  // but can be overwritten (e.g. via the PositionScope class).
  TokenPosition max_position() { return max_position_; }
  // The smallest position read yet (since last reset).
  // This is automatically updated when calling ReadPosition,
  // but can be overwritten (e.g. via the PositionScope class).
  TokenPosition min_position() { return min_position_; }

  // A canonical name reference of -1 indicates none (for optional names), not
  // the root name as in the canonical name table.
  NameIndex ReadCanonicalNameReference() { return NameIndex(ReadUInt() - 1); }

  intptr_t offset() { return offset_; }
  void set_offset(intptr_t offset) { offset_ = offset; }

  intptr_t size() { return size_; }
  void set_size(intptr_t size) { size_ = size; }

  const TypedData* typed_data() { return typed_data_; }
  void set_typed_data(const TypedData* typed_data) { typed_data_ = typed_data; }

  const uint8_t* raw_buffer() { return raw_buffer_; }
  void set_raw_buffer(const uint8_t* raw_buffer) { raw_buffer_ = raw_buffer; }

  void CopyDataToVMHeap(const TypedData& typed_data,
                        intptr_t offset,
                        intptr_t size) {
    NoSafepointScope no_safepoint(thread_);
    memmove(typed_data.DataAddr(0), buffer() + offset, size);
  }

  uint8_t* CopyDataIntoZone(Zone* zone, intptr_t offset, intptr_t length) {
    uint8_t* buffer_ = zone->Alloc<uint8_t>(length);
    {
      NoSafepointScope no_safepoint(thread_);
      memmove(buffer_, buffer() + offset, length);
    }
    return buffer_;
  }

 private:
  const uint8_t* buffer() const {
    if (raw_buffer_ != NULL) {
      return raw_buffer_;
    }
    NoSafepointScope no_safepoint(thread_);
    return reinterpret_cast<uint8_t*>(typed_data_->DataAddr(0));
  }

  Thread* thread_;
  const uint8_t* raw_buffer_;
  const TypedData* typed_data_;
  intptr_t size_;
  intptr_t offset_;
  TokenPosition max_position_;
  TokenPosition min_position_;
  intptr_t current_script_id_;

  friend class PositionScope;
  friend class Program;
};

// A helper class that resets the readers min and max positions both upon
// initialization and upon destruction, i.e. when created the min an max
// positions will be reset to "noSource", when destructing the min and max will
// be reset to have they value they would have had, if they hadn't been reset in
// the first place.
class PositionScope {
 public:
  explicit PositionScope(Reader* reader)
      : reader_(reader),
        min_(reader->min_position_),
        max_(reader->max_position_) {
    reader->min_position_ = reader->max_position_ = TokenPosition::kNoSource;
  }

  ~PositionScope() {
    if (reader_->min_position_.IsNoSource()) {
      reader_->min_position_ = min_;
    } else if (min_.IsReal()) {
      reader_->min_position_ = Utils::Minimum(reader_->min_position_, min_);
    }
    reader_->max_position_ = Utils::Maximum(reader_->max_position_, max_);
  }

 private:
  Reader* reader_;
  TokenPosition min_;
  TokenPosition max_;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_BINARY_H_
