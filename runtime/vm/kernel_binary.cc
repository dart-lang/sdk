// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <map>
#include <vector>

#include "vm/flags.h"
#include "vm/kernel.h"
#include "vm/os.h"

#if defined(DEBUG)
#define TRACE_READ_OFFSET() do {               \
    if (FLAG_trace_kernel_binary)              \
      reader->DumpOffset(__PRETTY_FUNCTION__); \
  } while (0)
#define TRACE_WRITE_OFFSET() do {              \
    if (FLAG_trace_kernel_binary)              \
      writer->DumpOffset(__PRETTY_FUNCTION__); \
  } while (0)
#else
#define TRACE_READ_OFFSET()
#define TRACE_WRITE_OFFSET()
#endif

namespace dart {


ByteWriter::~ByteWriter() {}


namespace kernel {


static const uint32_t kMagicProgramFile = 0x90ABCDEFu;


// Keep in sync with package:dynamo/lib/binary/tag.dart
enum Tag {
  kNothing = 0,
  kSomething = 1,

  kNormalClass = 2,
  kMixinClass = 3,

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
  kBlockExpression = 54,

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

  kInvalidType = 90,
  kDynamicType = 91,
  kVoidType = 92,
  kInterfaceType = 93,
  kFunctionType = 94,
  kTypeParameterType = 95,
  kSimpleInterfaceType = 96,
  kSimpleFunctionType = 97,

  kNullReference = 99,
  kNormalClassReference = 100,
  kMixinClassReference = 101,

  kLibraryFieldReference = 102,
  kClassFieldReference = 103,
  kClassConstructorReference = 104,
  kLibraryProcedureReference = 105,
  kClassProcedureReference = 106,

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
    variable_count_.push_back(current_count_);
    current_count_ = 0;
  }

  void LeaveScope() {
    variables_.resize(variables_.size() - current_count_);
    current_count_ = variable_count_[variable_count_.size() - 1];
    variable_count_.pop_back();
  }

  T* Lookup(int index) {
    ASSERT(static_cast<unsigned>(index) < variables_.size());
    return variables_[index];
  }

  void Push(T* v) {
    variables_.push_back(v);
    current_count_++;
  }

  void Push(List<T>* decl) {
    for (int i = 0; i < decl->length(); i++) {
      variables_.push_back(decl[i]);
      current_count_++;
    }
  }

  void Pop(T* decl) {
    variables_.resize(variables_.size() - 1);
    current_count_--;
  }

  void Pop(List<T>* decl) {
    variables_.resize(variables_.size() - decl->length());
    current_count_ -= decl->length();
  }

 private:
  int current_count_;
  std::vector<T*> variables_;
  std::vector<int> variable_count_;
};


template <typename T>
class BlockMap {
 public:
  BlockMap() : current_count_(0), stack_height_(0) {}

  void EnterScope() {
    variable_count_.push_back(current_count_);
    current_count_ = 0;
  }

  void LeaveScope() {
    stack_height_ -= current_count_;
    current_count_ = variable_count_[variable_count_.size() - 1];
    variable_count_.pop_back();
  }

  int Lookup(T* object) {
    ASSERT(variables_.find(object) != variables_.end());
    if (variables_.find(object) == variables_.end()) FATAL("lookup failure");
    return variables_[object];
  }

  void Push(T* v) {
    int index = stack_height_++;
    variables_[v] = index;
    current_count_++;
  }

  void Set(T* v, int index) { variables_[v] = index; }

  void Push(List<T>* decl) {
    for (int i = 0; i < decl->length(); i++) {
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
  std::map<T*, int> variables_;
  std::vector<int> variable_count_;
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


template <typename T>
class SwitchCaseScope {
 public:
  explicit SwitchCaseScope(T* builder) : builder_(builder) {
    builder_->switch_cases().EnterScope();
  }
  ~SwitchCaseScope() { builder_->switch_cases().LeaveScope(); }

 private:
  T* builder_;
};


class ReaderHelper {
 public:
  ReaderHelper() : program_(NULL) {}
  ~ReaderHelper() {}

  Program* program() { return program_; }
  void set_program(Program* program) { program_ = program; }

  BlockStack<VariableDeclaration>& variables() { return scope_; }
  BlockStack<TypeParameter>& type_parameters() { return type_parameters_; }
  BlockStack<LabeledStatement>& lables() { return labels_; }
  BlockStack<SwitchCase>& switch_cases() { return switch_cases_; }

 private:
  Program* program_;
  BlockStack<VariableDeclaration> scope_;
  BlockStack<TypeParameter> type_parameters_;
  BlockStack<LabeledStatement> labels_;
  BlockStack<SwitchCase> switch_cases_;
};


class Reader {
 public:
  Reader(const uint8_t* buffer, int64_t size)
      : buffer_(buffer), size_(size), offset_(0) {}

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

  intptr_t ReadListLength() { return ReadUInt(); }

  uint8_t ReadByte() { return buffer_[offset_++]; }

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
          "(offset: %" Pd64 ", size: %" Pd64 ")",
          offset_, size_);
    }
  }

  void DumpOffset(const char* str) {
    OS::PrintErr("@%" Pd64 " %s\n", offset_, str);
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

 private:
  const uint8_t* buffer_;
  int64_t size_;
  int64_t offset_;
  ReaderHelper builder_;
};


class WriterHelper {
 public:
  void SetProgram(Program* program) {
    program_ = program;
    for (int i = 0; i < program->libraries().length(); i++) {
      Library* lib = program->libraries()[i];
      libraries_.Set(lib, i);

      for (int j = 0; j < lib->classes().length(); j++) {
        Class* klass = lib->classes()[j];
        classes_.Set(klass, j);

        for (int k = 0; k < klass->fields().length(); k++) {
          Field* field = klass->fields()[k];
          fields_.Set(field, k);
        }
        for (int k = 0; k < klass->constructors().length(); k++) {
          Constructor* constructor = klass->constructors()[k];
          constructors_.Set(constructor, k);
        }
        for (int k = 0; k < klass->procedures().length(); k++) {
          Procedure* procedure = klass->procedures()[k];
          procedures_.Set(procedure, k);
        }
      }

      for (int k = 0; k < lib->fields().length(); k++) {
        Field* field = lib->fields()[k];
        fields_.Set(field, k);
      }

      for (int k = 0; k < lib->procedures().length(); k++) {
        Procedure* procedure = lib->procedures()[k];
        procedures_.Set(procedure, k);
      }
    }
  }

  Program* program() { return program_; }

  BlockMap<String>& strings() { return strings_; }
  BlockMap<Library>& libraries() { return libraries_; }
  BlockMap<Class>& classes() { return classes_; }
  BlockMap<Field>& fields() { return fields_; }
  BlockMap<Procedure>& procedures() { return procedures_; }
  BlockMap<Constructor>& constructors() { return constructors_; }

  BlockMap<VariableDeclaration>& variables() { return scope_; }
  BlockMap<TypeParameter>& type_parameters() { return type_parameters_; }
  BlockMap<LabeledStatement>& lables() { return labels_; }
  BlockMap<SwitchCase>& switch_cases() { return switch_cases_; }

 private:
  Program* program_;

  BlockMap<String> strings_;
  BlockMap<Library> libraries_;
  BlockMap<Class> classes_;
  BlockMap<Field> fields_;
  BlockMap<Procedure> procedures_;
  BlockMap<Constructor> constructors_;

  BlockMap<VariableDeclaration> scope_;
  BlockMap<TypeParameter> type_parameters_;
  BlockMap<LabeledStatement> labels_;
  BlockMap<SwitchCase> switch_cases_;
};


class Writer {
 public:
  explicit Writer(ByteWriter* writer) : out_(writer), offset_(0) {}

  void WriteUInt32(uint32_t value) {
    uint8_t buffer[4] = {
        static_cast<uint8_t>((value >> 24) & 0xff),
        static_cast<uint8_t>((value >> 16) & 0xff),
        static_cast<uint8_t>((value >> 8) & 0xff),
        static_cast<uint8_t>((value >> 0) & 0xff),
    };
    WriteBytes(buffer, 4);
  }

  void WriteUInt(uint32_t value) {
    if (value < 0x80) {
      // 0...
      WriteByte(static_cast<uint8_t>(value));
    } else if (value < 0x4000) {
      // 10...
      WriteByte(static_cast<uint8_t>(((value >> 8) & 0x3f) | 0x80));
      WriteByte(static_cast<uint8_t>(value & 0xff));
    } else {
      // 11...
      // Ensure the highest 2 bits is not used for anything (we use it to for
      // encoding).
      ASSERT(static_cast<uint8_t>((value >> 24) & 0xc0) == 0);
      uint8_t buffer[4] = {
          static_cast<uint8_t>(((value >> 24) & 0x7f) | 0xc0),
          static_cast<uint8_t>((value >> 16) & 0xff),
          static_cast<uint8_t>((value >> 8) & 0xff),
          static_cast<uint8_t>((value >> 0) & 0xff),
      };
      WriteBytes(buffer, 4);
    }
  }

