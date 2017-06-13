// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_BINARY_H_
#define RUNTIME_VM_KERNEL_BINARY_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include <map>

#include "vm/kernel.h"
#include "vm/kernel_to_il.h"
#include "vm/object.h"

namespace dart {
namespace kernel {


static const uint32_t kMagicProgramFile = 0x90ABCDEFu;


// Keep in sync with package:dynamo/lib/binary/tag.dart
enum Tag {
  kNothing = 0,
  kSomething = 1,

  kClass = 2,

  kFunctionNode = 3,
  kField = 4,
  kConstructor = 5,
  kProcedure = 6,

  kInvalidInitializer = 7,
  kFieldInitializer = 8,
  kSuperInitializer = 9,
  kRedirectingInitializer = 10,
  kLocalInitializer = 11,

  kDirectPropertyGet = 15,
  kDirectPropertySet = 16,
  kDirectMethodInvocation = 17,
  kConstStaticInvocation = 18,
  kInvalidExpression = 19,
  kVariableGet = 20,
  kVariableSet = 21,
  kPropertyGet = 22,
  kPropertySet = 23,
  kSuperPropertyGet = 24,
  kSuperPropertySet = 25,
  kStaticGet = 26,
  kStaticSet = 27,
  kMethodInvocation = 28,
  kSuperMethodInvocation = 29,
  kStaticInvocation = 30,
  kConstructorInvocation = 31,
  kConstConstructorInvocation = 32,
  kNot = 33,
  kLogicalExpression = 34,
  kConditionalExpression = 35,
  kStringConcatenation = 36,
  kIsExpression = 37,
  kAsExpression = 38,
  kStringLiteral = 39,
  kDoubleLiteral = 40,
  kTrueLiteral = 41,
  kFalseLiteral = 42,
  kNullLiteral = 43,
  kSymbolLiteral = 44,
  kTypeLiteral = 45,
  kThisExpression = 46,
  kRethrow = 47,
  kThrow = 48,
  kListLiteral = 49,
  kMapLiteral = 50,
  kAwaitExpression = 51,
  kFunctionExpression = 52,
  kLet = 53,

  kPositiveIntLiteral = 55,
  kNegativeIntLiteral = 56,
  kBigIntLiteral = 57,
  kConstListLiteral = 58,
  kConstMapLiteral = 59,

  kInvalidStatement = 60,
  kExpressionStatement = 61,
  kBlock = 62,
  kEmptyStatement = 63,
  kAssertStatement = 64,
  kLabeledStatement = 65,
  kBreakStatement = 66,
  kWhileStatement = 67,
  kDoStatement = 68,
  kForStatement = 69,
  kForInStatement = 70,
  kSwitchStatement = 71,
  kContinueSwitchStatement = 72,
  kIfStatement = 73,
  kReturnStatement = 74,
  kTryCatch = 75,
  kTryFinally = 76,
  kYieldStatement = 77,
  kVariableDeclaration = 78,
  kFunctionDeclaration = 79,
  kAsyncForInStatement = 80,

  kTypedefType = 87,
  kVectorType = 88,
  kBottomType = 89,
  kInvalidType = 90,
  kDynamicType = 91,
  kVoidType = 92,
  kInterfaceType = 93,
  kFunctionType = 94,
  kTypeParameterType = 95,
  kSimpleInterfaceType = 96,
  kSimpleFunctionType = 97,

  kVectorCreation = 102,
  kVectorGet = 103,
  kVectorSet = 104,
  kVectorCopy = 105,

  kClosureCreation = 106,

  kSpecializedTagHighBit = 0x80,  // 10000000
  kSpecializedTagMask = 0xF8,     // 11111000
  kSpecializedPayloadMask = 0x7,  // 00000111

  kSpecializedVariableGet = 128,
  kSpecializedVariableSet = 136,
  kSpecialIntLiteral = 144,
};


static const int SpecializedIntLiteralBias = 3;


template <typename T>
class BlockStack {
 public:
  BlockStack() : current_count_(0) {}

  void EnterScope() {
    variable_count_.Add(current_count_);
    current_count_ = 0;
  }

  void LeaveScope() {
    variables_.TruncateTo(variables_.length() - current_count_);
    current_count_ = variable_count_[variable_count_.length() - 1];
    variable_count_.RemoveLast();
  }

  T* Lookup(int index) {
    ASSERT(index < variables_.length());
    return variables_[index];
  }

  void Push(T* v) {
    variables_.Add(v);
    current_count_++;
  }

  void Push(List<T>* decl) {
    for (intptr_t i = 0; i < decl->length(); i++) {
      variables_.Add(decl[i]);
      current_count_++;
    }
  }

  void Pop(T* decl) {
    variables_.RemoveLast();
    current_count_--;
  }

  void Pop(List<T>* decl) {
    variables_.TruncateTo(variables_.length() - decl->length());
    current_count_ -= decl->length();
  }