  void WriteListLength(intptr_t value) { return WriteUInt(value); }

  void WriteByte(uint8_t value) {
    out_->WriteByte(value);
    offset_++;
  }

  void WriteBool(bool value) { WriteByte(value ? 1 : 0); }

  void WriteFlags(uint8_t value) { WriteByte(value); }

  void WriteTag(Tag tag) { WriteByte(static_cast<uint8_t>(tag)); }

  void WriteTag(Tag tag, uint8_t payload) {
    ASSERT((payload & ~kSpecializedPayloadMask) == 0);
    WriteByte(kSpecializedTagHighBit | static_cast<uint8_t>(tag) | payload);
  }

  void WriteBytes(uint8_t* bytes, int length) {
    out_->WriteBytes(bytes, length);
    offset_ += length;
  }

  template <typename T>
  void WriteOptional(T* object) {
    if (object == NULL) {
      WriteTag(kNothing);
    } else {
      WriteTag(kSomething);
      object->WriteTo(this);
    }
  }

  template <typename T, typename WT>
  void WriteOptionalStatic(T* object) {
    if (object == NULL) {
      WriteTag(kNothing);
    } else {
      WriteTag(kSomething);
      WT::WriteTo(this, object);
    }
  }

  template <typename T>
  void WriteOptionalStatic(T* object) {
    return WriteOptionalStatic<T, T>(object);
  }

  void DumpOffset(const char* str) {
    OS::PrintErr("@%" Pd64 " %s\n", offset_, str);
  }

  WriterHelper* helper() { return &helper_; }

 private:
  ByteWriter* out_;
  WriterHelper helper_;
  int64_t offset_;
};


template <typename T>
template <typename IT>
void List<T>::ReadFrom(Reader* reader, TreeNode* parent) {
  TRACE_READ_OFFSET();
  ASSERT(parent != NULL);
  int length = reader->ReadListLength();
  EnsureInitialized(length);

  for (int i = 0; i < length_; i++) {
    IT* object = GetOrCreate<IT>(i, parent);
    object->ReadFrom(reader);
  }
}


template <typename T>
template <typename IT>
void List<T>::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  int length = reader->ReadListLength();
  EnsureInitialized(length);

  for (int i = 0; i < length_; i++) {
    GetOrCreate<IT>(i)->ReadFrom(reader);
  }
}


template <typename T>
template <typename IT>
void List<T>::ReadFromStatic(Reader* reader) {
  TRACE_READ_OFFSET();
  int length = reader->ReadListLength();
  EnsureInitialized(length);

  for (int i = 0; i < length_; i++) {
    ASSERT(array_[i] == NULL);
    array_[i] = IT::ReadFrom(reader);
  }
}


template <typename T>
void List<T>::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();

  // NOTE: We only support dense lists.
  writer->WriteListLength(length_);
  for (int i = 0; i < length_; i++) {
    T* object = array_[i];
    ASSERT(object != NULL);
    object->WriteTo(writer);
  }
}


template <typename T>
template <typename IT>
void List<T>::WriteToStatic(Writer* writer) {
  TRACE_WRITE_OFFSET();

  // NOTE: We only support dense lists.
  writer->WriteListLength(length_);
  for (int i = 0; i < length_; i++) {
    T* object = array_[i];
    ASSERT(object != NULL);
    IT::WriteTo(writer, object);
  }
}


void TypeParameterList::ReadFrom(Reader* reader) {
  // It is possible for the bound of the first type parameter to refer to
  // the second type parameter. This means we need to create [TypeParameter]
  // objects before reading the bounds.
  int length = reader->ReadListLength();
  EnsureInitialized(length);

  // Make all [TypeParameter]s available in scope.
  for (int i = 0; i < length; i++) {
    TypeParameter* parameter = (*this)[i] = new TypeParameter();
    reader->helper()->type_parameters().Push(parameter);
  }

  // Read all [TypeParameter]s and their bounds.
  for (int i = 0; i < length; i++) {
    (*this)[i]->ReadFrom(reader);
  }
}


void TypeParameterList::WriteTo(Writer* writer) {
  writer->WriteListLength(length());

  // Make all [TypeParameter]s available in scope.
  for (int i = 0; i < length(); i++) {
    TypeParameter* parameter = (*this)[i];
    writer->helper()->type_parameters().Push(parameter);
  }

  // Write all [TypeParameter]s and their bounds.
  for (int i = 0; i < length(); i++) {
    TypeParameter* parameter = (*this)[i];
    parameter->WriteTo(writer);
  }
}


template <typename A, typename B>
Tuple<A, B>* Tuple<A, B>::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  A* first = A::ReadFrom(reader);
  B* second = B::ReadFrom(reader);
  return new Tuple<A, B>(first, second);
}


template <typename A, typename B>
void Tuple<A, B>::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  first_->WriteTo(writer);
  second_->WriteTo(writer);
}


template <typename B, typename S>
class DowncastReader {
 public:
  static S* ReadFrom(Reader* reader) {
    TRACE_READ_OFFSET();
    return S::Cast(B::ReadFrom(reader));
  }
};


class StringImpl {
 public:
  static String* ReadFrom(Reader* reader) {
    TRACE_READ_OFFSET();
    return String::ReadFromImpl(reader);
  }

  static void WriteTo(Writer* writer, String* string) {
    TRACE_WRITE_OFFSET();
    string->WriteToImpl(writer);
  }
};


class VariableDeclarationImpl {
 public:
  static VariableDeclaration* ReadFrom(Reader* reader) {
    TRACE_READ_OFFSET();
    return VariableDeclaration::ReadFromImpl(reader);
  }

  static void WriteTo(Writer* writer, VariableDeclaration* d) {
    TRACE_WRITE_OFFSET();
    d->WriteToImpl(writer);
  }
};


String* String::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return Reference::ReadStringFrom(reader);
}


String* String::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  uint32_t bytes = reader->ReadUInt();
  String* string = new String(reader->Consume(bytes), bytes);
  return string;
}


void String::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  Reference::WriteStringTo(writer, this);
}


void String::WriteToImpl(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteUInt(size_);
  writer->WriteBytes(buffer_, size_);
}


void StringTable::ReadFrom(Reader* reader) {
  strings_.ReadFromStatic<StringImpl>(reader);
}


void StringTable::WriteTo(Writer* writer) {
  strings_.WriteToStatic<StringImpl>(writer);

  // Build up the "String* -> index" table.
  WriterHelper* helper = writer->helper();
  for (int i = 0; i < strings_.length(); i++) {
    helper->strings().Push(strings_[i]);
  }
}


void LineStartingTable::ReadFrom(Reader* reader, intptr_t length) {
  size_ = length;
  values_ = new intptr_t*[size_];
  for (intptr_t i = 0; i < size_; ++i) {
    intptr_t line_count = reader->ReadUInt();
    intptr_t* line_starts = new intptr_t[line_count + 1];
    line_starts[0] = line_count;
    intptr_t previous_line_start = 0;
    for (intptr_t j = 0; j < line_count; ++j) {
      intptr_t lineStart = reader->ReadUInt() + previous_line_start;
      line_starts[j + 1] = lineStart;
      previous_line_start = lineStart;
    }
    values_[i] = line_starts;
  }
}


void LineStartingTable::WriteTo(Writer* writer) {
  for (intptr_t i = 0; i < size_; ++i) {
    intptr_t* line_starts = values_[i];
    intptr_t line_count = line_starts[0];
    writer->WriteUInt(line_count);

    intptr_t previous_line_start = 0;
    for (intptr_t j = 0; j < line_count; ++j) {
      intptr_t line_start = line_starts[j + 1];
      writer->WriteUInt(line_start - previous_line_start);
      previous_line_start = line_start;
    }
  }
}


Library* Library::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  int flags = reader->ReadFlags();
  ASSERT(flags == 0);  // external libraries not supported
  name_ = Reference::ReadStringFrom(reader);
  import_uri_ = Reference::ReadStringFrom(reader);
  reader->ReadUInt();

  int num_classes = reader->ReadUInt();
  classes().EnsureInitialized(num_classes);
  for (int i = 0; i < num_classes; i++) {
    Tag tag = reader->ReadTag();
    if (tag == kNormalClass) {
      NormalClass* klass = classes().GetOrCreate<NormalClass>(i, this);
      klass->ReadFrom(reader);
    } else {
      ASSERT(tag == kMixinClass);
      MixinClass* klass = classes().GetOrCreate<MixinClass>(i, this);
      klass->ReadFrom(reader);
    }
  }

  fields().ReadFrom<Field>(reader, this);
  procedures().ReadFrom<Procedure>(reader, this);
  return this;
}


void Library::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  name_->WriteTo(writer);
  import_uri_->WriteTo(writer);
  writer->WriteUInt(0);

  writer->WriteUInt(classes_.length());
  for (int i = 0; i < classes_.length(); i++) {
    Class* klass = classes_[i];
    if (klass->IsNormalClass()) {
      writer->WriteTag(kNormalClass);
      NormalClass::Cast(klass)->WriteTo(writer);
    } else {
      writer->WriteTag(kMixinClass);
      MixinClass::Cast(klass)->WriteTo(writer);
    }
  }
  fields().WriteTo(writer);
  procedures().WriteTo(writer);
}


Class* Class::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();

  is_abstract_ = reader->ReadBool();
  name_ = Reference::ReadStringFrom(reader);
  reader->ReadUInt();
  annotations_.ReadFromStatic<Expression>(reader);

  return this;
}


void Class::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteBool(is_abstract_);
  name_->WriteTo(writer);
  writer->WriteUInt(0);
  annotations_.WriteTo(writer);
}


NormalClass* NormalClass::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Class::ReadFrom(reader);
  TypeParameterScope<ReaderHelper> scope(reader->helper());

  type_parameters_.ReadFrom(reader);
  DartType* type = reader->ReadOptional<DartType>();

  super_class_ = InterfaceType::Cast(type);
  implemented_classes_.ReadFromStatic<DowncastReader<DartType, InterfaceType> >(
      reader);
  fields_.ReadFrom<Field>(reader, this);
  constructors_.ReadFrom<Constructor>(reader, this);
  procedures_.ReadFrom<Procedure>(reader, this);

  return this;
}


void NormalClass::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  Class::WriteTo(writer);
  TypeParameterScope<WriterHelper> scope(writer->helper());

  type_parameters().WriteTo(writer);
  writer->WriteOptional<DartType>(super_class_);
  implemented_classes().WriteTo(writer);
  fields_.WriteTo(writer);
  constructors_.WriteTo(writer);
  procedures_.WriteTo(writer);
}


MixinClass* MixinClass::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TypeParameterScope<ReaderHelper> scope(reader->helper());

  Class::ReadFrom(reader);
  type_parameters_.ReadFrom(reader);
  first_ = InterfaceType::Cast(DartType::ReadFrom(reader));
  second_ = InterfaceType::Cast(DartType::ReadFrom(reader));
  implemented_classes_.ReadFromStatic<DowncastReader<DartType, InterfaceType> >(
      reader);
  constructors_.ReadFrom<Constructor>(reader, this);
  return this;
}


void MixinClass::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  TypeParameterScope<WriterHelper> scope(writer->helper());

  Class::WriteTo(writer);
  type_parameters_.WriteTo(writer);
  first_->WriteTo(writer);
  second_->WriteTo(writer);
  implemented_classes_.WriteTo(writer);
  constructors_.WriteTo(writer);
}


Member* Reference::ReadMemberFrom(Reader* reader, bool allow_null) {
  TRACE_READ_OFFSET();

  Program* program = reader->helper()->program();
  Tag tag = reader->ReadTag();
  switch (tag) {
    case kLibraryFieldReference: {
      int library_idx = reader->ReadUInt();
      int field_idx = reader->ReadUInt();
      Library* library = program->libraries().GetOrCreate<Library>(library_idx);
      return library->fields().GetOrCreate<Field>(field_idx, library);
    }
    case kLibraryProcedureReference: {
      int library_idx = reader->ReadUInt();
      int procedure_idx = reader->ReadUInt();
      Library* library = program->libraries().GetOrCreate<Library>(library_idx);
      return library->procedures().GetOrCreate<Procedure>(procedure_idx,
                                                          library);
    }
    case kClassFieldReference:
    case kClassConstructorReference:
    case kClassProcedureReference: {
      Class* klass = Reference::ReadClassFrom(reader);
      if (tag == kClassFieldReference) {
        int field_idx = reader->ReadUInt();
        return klass->fields().GetOrCreate<Field>(field_idx, klass);
      } else if (tag == kClassConstructorReference) {
        int constructor_idx = reader->ReadUInt();
        return klass->constructors().GetOrCreate<Constructor>(constructor_idx,
                                                              klass);
      } else {
        ASSERT(tag == kClassProcedureReference);
        int procedure_idx = reader->ReadUInt();
        return klass->procedures().GetOrCreate<Procedure>(procedure_idx, klass);
      }
    }
    case kNullReference:
      if (allow_null) {
        return NULL;
      } else {
        FATAL("Expected a valid member reference, but got `null`");
      }
    default:
      UNREACHABLE();
      break;
  }

  UNREACHABLE();
  return NULL;
}


void Reference::WriteMemberTo(Writer* writer, Member* member, bool allow_null) {
  TRACE_WRITE_OFFSET();
  if (member == NULL) {
    if (allow_null) {
      writer->WriteTag(kNullReference);
      return;
    } else {
      FATAL("Expected a valid member reference but got `null`");
    }
  }
  TreeNode* node = member->parent();

  WriterHelper* helper = writer->helper();

  if (node->IsLibrary()) {
    Library* library = Library::Cast(node);
    if (member->IsField()) {
      Field* field = Field::Cast(member);
      writer->WriteTag(kLibraryFieldReference);
      writer->WriteUInt(helper->libraries().Lookup(library));
      writer->WriteUInt(helper->fields().Lookup(field));
    } else {
      Procedure* procedure = Procedure::Cast(member);
      writer->WriteTag(kLibraryProcedureReference);
      writer->WriteUInt(helper->libraries().Lookup(library));
      writer->WriteUInt(helper->procedures().Lookup(procedure));
    }
  } else {
    Class* klass = Class::Cast(node);

    if (member->IsField()) {
      Field* field = Field::Cast(member);
      writer->WriteTag(kClassFieldReference);
      Reference::WriteClassTo(writer, klass);
      writer->WriteUInt(helper->fields().Lookup(field));
    } else if (member->IsConstructor()) {
      Constructor* constructor = Constructor::Cast(member);
      writer->WriteTag(kClassConstructorReference);
      Reference::WriteClassTo(writer, klass);
      writer->WriteUInt(helper->constructors().Lookup(constructor));
    } else {
      Procedure* procedure = Procedure::Cast(member);
      writer->WriteTag(kClassProcedureReference);
      Reference::WriteClassTo(writer, klass);
      writer->WriteUInt(helper->procedures().Lookup(procedure));
    }
  }
}


Class* Reference::ReadClassFrom(Reader* reader, bool allow_null) {
  TRACE_READ_OFFSET();
  Program* program = reader->helper()->program();

  Tag klass_member_tag = reader->ReadTag();
  if (klass_member_tag == kNullReference) {
    if (allow_null) {
      return NULL;
    } else {
      FATAL("Expected a valid class reference but got `null`.");
    }
  }
  int library_idx = reader->ReadUInt();
  int class_idx = reader->ReadUInt();

  Library* library = program->libraries().GetOrCreate<Library>(library_idx);
  Class* klass;
  if (klass_member_tag == kNormalClassReference) {
    klass = library->classes().GetOrCreate<NormalClass>(class_idx, library);
  } else {
    ASSERT(klass_member_tag == kMixinClassReference);
    klass = library->classes().GetOrCreate<MixinClass>(class_idx, library);
  }
  return klass;
}


void Reference::WriteClassTo(Writer* writer, Class* klass, bool allow_null) {
  TRACE_WRITE_OFFSET();
  if (klass == NULL) {
    if (allow_null) {
      writer->WriteTag(kNullReference);
      return;
    } else {
      FATAL("Expected a valid class reference but got `null`.");
    }
  }
  if (klass->IsNormalClass()) {
    writer->WriteTag(kNormalClassReference);
  } else {
    ASSERT(klass->IsMixinClass());
    writer->WriteTag(kMixinClassReference);
  }

  writer->WriteUInt(writer->helper()->libraries().Lookup(klass->parent()));
  writer->WriteUInt(writer->helper()->classes().Lookup(klass));
}


String* Reference::ReadStringFrom(Reader* reader) {
  int index = reader->ReadUInt();
  return reader->helper()->program()->string_table().strings()[index];
}


void Reference::WriteStringTo(Writer* writer, String* string) {
  int index = writer->helper()->strings().Lookup(string);
  writer->WriteUInt(index);
}


Field* Field::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  ASSERT(tag == kField);

  reader->ReadUInt();
  flags_ = reader->ReadFlags();
  name_ = Name::ReadFrom(reader);
  reader->ReadUInt();
  annotations_.ReadFromStatic<Expression>(reader);
  type_ = DartType::ReadFrom(reader);
  inferred_value_ = reader->ReadOptional<InferredValue>();
  initializer_ = reader->ReadOptional<Expression>();
  return this;
}


void Field::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kField);
  writer->WriteUInt(0);
  writer->WriteFlags(flags_);
  name_->WriteTo(writer);
  writer->WriteUInt(0);
  annotations_.WriteTo(writer);
  type_->WriteTo(writer);
  writer->WriteOptional<InferredValue>(inferred_value_);
  writer->WriteOptional<Expression>(initializer_);
}