 private:
  int current_count_;
  MallocGrowableArray<T*> variables_;
  MallocGrowableArray<int> variable_count_;
};


template <typename T>
class BlockMap {
 public:
  BlockMap() : current_count_(0), stack_height_(0) {}

  void EnterScope() {
    variable_count_.Add(current_count_);
    current_count_ = 0;
  }

  void LeaveScope() {
    stack_height_ -= current_count_;
    current_count_ = variable_count_[variable_count_.length() - 1];
    variable_count_.RemoveLast();
  }

  int Lookup(T* object) {
    typename MallocMap<T, int>::Pair* result = variables_.LookupPair(object);
    ASSERT(result != NULL);
    if (result == NULL) FATAL("lookup failure");
    return RawPointerKeyValueTrait<T, int>::ValueOf(*result);
  }

  void Push(T* v) {
    ASSERT(variables_.LookupPair(v) == NULL);
    int index = stack_height_++;
    variables_.Insert(v, index);
    current_count_++;
  }

  void Set(T* v, int index) {
    typename MallocMap<T, int>::Pair* entry = variables_.LookupPair(v);
    ASSERT(entry != NULL);
    entry->value = index;
  }

  void Push(List<T>* decl) {
    for (intptr_t i = 0; i < decl->length(); i++) {
      Push(decl[i]);
    }
  }

  void Pop(T* v) {
    current_count_--;
    stack_height_--;
  }

 private:
  int current_count_;
  int stack_height_;
  MallocMap<T, int> variables_;
  MallocGrowableArray<int> variable_count_;
};


template <typename T>
class VariableScope {
 public:
  explicit VariableScope(T* builder) : builder_(builder) {
    builder_->variables().EnterScope();
  }
  ~VariableScope() { builder_->variables().LeaveScope(); }

 private:
  T* builder_;
};


template <typename T>
class TypeParameterScope {
 public:
  explicit TypeParameterScope(T* builder) : builder_(builder) {
    builder_->type_parameters().EnterScope();
  }
  ~TypeParameterScope() { builder_->type_parameters().LeaveScope(); }

 private:
  T* builder_;
};


// Unlike other scopes, labels from enclosing functions are not visible in
// nested functions.  The LabelScope class is used to hide outer labels.
template <typename Builder, typename Block>
class LabelScope {
 public:
  explicit LabelScope(Builder* builder) : builder_(builder) {
    outer_block_ = builder_->labels();
    builder_->set_labels(&block_);
  }
  ~LabelScope() { builder_->set_labels(outer_block_); }

 private:
  Builder* builder_;
  Block block_;
  Block* outer_block_;
};


class ReaderHelper {
 public:
  ReaderHelper() : program_(NULL), labels_(NULL) {}

  Program* program() { return program_; }
  void set_program(Program* program) { program_ = program; }

  BlockStack<VariableDeclaration>& variables() { return scope_; }
  BlockStack<TypeParameter>& type_parameters() { return type_parameters_; }

  BlockStack<LabeledStatement>* labels() { return labels_; }
  void set_labels(BlockStack<LabeledStatement>* labels) { labels_ = labels; }

 private:
  Program* program_;
  BlockStack<VariableDeclaration> scope_;
  BlockStack<TypeParameter> type_parameters_;
  BlockStack<LabeledStatement>* labels_;
};


class Reader {
 public:
  Reader(const uint8_t* buffer, intptr_t size)
      : buffer_(buffer),
        size_(size),
        offset_(0),
        string_data_offset_(-1),
        string_offsets_(NULL),
        canonical_name_parents_(NULL),
        canonical_name_strings_(NULL) {}

  ~Reader();

  uint32_t ReadUInt32() {
    ASSERT(offset_ + 4 <= size_);

    uint32_t value = (buffer_[offset_ + 0] << 24) |
                     (buffer_[offset_ + 1] << 16) |
                     (buffer_[offset_ + 2] << 8) | (buffer_[offset_ + 3] << 0);
    offset_ += 4;
    return value;
  }

  uint32_t ReadUInt() {
    ASSERT(offset_ + 1 <= size_);
    uint8_t byte0 = buffer_[offset_];
    if ((byte0 & 0x80) == 0) {
      // 0...
      offset_++;
      return byte0;
    } else if ((byte0 & 0xc0) == 0x80) {
      // 10...
      ASSERT(offset_ + 2 <= size_);
      uint32_t value = ((byte0 & ~0x80) << 8) | (buffer_[offset_ + 1]);
      offset_ += 2;
      return value;
    } else {
      // 11...
      ASSERT(offset_ + 4 <= size_);
      uint32_t value = ((byte0 & ~0xc0) << 24) | (buffer_[offset_ + 1] << 16) |
                       (buffer_[offset_ + 2] << 8) |
                       (buffer_[offset_ + 3] << 0);
      offset_ += 4;
      return value;
    }
  }