Constructor* Constructor::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  ASSERT(tag == kConstructor);

  VariableScope<ReaderHelper> parameters(reader->helper());
  flags_ = reader->ReadFlags();
  name_ = Name::ReadFrom(reader);
  annotations_.ReadFromStatic<Expression>(reader);
  function_ = FunctionNode::ReadFrom(reader);
  initializers_.ReadFromStatic<Initializer>(reader);
  return this;
}


void Constructor::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kConstructor);

  VariableScope<WriterHelper> parameters(writer->helper());
  writer->WriteFlags(flags_);
  name_->WriteTo(writer);
  annotations_.WriteTo(writer);
  function_->WriteTo(writer);
  initializers_.WriteTo(writer);
}


Procedure* Procedure::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  ASSERT(tag == kProcedure);

  VariableScope<ReaderHelper> parameters(reader->helper());
  kind_ = static_cast<ProcedureKind>(reader->ReadByte());
  flags_ = reader->ReadFlags();
  name_ = Name::ReadFrom(reader);
  reader->ReadUInt();
  annotations_.ReadFromStatic<Expression>(reader);
  function_ = reader->ReadOptional<FunctionNode>();
  return this;
}


void Procedure::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kProcedure);

  VariableScope<WriterHelper> parameters(writer->helper());
  writer->WriteByte(kind_);
  writer->WriteFlags(flags_);
  name_->WriteTo(writer);
  writer->WriteUInt(0);
  annotations_.WriteTo(writer);
  writer->WriteOptional<FunctionNode>(function_);
}


Initializer* Initializer::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  switch (tag) {
    case kInvalidInitializer:
      return InvalidInitializer::ReadFromImpl(reader);
    case kFieldInitializer:
      return FieldInitializer::ReadFromImpl(reader);
    case kSuperInitializer:
      return SuperInitializer::ReadFromImpl(reader);
    case kRedirectingInitializer:
      return RedirectingInitializer::ReadFromImpl(reader);
    case kLocalInitializer:
      return LocalInitializer::ReadFromImpl(reader);
    default:
      UNREACHABLE();
  }
  return NULL;
}


InvalidInitializer* InvalidInitializer::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  return new InvalidInitializer();
}


void InvalidInitializer::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kInvalidInitializer);
}


FieldInitializer* FieldInitializer::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  FieldInitializer* initializer = new FieldInitializer();
  initializer->field_ = Field::Cast(Reference::ReadMemberFrom(reader));
  initializer->value_ = Expression::ReadFrom(reader);
  return initializer;
}


void FieldInitializer::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kFieldInitializer);
  Reference::WriteMemberTo(writer, field_);
  value_->WriteTo(writer);
}


SuperInitializer* SuperInitializer::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  SuperInitializer* init = new SuperInitializer();
  init->target_ = Constructor::Cast(Reference::ReadMemberFrom(reader));
  init->arguments_ = Arguments::ReadFrom(reader);
  return init;
}


void SuperInitializer::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kSuperInitializer);
  Reference::WriteMemberTo(writer, target_);
  arguments_->WriteTo(writer);
}


RedirectingInitializer* RedirectingInitializer::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  RedirectingInitializer* init = new RedirectingInitializer();
  init->target_ = Constructor::Cast(Reference::ReadMemberFrom(reader));
  init->arguments_ = Arguments::ReadFrom(reader);
  return init;
}


void RedirectingInitializer::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kRedirectingInitializer);
  Reference::WriteMemberTo(writer, target_);
  arguments_->WriteTo(writer);
}


LocalInitializer* LocalInitializer::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  LocalInitializer* init = new LocalInitializer();
  init->variable_ = VariableDeclaration::ReadFromImpl(reader);
  return init;
}


void LocalInitializer::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kLocalInitializer);
  variable_->WriteToImpl(writer);
}


Expression* Expression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  uint8_t payload = 0;
  Tag tag = reader->ReadTag(&payload);
  switch (tag) {
    case kInvalidExpression:
      return InvalidExpression::ReadFrom(reader);
    case kVariableGet:
      return VariableGet::ReadFrom(reader);
    case kSpecializedVariableGet:
      return VariableGet::ReadFrom(reader, payload);
    case kVariableSet:
      return VariableSet::ReadFrom(reader);
    case kSpecializedVariableSet:
      return VariableSet::ReadFrom(reader, payload);
    case kPropertyGet:
      return PropertyGet::ReadFrom(reader);
    case kPropertySet:
      return PropertySet::ReadFrom(reader);
    case kDirectPropertyGet:
      return DirectPropertyGet::ReadFrom(reader);
    case kDirectPropertySet:
      return DirectPropertySet::ReadFrom(reader);
    case kStaticGet:
      return StaticGet::ReadFrom(reader);
    case kStaticSet:
      return StaticSet::ReadFrom(reader);
    case kMethodInvocation:
      return MethodInvocation::ReadFrom(reader);
    case kDirectMethodInvocation:
      return DirectMethodInvocation::ReadFrom(reader);
    case kStaticInvocation:
      return StaticInvocation::ReadFrom(reader, false);
    case kConstStaticInvocation:
      return StaticInvocation::ReadFrom(reader, true);
    case kConstructorInvocation:
      return ConstructorInvocation::ReadFrom(reader, false);
    case kConstConstructorInvocation:
      return ConstructorInvocation::ReadFrom(reader, true);
    case kNot:
      return Not::ReadFrom(reader);
    case kLogicalExpression:
      return LogicalExpression::ReadFrom(reader);
    case kConditionalExpression:
      return ConditionalExpression::ReadFrom(reader);
    case kStringConcatenation:
      return StringConcatenation::ReadFrom(reader);
    case kIsExpression:
      return IsExpression::ReadFrom(reader);
    case kAsExpression:
      return AsExpression::ReadFrom(reader);
    case kSymbolLiteral:
      return SymbolLiteral::ReadFrom(reader);
    case kTypeLiteral:
      return TypeLiteral::ReadFrom(reader);
    case kThisExpression:
      return ThisExpression::ReadFrom(reader);
    case kRethrow:
      return Rethrow::ReadFrom(reader);
    case kThrow:
      return Throw::ReadFrom(reader);
    case kListLiteral:
      return ListLiteral::ReadFrom(reader, false);
    case kConstListLiteral:
      return ListLiteral::ReadFrom(reader, true);
    case kMapLiteral:
      return MapLiteral::ReadFrom(reader, false);
    case kConstMapLiteral:
      return MapLiteral::ReadFrom(reader, true);
    case kAwaitExpression:
      return AwaitExpression::ReadFrom(reader);
    case kFunctionExpression:
      return FunctionExpression::ReadFrom(reader);
    case kLet:
      return Let::ReadFrom(reader);
    case kBlockExpression:
      return BlockExpression::ReadFrom(reader);
    case kBigIntLiteral:
      return BigintLiteral::ReadFrom(reader);
    case kStringLiteral:
      return StringLiteral::ReadFrom(reader);
    case kSpecialIntLiteral:
      return IntLiteral::ReadFrom(reader, payload);
    case kNegativeIntLiteral:
      return IntLiteral::ReadFrom(reader, true);
    case kPositiveIntLiteral:
      return IntLiteral::ReadFrom(reader, false);
    case kDoubleLiteral:
      return DoubleLiteral::ReadFrom(reader);
    case kTrueLiteral:
      return BoolLiteral::ReadFrom(reader, true);
    case kFalseLiteral:
      return BoolLiteral::ReadFrom(reader, false);
    case kNullLiteral:
      return NullLiteral::ReadFrom(reader);
    default:
      UNREACHABLE();
  }
  return NULL;
}


InvalidExpression* InvalidExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new InvalidExpression();
}


void InvalidExpression::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kInvalidExpression);
}


VariableGet* VariableGet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableGet* get = new VariableGet();
  get->variable_ = reader->helper()->variables().Lookup(reader->ReadUInt());
  reader->ReadOptional<DartType>();  // Unused promoted type.
  return get;
}


VariableGet* VariableGet::ReadFrom(Reader* reader, uint8_t payload) {
  TRACE_READ_OFFSET();
  VariableGet* get = new VariableGet();
  get->variable_ = reader->helper()->variables().Lookup(payload);
  return get;
}


void VariableGet::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  int index = writer->helper()->variables().Lookup(variable_);
  if ((index & kSpecializedPayloadMask) == index) {
    writer->WriteTag(kSpecializedVariableGet, static_cast<uint8_t>(index));
  } else {
    writer->WriteTag(kVariableGet);
    writer->WriteUInt(index);
    writer->WriteOptional<DartType>(NULL);
  }
}


VariableSet* VariableSet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableSet* set = new VariableSet();
  set->variable_ = reader->helper()->variables().Lookup(reader->ReadUInt());
  set->expression_ = Expression::ReadFrom(reader);
  return set;
}


VariableSet* VariableSet::ReadFrom(Reader* reader, uint8_t payload) {
  TRACE_READ_OFFSET();
  VariableSet* set = new VariableSet();
  set->variable_ = reader->helper()->variables().Lookup(payload);
  set->expression_ = Expression::ReadFrom(reader);
  return set;
}


void VariableSet::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  int index = writer->helper()->variables().Lookup(variable_);
  if ((index & kSpecializedPayloadMask) == index) {
    writer->WriteTag(kSpecializedVariableSet, static_cast<uint8_t>(index));
  } else {
    writer->WriteTag(kVariableSet);
    writer->WriteUInt(index);
  }
  expression_->WriteTo(writer);
}


PropertyGet* PropertyGet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  PropertyGet* get = new PropertyGet();
  reader->ReadUInt();
  get->receiver_ = Expression::ReadFrom(reader);
  get->name_ = Name::ReadFrom(reader);
  get->interfaceTarget_ = Reference::ReadMemberFrom(reader, true);
  return get;
}


void PropertyGet::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kPropertyGet);
  writer->WriteUInt(0);
  receiver_->WriteTo(writer);
  name_->WriteTo(writer);
  Reference::WriteMemberTo(writer, interfaceTarget_, true);
}


PropertySet* PropertySet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  PropertySet* set = new PropertySet();
  reader->ReadUInt();
  set->receiver_ = Expression::ReadFrom(reader);
  set->name_ = Name::ReadFrom(reader);
  set->value_ = Expression::ReadFrom(reader);
  set->interfaceTarget_ = Reference::ReadMemberFrom(reader, true);
  return set;
}


void PropertySet::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kPropertySet);
  writer->WriteUInt(0);
  receiver_->WriteTo(writer);
  name_->WriteTo(writer);
  value_->WriteTo(writer);
  Reference::WriteMemberTo(writer, interfaceTarget_, true);
}


DirectPropertyGet* DirectPropertyGet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  DirectPropertyGet* get = new DirectPropertyGet();
  get->receiver_ = Expression::ReadFrom(reader);
  get->target_ = Reference::ReadMemberFrom(reader);
  return get;
}


void DirectPropertyGet::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kDirectPropertyGet);
  receiver_->WriteTo(writer);
  Reference::WriteMemberTo(writer, target_);
}


DirectPropertySet* DirectPropertySet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  DirectPropertySet* set = new DirectPropertySet();
  set->receiver_ = Expression::ReadFrom(reader);
  set->target_ = Reference::ReadMemberFrom(reader);
  set->value_ = Expression::ReadFrom(reader);
  return set;
}


void DirectPropertySet::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kDirectPropertySet);
  receiver_->WriteTo(writer);
  Reference::WriteMemberTo(writer, target_);
  value_->WriteTo(writer);
}


StaticGet* StaticGet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  StaticGet* get = new StaticGet();
  reader->ReadUInt();
  get->target_ = Reference::ReadMemberFrom(reader);
  return get;
}


void StaticGet::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kStaticGet);
  writer->WriteUInt(0);
  Reference::WriteMemberTo(writer, target_);
}


StaticSet* StaticSet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  StaticSet* set = new StaticSet();
  set->target_ = Reference::ReadMemberFrom(reader);
  set->expression_ = Expression::ReadFrom(reader);
  return set;
}


void StaticSet::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kStaticSet);
  Reference::WriteMemberTo(writer, target_);
  expression_->WriteTo(writer);
}


Arguments* Arguments::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Arguments* arguments = new Arguments();
  arguments->types().ReadFromStatic<DartType>(reader);
  arguments->positional().ReadFromStatic<Expression>(reader);
  arguments->named().ReadFromStatic<NamedExpression>(reader);
  return arguments;
}


void Arguments::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  types().WriteTo(writer);
  positional().WriteTo(writer);
  named().WriteTo(writer);
}


NamedExpression* NamedExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  String* name = Reference::ReadStringFrom(reader);
  Expression* expression = Expression::ReadFrom(reader);
  return new NamedExpression(name, expression);
}


void NamedExpression::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  name_->WriteTo(writer);
  expression_->WriteTo(writer);
}


MethodInvocation* MethodInvocation::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  MethodInvocation* invocation = new MethodInvocation();
  reader->ReadUInt();
  invocation->receiver_ = Expression::ReadFrom(reader);
  invocation->name_ = Name::ReadFrom(reader);
  invocation->arguments_ = Arguments::ReadFrom(reader);
  invocation->interfaceTarget_ = Reference::ReadMemberFrom(reader, true);
  return invocation;
}


void MethodInvocation::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kMethodInvocation);
  writer->WriteUInt(0);
  receiver_->WriteTo(writer);
  name_->WriteTo(writer);
  arguments_->WriteTo(writer);
  Reference::WriteMemberTo(writer, interfaceTarget_, true);
}


DirectMethodInvocation* DirectMethodInvocation::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  DirectMethodInvocation* invocation = new DirectMethodInvocation();
  invocation->receiver_ = Expression::ReadFrom(reader);
  invocation->target_ = Procedure::Cast(Reference::ReadMemberFrom(reader));
  invocation->arguments_ = Arguments::ReadFrom(reader);
  return invocation;
}


void DirectMethodInvocation::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kDirectMethodInvocation);
  receiver_->WriteTo(writer);
  Reference::WriteMemberTo(writer, target_);
  arguments_->WriteTo(writer);
}


StaticInvocation* StaticInvocation::ReadFrom(Reader* reader, bool is_const) {
  TRACE_READ_OFFSET();

  reader->ReadUInt();
  Member* member = Reference::ReadMemberFrom(reader);
  Arguments* args = Arguments::ReadFrom(reader);

  return new StaticInvocation(Procedure::Cast(member), args, is_const);
}


void StaticInvocation::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(is_const_ ? kConstStaticInvocation : kStaticInvocation);
  writer->WriteUInt(0);
  Reference::WriteMemberTo(writer, procedure_);
  arguments_->WriteTo(writer);
}


ConstructorInvocation* ConstructorInvocation::ReadFrom(Reader* reader,
                                                       bool is_const) {
  TRACE_READ_OFFSET();
  ConstructorInvocation* invocation = new ConstructorInvocation();
  invocation->is_const_ = is_const;
  reader->ReadUInt();
  invocation->target_ = Constructor::Cast(Reference::ReadMemberFrom(reader));
  invocation->arguments_ = Arguments::ReadFrom(reader);
  return invocation;
}


void ConstructorInvocation::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(is_const_ ? kConstConstructorInvocation
                             : kConstructorInvocation);
  writer->WriteUInt(0);
  Reference::WriteMemberTo(writer, target_);
  arguments_->WriteTo(writer);
}


Not* Not::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Not* n = new Not();
  n->expression_ = Expression::ReadFrom(reader);
  return n;
}


void Not::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kNot);
  expression_->WriteTo(writer);
}


LogicalExpression* LogicalExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  LogicalExpression* expr = new LogicalExpression();
  expr->left_ = Expression::ReadFrom(reader);
  expr->operator_ = static_cast<Operator>(reader->ReadByte());
  expr->right_ = Expression::ReadFrom(reader);
  return expr;
}


void LogicalExpression::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kLogicalExpression);
  left_->WriteTo(writer);
  writer->WriteByte(operator_);
  right_->WriteTo(writer);
}


ConditionalExpression* ConditionalExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  ConditionalExpression* expr = new ConditionalExpression();
  expr->condition_ = Expression::ReadFrom(reader);
  expr->then_ = Expression::ReadFrom(reader);
  expr->otherwise_ = Expression::ReadFrom(reader);
  reader->ReadOptional<DartType>();  // Unused static type.
  return expr;
}


void ConditionalExpression::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kConditionalExpression);
  condition_->WriteTo(writer);
  then_->WriteTo(writer);
  otherwise_->WriteTo(writer);
  writer->WriteOptional<DartType>(NULL);  // Unused static type.
}


StringConcatenation* StringConcatenation::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  StringConcatenation* concat = new StringConcatenation();
  concat->expressions_.ReadFromStatic<Expression>(reader);
  return concat;
}


void StringConcatenation::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kStringConcatenation);
  expressions_.WriteTo(writer);
}


IsExpression* IsExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  IsExpression* expr = new IsExpression();
  expr->operand_ = Expression::ReadFrom(reader);
  expr->type_ = DartType::ReadFrom(reader);
  return expr;
}


void IsExpression::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kIsExpression);
  operand_->WriteTo(writer);
  type_->WriteTo(writer);
}


AsExpression* AsExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  AsExpression* expr = new AsExpression();
  expr->operand_ = Expression::ReadFrom(reader);
  expr->type_ = DartType::ReadFrom(reader);
  return expr;
}


void AsExpression::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kAsExpression);
  operand_->WriteTo(writer);
  type_->WriteTo(writer);
}