  void add_token_position(
      MallocGrowableArray<MallocGrowableArray<intptr_t>*>* list,
      TokenPosition position) {
    intptr_t size = list->length();
    while (size <= current_script_id_) {
      MallocGrowableArray<intptr_t>* tmp = new MallocGrowableArray<intptr_t>();
      list->Add(tmp);
      size = list->length();
    }
    list->At(current_script_id_)->Add(position.value());
  }

  void record_token_position(TokenPosition position) {
    if (position.IsReal() && helper()->program() != NULL) {
      add_token_position(&helper()->program()->valid_token_positions, position);
    }
  }

  void record_yield_token_position(TokenPosition position) {
    if (helper()->program() != NULL) {
      add_token_position(&helper()->program()->yield_token_positions, position);
    }
  }

  /**
   * Read and return a TokenPosition from this reader.
   * @param record specifies whether or not the read position is saved as a
   * valid token position in the current script.
   * If not be sure to record it later by calling record_token_position (after
   * setting the correct current_script_id).
   */
  TokenPosition ReadPosition(bool record = true) {
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

    if (record) {
      record_token_position(result);
    }
    return result;
  }

  intptr_t ReadListLength() { return ReadUInt(); }

  uint8_t ReadByte() { return buffer_[offset_++]; }

  uint8_t PeekByte() { return buffer_[offset_]; }

  bool ReadBool() { return (ReadByte() & 1) == 1; }

  word ReadFlags() { return ReadByte(); }

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

  const uint8_t* Consume(int count) {
    ASSERT(offset_ + count <= size_);
    const uint8_t* old = buffer_ + offset_;
    offset_ += count;
    return old;
  }

  void EnsureEnd() {
    if (offset_ != size_) {
      FATAL2(
          "Reading Kernel file: Expected to be at EOF "
          "(offset: %" Pd ", size: %" Pd ")",
          offset_, size_);
    }
  }

  void DumpOffset(const char* str) {
    OS::PrintErr("@%" Pd " %s\n", offset_, str);
  }

  // The largest position read yet (since last reset).
  // This is automatically updated when calling ReadPosition,
  // but can be overwritten (e.g. via the PositionScope class).
  TokenPosition max_position() { return max_position_; }
  // The smallest position read yet (since last reset).
  // This is automatically updated when calling ReadPosition,
  // but can be overwritten (e.g. via the PositionScope class).
  TokenPosition min_position() { return min_position_; }
  // The current script id for what we are currently processing.
  // Note though that this is only a convenience helper and has to be set
  // manually.
  intptr_t current_script_id() { return current_script_id_; }
  void set_current_script_id(intptr_t script_id) {
    current_script_id_ = script_id;
  }

  template <typename T, typename RT>
  T* ReadOptional() {
    Tag tag = ReadTag();
    if (tag == kNothing) {
      return NULL;
    }
    ASSERT(tag == kSomething);
    return RT::ReadFrom(this);
  }

  template <typename T>
  T* ReadOptional() {
    return ReadOptional<T, T>();
  }

  ReaderHelper* helper() { return &builder_; }

  // A canonical name reference of -1 indicates none (for optional names), not
  // the root name as in the canonical name table.
  NameIndex ReadCanonicalNameReference() { return NameIndex(ReadUInt() - 1); }

  intptr_t offset() { return offset_; }
  void set_offset(intptr_t offset) { offset_ = offset; }
  intptr_t size() { return size_; }

  const uint8_t* buffer() { return buffer_; }

  intptr_t string_data_offset() { return string_data_offset_; }
  void MarkStringDataOffset() {
    ASSERT(string_data_offset_ == -1);
    string_data_offset_ = offset_;
  }

  intptr_t StringLength(StringIndex index) {
    return string_offsets_[index + 1] - string_offsets_[index];
  }

  uint8_t CharacterAt(StringIndex string_index, intptr_t index) {
    ASSERT(index < StringLength(string_index));
    return buffer_[string_data_offset_ + string_offsets_[string_index] + index];
  }

  // The canonical name index of a canonical name's parent (-1 indicates that
  // the parent is the root name).
  NameIndex CanonicalNameParent(NameIndex index) {
    return canonical_name_parents_[index];
  }

  // The string index of a canonical name's name string.
  StringIndex CanonicalNameString(NameIndex index) {
    return canonical_name_strings_[index];
  }

 private:
  const uint8_t* buffer_;
  intptr_t size_;
  intptr_t offset_;
  ReaderHelper builder_;
  TokenPosition max_position_;
  TokenPosition min_position_;
  intptr_t current_script_id_;

  // The offset of the start of the string data is recorded to allow access to
  // the strings during deserialization.
  intptr_t string_data_offset_;

  // The string offsets are decoded to support efficient access to string UTF-8
  // encodings.
  intptr_t* string_offsets_;

  // The canonical names are decoded.
  NameIndex* canonical_name_parents_;
  StringIndex* canonical_name_strings_;

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