StringLiteral* StringLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new StringLiteral(Reference::ReadStringFrom(reader));
}


void StringLiteral::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kStringLiteral);
  value_->WriteTo(writer);
}


BigintLiteral* BigintLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new BigintLiteral(Reference::ReadStringFrom(reader));
}


void BigintLiteral::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kBigIntLiteral);
  value_->WriteTo(writer);
}


IntLiteral* IntLiteral::ReadFrom(Reader* reader, bool is_negative) {
  TRACE_READ_OFFSET();
  IntLiteral* literal = new IntLiteral();
  literal->value_ = is_negative ? -static_cast<int64_t>(reader->ReadUInt())
                                : reader->ReadUInt();
  return literal;
}


IntLiteral* IntLiteral::ReadFrom(Reader* reader, uint8_t payload) {
  TRACE_READ_OFFSET();
  IntLiteral* literal = new IntLiteral();
  literal->value_ = static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
  return literal;
}


void IntLiteral::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  int64_t payload = value_ + SpecializedIntLiteralBias;
  if ((payload & kSpecializedPayloadMask) == payload) {
    writer->WriteTag(kSpecialIntLiteral, static_cast<uint8_t>(payload));
  } else {
    writer->WriteTag(value_ < 0 ? kNegativeIntLiteral : kPositiveIntLiteral);
    writer->WriteUInt(static_cast<uint32_t>(value_ < 0 ? -value_ : value_));
  }
}


DoubleLiteral* DoubleLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  DoubleLiteral* literal = new DoubleLiteral();
  literal->value_ = Reference::ReadStringFrom(reader);
  return literal;
}


void DoubleLiteral::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kDoubleLiteral);
  value_->WriteTo(writer);
}


BoolLiteral* BoolLiteral::ReadFrom(Reader* reader, bool value) {
  TRACE_READ_OFFSET();
  BoolLiteral* lit = new BoolLiteral();
  lit->value_ = value;
  return lit;
}


void BoolLiteral::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(value_ ? kTrueLiteral : kFalseLiteral);
}


NullLiteral* NullLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new NullLiteral();
}


void NullLiteral::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kNullLiteral);
}


SymbolLiteral* SymbolLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  SymbolLiteral* lit = new SymbolLiteral();
  lit->value_ = Reference::ReadStringFrom(reader);
  return lit;
}


void SymbolLiteral::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kSymbolLiteral);
  value_->WriteTo(writer);
}


TypeLiteral* TypeLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TypeLiteral* literal = new TypeLiteral();
  literal->type_ = DartType::ReadFrom(reader);
  return literal;
}


void TypeLiteral::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kTypeLiteral);
  type_->WriteTo(writer);
}


ThisExpression* ThisExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new ThisExpression();
}


void ThisExpression::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kThisExpression);
}


Rethrow* Rethrow::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new Rethrow();
}


void Rethrow::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kRethrow);
}


Throw* Throw::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Throw* t = new Throw();
  reader->ReadUInt();
  t->expression_ = Expression::ReadFrom(reader);
  return t;
}


void Throw::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kThrow);
  writer->WriteUInt(0);
  expression_->WriteTo(writer);
}


ListLiteral* ListLiteral::ReadFrom(Reader* reader, bool is_const) {
  TRACE_READ_OFFSET();
  ListLiteral* literal = new ListLiteral();
  literal->is_const_ = is_const;
  literal->type_ = DartType::ReadFrom(reader);
  literal->expressions_.ReadFromStatic<Expression>(reader);
  return literal;
}


void ListLiteral::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(is_const_ ? kConstListLiteral : kListLiteral);
  type_->WriteTo(writer);
  expressions_.WriteTo(writer);
}


MapLiteral* MapLiteral::ReadFrom(Reader* reader, bool is_const) {
  TRACE_READ_OFFSET();
  MapLiteral* literal = new MapLiteral();
  literal->is_const_ = is_const;
  literal->key_type_ = DartType::ReadFrom(reader);
  literal->value_type_ = DartType::ReadFrom(reader);
  literal->entries_.ReadFromStatic<MapEntry>(reader);
  return literal;
}


void MapLiteral::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(is_const_ ? kConstMapLiteral : kMapLiteral);
  key_type_->WriteTo(writer);
  value_type_->WriteTo(writer);
  entries_.WriteTo(writer);
}


MapEntry* MapEntry::ReadFrom(Reader* reader) {
  MapEntry* entry = new MapEntry();
  entry->key_ = Expression::ReadFrom(reader);
  entry->value_ = Expression::ReadFrom(reader);
  return entry;
}


void MapEntry::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  key_->WriteTo(writer);
  value_->WriteTo(writer);
}


AwaitExpression* AwaitExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  AwaitExpression* await = new AwaitExpression();
  await->operand_ = Expression::ReadFrom(reader);
  return await;
}


void AwaitExpression::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kAwaitExpression);
  operand_->WriteTo(writer);
}


FunctionExpression* FunctionExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> parameters(reader->helper());
  FunctionExpression* expr = new FunctionExpression();
  expr->function_ = FunctionNode::ReadFrom(reader);
  return expr;
}


void FunctionExpression::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  VariableScope<WriterHelper> parameters(writer->helper());
  writer->WriteTag(kFunctionExpression);
  function_->WriteTo(writer);
}


Let* Let::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> vars(reader->helper());
  Let* let = new Let();
  let->variable_ = VariableDeclaration::ReadFromImpl(reader);
  let->body_ = Expression::ReadFrom(reader);
  return let;
}


void Let::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  VariableScope<WriterHelper> vars(writer->helper());
  writer->WriteTag(kLet);
  variable_->WriteToImpl(writer);
  body_->WriteTo(writer);
}


BlockExpression* BlockExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  BlockExpression* be = new BlockExpression();
  be->body_ = Block::ReadFromImpl(reader);
  be->value_ = Expression::ReadFrom(reader);
  return be;
}


void BlockExpression::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kBlockExpression);
  body_->WriteToImpl(writer);
  value_->WriteTo(writer);
}


Statement* Statement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  switch (tag) {
    case kInvalidStatement:
      return InvalidStatement::ReadFrom(reader);
    case kExpressionStatement:
      return ExpressionStatement::ReadFrom(reader);
    case kBlock:
      return Block::ReadFromImpl(reader);
    case kEmptyStatement:
      return EmptyStatement::ReadFrom(reader);
    case kAssertStatement:
      return AssertStatement::ReadFrom(reader);
    case kLabeledStatement:
      return LabeledStatement::ReadFrom(reader);
    case kBreakStatement:
      return BreakStatement::ReadFrom(reader);
    case kWhileStatement:
      return WhileStatement::ReadFrom(reader);
    case kDoStatement:
      return DoStatement::ReadFrom(reader);
    case kForStatement:
      return ForStatement::ReadFrom(reader);
    case kForInStatement:
      return ForInStatement::ReadFrom(reader, false);
    case kAsyncForInStatement:
      return ForInStatement::ReadFrom(reader, true);
    case kSwitchStatement:
      return SwitchStatement::ReadFrom(reader);
    case kContinueSwitchStatement:
      return ContinueSwitchStatement::ReadFrom(reader);
    case kIfStatement:
      return IfStatement::ReadFrom(reader);
    case kReturnStatement:
      return ReturnStatement::ReadFrom(reader);
    case kTryCatch:
      return TryCatch::ReadFrom(reader);
    case kTryFinally:
      return TryFinally::ReadFrom(reader);
    case kYieldStatement:
      return YieldStatement::ReadFrom(reader);
    case kVariableDeclaration:
      return VariableDeclaration::ReadFromImpl(reader);
    case kFunctionDeclaration:
      return FunctionDeclaration::ReadFrom(reader);
    default:
      UNREACHABLE();
  }
  return NULL;
}


InvalidStatement* InvalidStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new InvalidStatement();
}


void InvalidStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kInvalidStatement);
}


ExpressionStatement* ExpressionStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new ExpressionStatement(Expression::ReadFrom(reader));
}


void ExpressionStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kExpressionStatement);
  expression_->WriteTo(writer);
}


Block* Block::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> vars(reader->helper());
  Block* block = new Block();
  block->statements().ReadFromStatic<Statement>(reader);
  return block;
}


void Block::WriteTo(Writer* writer) {
  writer->WriteTag(kBlock);
  WriteToImpl(writer);
}


void Block::WriteToImpl(Writer* writer) {
  TRACE_WRITE_OFFSET();
  VariableScope<WriterHelper> vars(writer->helper());
  statements_.WriteTo(writer);
}


EmptyStatement* EmptyStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new EmptyStatement();
}


void EmptyStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kEmptyStatement);
}


AssertStatement* AssertStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  AssertStatement* stmt = new AssertStatement();
  stmt->condition_ = Expression::ReadFrom(reader);
  stmt->message_ = reader->ReadOptional<Expression>();
  return stmt;
}


void AssertStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kAssertStatement);
  condition_->WriteTo(writer);
  writer->WriteOptional<Expression>(message_);
}


LabeledStatement* LabeledStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  LabeledStatement* stmt = new LabeledStatement();
  reader->helper()->lables().Push(stmt);
  stmt->body_ = Statement::ReadFrom(reader);
  reader->helper()->lables().Pop(stmt);
  return stmt;
}


void LabeledStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kLabeledStatement);
  writer->helper()->lables().Push(this);
  body_->WriteTo(writer);
  writer->helper()->lables().Pop(this);
}


BreakStatement* BreakStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  BreakStatement* stmt = new BreakStatement();
  stmt->target_ = reader->helper()->lables().Lookup(reader->ReadUInt());
  return stmt;
}


void BreakStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kBreakStatement);
  writer->WriteUInt(writer->helper()->lables().Lookup(target_));
}


WhileStatement* WhileStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  WhileStatement* stmt = new WhileStatement();
  stmt->condition_ = Expression::ReadFrom(reader);
  stmt->body_ = Statement::ReadFrom(reader);
  return stmt;
}


void WhileStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kWhileStatement);
  condition_->WriteTo(writer);
  body_->WriteTo(writer);
}


DoStatement* DoStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  DoStatement* dostmt = new DoStatement();
  dostmt->body_ = Statement::ReadFrom(reader);
  dostmt->condition_ = Expression::ReadFrom(reader);
  return dostmt;
}


void DoStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kDoStatement);
  body_->WriteTo(writer);
  condition_->WriteTo(writer);
}


ForStatement* ForStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> vars(reader->helper());
  ForStatement* forstmt = new ForStatement();
  forstmt->variables_.ReadFromStatic<VariableDeclarationImpl>(reader);
  forstmt->condition_ = reader->ReadOptional<Expression>();
  forstmt->updates_.ReadFromStatic<Expression>(reader);
  forstmt->body_ = Statement::ReadFrom(reader);
  return forstmt;
}


void ForStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kForStatement);
  VariableScope<WriterHelper> vars(writer->helper());
  variables_.WriteToStatic<VariableDeclarationImpl>(writer);
  writer->WriteOptional<Expression>(condition_);
  updates_.WriteTo(writer);
  body_->WriteTo(writer);
}


ForInStatement* ForInStatement::ReadFrom(Reader* reader, bool is_async) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> vars(reader->helper());
  ForInStatement* forinstmt = new ForInStatement();
  forinstmt->is_async_ = is_async;
  forinstmt->variable_ = VariableDeclaration::ReadFromImpl(reader);
  forinstmt->iterable_ = Expression::ReadFrom(reader);
  forinstmt->body_ = Statement::ReadFrom(reader);
  return forinstmt;
}


void ForInStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(is_async_ ? kAsyncForInStatement : kForInStatement);
  VariableScope<WriterHelper> vars(writer->helper());
  variable_->WriteToImpl(writer);
  iterable_->WriteTo(writer);
  body_->WriteTo(writer);
}


SwitchStatement* SwitchStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  SwitchCaseScope<ReaderHelper> scope(reader->helper());
  SwitchStatement* stmt = new SwitchStatement();
  stmt->condition_ = Expression::ReadFrom(reader);
  // We need to explicitly create empty [SwitchCase]s first in order to add them
  // to the [SwitchCaseScope]. This is necessary since a [Statement] in a switch
  // case can refer to one defined later on.
  int count = reader->ReadUInt();
  for (int i = 0; i < count; i++) {
    SwitchCase* sc = stmt->cases_.GetOrCreate<SwitchCase>(i);
    reader->helper()->switch_cases().Push(sc);
  }
  for (int i = 0; i < count; i++) {
    SwitchCase* sc = stmt->cases_[i];
    sc->ReadFrom(reader);
  }
  return stmt;
}


void SwitchStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  SwitchCaseScope<WriterHelper> scope(writer->helper());
  writer->WriteTag(kSwitchStatement);
  condition_->WriteTo(writer);
  for (int i = 0; i < cases_.length(); i++) {
    writer->helper()->switch_cases().Push(cases_[i]);
  }
  cases_.WriteTo(writer);
}


SwitchCase* SwitchCase::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  expressions_.ReadFromStatic<Expression>(reader);
  is_default_ = reader->ReadBool();
  body_ = Statement::ReadFrom(reader);
  return this;
}


void SwitchCase::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  expressions_.WriteTo(writer);
  writer->WriteBool(is_default_);
  body_->WriteTo(writer);
}


ContinueSwitchStatement* ContinueSwitchStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  ContinueSwitchStatement* stmt = new ContinueSwitchStatement();
  stmt->target_ = reader->helper()->switch_cases().Lookup(reader->ReadUInt());
  return stmt;
}


void ContinueSwitchStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kContinueSwitchStatement);
  writer->WriteUInt(writer->helper()->switch_cases().Lookup(target_));
}


IfStatement* IfStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  IfStatement* ifstmt = new IfStatement();
  ifstmt->condition_ = Expression::ReadFrom(reader);
  ifstmt->then_ = Statement::ReadFrom(reader);
  ifstmt->otherwise_ = Statement::ReadFrom(reader);
  return ifstmt;
}


void IfStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kIfStatement);
  condition_->WriteTo(writer);
  then_->WriteTo(writer);
  otherwise_->WriteTo(writer);
}


ReturnStatement* ReturnStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  ReturnStatement* ret = new ReturnStatement();
  ret->expression_ = reader->ReadOptional<Expression>();
  return ret;
}


void ReturnStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kReturnStatement);
  writer->WriteOptional<Expression>(expression_);
}


TryCatch* TryCatch::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TryCatch* tc = new TryCatch();
  tc->body_ = Statement::ReadFrom(reader);
  tc->catches_.ReadFromStatic<Catch>(reader);
  return tc;
}


void TryCatch::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kTryCatch);
  body_->WriteTo(writer);
  catches_.WriteTo(writer);
}


Catch* Catch::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> vars(reader->helper());
  Catch* c = new Catch();
  c->guard_ = DartType::ReadFrom(reader);
  c->exception_ =
      reader->ReadOptional<VariableDeclaration, VariableDeclarationImpl>();
  c->stack_trace_ =
      reader->ReadOptional<VariableDeclaration, VariableDeclarationImpl>();
  c->body_ = Statement::ReadFrom(reader);
  return c;
}


void Catch::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  VariableScope<WriterHelper> vars(writer->helper());
  guard_->WriteTo(writer);
  writer->WriteOptionalStatic<VariableDeclaration, VariableDeclarationImpl>(
      exception_);
  writer->WriteOptionalStatic<VariableDeclaration, VariableDeclarationImpl>(
      stack_trace_);
  body_->WriteTo(writer);
}


TryFinally* TryFinally::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TryFinally* tf = new TryFinally();
  tf->body_ = Statement::ReadFrom(reader);
  tf->finalizer_ = Statement::ReadFrom(reader);
  return tf;
}


void TryFinally::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kTryFinally);
  body_->WriteTo(writer);
  finalizer_->WriteTo(writer);
}


YieldStatement* YieldStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  YieldStatement* stmt = new YieldStatement();
  stmt->flags_ = reader->ReadByte();
  stmt->expression_ = Expression::ReadFrom(reader);
  return stmt;
}


void YieldStatement::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kYieldStatement);
  writer->WriteByte(flags_);
  expression_->WriteTo(writer);
}


VariableDeclaration* VariableDeclaration::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  ASSERT(tag == kVariableDeclaration);
  return VariableDeclaration::ReadFromImpl(reader);
}


VariableDeclaration* VariableDeclaration::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableDeclaration* decl = new VariableDeclaration();
  decl->flags_ = reader->ReadFlags();
  decl->name_ = Reference::ReadStringFrom(reader);
  decl->type_ = DartType::ReadFrom(reader);
  decl->inferred_value_ = reader->ReadOptional<InferredValue>();
  decl->initializer_ = reader->ReadOptional<Expression>();
  reader->helper()->variables().Push(decl);
  return decl;
}


void VariableDeclaration::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kVariableDeclaration);
  WriteToImpl(writer);
}


void VariableDeclaration::WriteToImpl(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteFlags(flags_);
  name_->WriteTo(writer);
  type_->WriteTo(writer);
  writer->WriteOptional<InferredValue>(inferred_value_);
  writer->WriteOptional<Expression>(initializer_);
  writer->helper()->variables().Push(this);
}


FunctionDeclaration* FunctionDeclaration::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  FunctionDeclaration* decl = new FunctionDeclaration();
  decl->variable_ = VariableDeclaration::ReadFromImpl(reader);
  VariableScope<ReaderHelper> parameters(reader->helper());
  decl->function_ = FunctionNode::ReadFrom(reader);
  return decl;
}


void FunctionDeclaration::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kFunctionDeclaration);
  variable_->WriteToImpl(writer);
  VariableScope<WriterHelper> parameters(writer->helper());
  function_->WriteTo(writer);
}


Name* Name::ReadFrom(Reader* reader) {
  String* string = Reference::ReadStringFrom(reader);
  if (string->size() >= 1 && string->buffer()[0] == '_') {
    int lib_index = reader->ReadUInt();
    Library* library =
        reader->helper()->program()->libraries().GetOrCreate<Library>(
            lib_index);
    return new Name(string, library);
  } else {
    return new Name(string, NULL);
  }
}


void Name::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  string_->WriteTo(writer);
  Library* library = library_;
  bool is_private = library != NULL;
  if (is_private) {
    writer->WriteUInt(writer->helper()->libraries().Lookup(library_));
  }
}


InferredValue* InferredValue::ReadFrom(Reader* reader) {
  InferredValue* type = new InferredValue();
  type->klass_ = Reference::ReadClassFrom(reader, true);
  type->kind_ = static_cast<BaseClassKind>(reader->ReadByte());
  type->value_bits_ = reader->ReadByte();
  return type;
}


void InferredValue::WriteTo(Writer* writer) {
  Reference::WriteClassTo(writer, klass_, true);
  writer->WriteByte(static_cast<uint8_t>(kind_));
  writer->WriteByte(value_bits_);
}


DartType* DartType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  switch (tag) {
    case kInvalidType:
      return InvalidType::ReadFrom(reader);
    case kDynamicType:
      return DynamicType::ReadFrom(reader);
    case kVoidType:
      return VoidType::ReadFrom(reader);
    case kInterfaceType:
      return InterfaceType::ReadFrom(reader);
    case kSimpleInterfaceType:
      return InterfaceType::ReadFrom(reader, true);
    case kFunctionType:
      return FunctionType::ReadFrom(reader);
    case kSimpleFunctionType:
      return FunctionType::ReadFrom(reader, true);
    case kTypeParameterType:
      return TypeParameterType::ReadFrom(reader);
    default:
      UNREACHABLE();
  }
  UNREACHABLE();
  return NULL;
}


InvalidType* InvalidType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new InvalidType();
}


void InvalidType::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kInvalidType);
}


DynamicType* DynamicType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new DynamicType();
}


void DynamicType::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kDynamicType);
}


VoidType* VoidType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new VoidType();
}


void VoidType::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kVoidType);
}


InterfaceType* InterfaceType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Class* klass = Reference::ReadClassFrom(reader);
  InterfaceType* type = new InterfaceType(klass);
  type->type_arguments().ReadFromStatic<DartType>(reader);
  return type;
}


InterfaceType* InterfaceType::ReadFrom(Reader* reader,
                                       bool _without_type_arguments_) {
  TRACE_READ_OFFSET();
  Class* klass = Reference::ReadClassFrom(reader);
  InterfaceType* type = new InterfaceType(klass);
  ASSERT(_without_type_arguments_);
  return type;
}


void InterfaceType::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  if (type_arguments_.length() == 0) {
    writer->WriteTag(kSimpleInterfaceType);
    Reference::WriteClassTo(writer, klass_);
  } else {
    writer->WriteTag(kInterfaceType);
    Reference::WriteClassTo(writer, klass_);
    type_arguments_.WriteTo(writer);
  }
}


FunctionType* FunctionType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  FunctionType* type = new FunctionType();
  TypeParameterScope<ReaderHelper> scope(reader->helper());
  type->type_parameters().ReadFrom(reader);
  type->required_parameter_count_ = reader->ReadUInt();
  type->positional_parameters().ReadFromStatic<DartType>(reader);
  type->named_parameters().ReadFromStatic<Tuple<String, DartType> >(reader);
  type->return_type_ = DartType::ReadFrom(reader);
  return type;
}


FunctionType* FunctionType::ReadFrom(Reader* reader, bool _is_simple_) {
  TRACE_READ_OFFSET();
  FunctionType* type = new FunctionType();
  ASSERT(_is_simple_);
  type->positional_parameters().ReadFromStatic<DartType>(reader);
  type->required_parameter_count_ = type->positional_parameters().length();
  type->return_type_ = DartType::ReadFrom(reader);
  return type;
}


void FunctionType::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();

  bool is_simple =
      positional_parameters_.length() == required_parameter_count_ &&
      type_parameters_.length() == 0 && named_parameters_.length() == 0;
  if (is_simple) {
    writer->WriteTag(kSimpleFunctionType);
    positional_parameters_.WriteTo(writer);
    return_type_->WriteTo(writer);
  } else {
    TypeParameterScope<WriterHelper> scope(writer->helper());
    writer->WriteTag(kFunctionType);
    type_parameters_.WriteTo(writer);
    writer->WriteUInt(required_parameter_count_);
    positional_parameters_.WriteTo(writer);
    named_parameters_.WriteTo(writer);
    return_type_->WriteTo(writer);
  }
}


TypeParameterType* TypeParameterType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TypeParameterType* type = new TypeParameterType();
  type->parameter_ =
      reader->helper()->type_parameters().Lookup(reader->ReadUInt());
  return type;
}


void TypeParameterType::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  writer->WriteTag(kTypeParameterType);
  writer->WriteUInt(writer->helper()->type_parameters().Lookup(parameter_));
}


Program* Program::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  uint32_t magic = reader->ReadUInt32();
  if (magic != kMagicProgramFile) FATAL("Invalid magic identifier");

  Program* program = new Program();
  reader->helper()->set_program(program);

  program->string_table_.ReadFrom(reader);
  StringTable dummy1;
  dummy1.ReadFrom(reader);
  LineStartingTable dummy2;
  dummy2.ReadFrom(reader, dummy1.strings_.length());

  int libraries = reader->ReadUInt();
  program->libraries().EnsureInitialized(libraries);
  for (int i = 0; i < libraries; i++) {
    program->libraries().GetOrCreate<Library>(i)->ReadFrom(reader);
  }

  program->main_method_ = Procedure::Cast(Reference::ReadMemberFrom(reader));

  return program;
}


void Program::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();

  writer->helper()->SetProgram(this);

  writer->WriteUInt32(kMagicProgramFile);

  // NOTE: Currently we don't GC strings and we require that all referenced
  // strings in nodes are present in [string_table_].
  string_table_.WriteTo(writer);
  StringTable dummy1;
  dummy1.WriteTo(writer);
  LineStartingTable dummy2;
  dummy2.WriteTo(writer);

  libraries_.WriteTo(writer);
  Reference::WriteMemberTo(writer, main_method_);
}


FunctionNode* FunctionNode::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TypeParameterScope<ReaderHelper> scope(reader->helper());

  FunctionNode* function = new FunctionNode();
  function->async_marker_ =
      static_cast<FunctionNode::AsyncMarker>(reader->ReadByte());
  function->type_parameters().ReadFrom(reader);
  function->required_parameter_count_ = reader->ReadUInt();
  function->positional_parameters().ReadFromStatic<VariableDeclarationImpl>(
      reader);
  function->named_parameters().ReadFromStatic<VariableDeclarationImpl>(reader);
  function->return_type_ = DartType::ReadFrom(reader);
  function->inferred_return_value_ = reader->ReadOptional<InferredValue>();

  VariableScope<ReaderHelper> vars(reader->helper());
  function->body_ = reader->ReadOptional<Statement>();
  return function;
}


void FunctionNode::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  TypeParameterScope<WriterHelper> scope(writer->helper());

  writer->WriteByte(static_cast<uint8_t>(async_marker_));
  type_parameters().WriteTo(writer);
  writer->WriteUInt(required_parameter_count());
  positional_parameters().WriteToStatic<VariableDeclarationImpl>(writer);
  named_parameters().WriteToStatic<VariableDeclarationImpl>(writer);
  return_type_->WriteTo(writer);
  writer->WriteOptional<InferredValue>(inferred_return_value_);

  VariableScope<WriterHelper> vars(writer->helper());
  writer->WriteOptional<Statement>(body_);
}


TypeParameter* TypeParameter::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  name_ = Reference::ReadStringFrom(reader);
  bound_ = DartType::ReadFrom(reader);
  return this;
}


void TypeParameter::WriteTo(Writer* writer) {
  TRACE_WRITE_OFFSET();
  name_->WriteTo(writer);
  bound_->WriteTo(writer);
}


}  // namespace kernel


kernel::Program* ReadPrecompiledKernelFromBuffer(const uint8_t* buffer,
                                                 intptr_t buffer_length) {
  kernel::Reader reader(buffer, buffer_length);
  return kernel::Program::ReadFrom(&reader);
}


void WritePrecompiledKernel(ByteWriter* byte_writer, kernel::Program* program) {
  ASSERT(byte_writer != NULL);

  kernel::Writer writer(byte_writer);
  program->WriteTo(&writer);
}


}  // namespace dart
