// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SNAPSHOT_H_
#define VM_SNAPSHOT_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/datastream.h"
#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class AbstractType;
class Array;
class Class;
class ClassTable;
class ExternalTypedData;
class GrowableObjectArray;
class Heap;
class LanguageError;
class Library;
class Object;
class ObjectStore;
class RawApiError;
class RawArray;
class RawBigint;
class RawBoundedType;
class RawMixinAppType;
class RawClass;
class RawContext;
class RawDouble;
class RawField;
class RawClosureData;
class RawRedirectionData;
class RawFunction;
class RawGrowableObjectArray;
class RawFloat32x4;
class RawFloat64x2;
class RawInt32x4;
class RawImmutableArray;
class RawLanguageError;
class RawLibrary;
class RawLibraryPrefix;
class RawNamespace;
class RawLiteralToken;
class RawMint;
class RawObject;
class RawOneByteString;
class RawPatchClass;
class RawScript;
class RawSmi;
class RawCapability;
class RawReceivePort;
class RawSendPort;
class RawStacktrace;
class RawTokenStream;
class RawType;
class RawTypeRef;
class RawTypeParameter;
class RawTypeArguments;
class RawTwoByteString;
class RawUnresolvedClass;
class String;
class TokenStream;
class TypeArguments;
class UnhandledException;

// Serialized object header encoding is as follows:
// - Smi: the Smi value is written as is (last bit is not tagged).
// - VM object (from VM isolate): (object id in vm isolate | 0x3)
//   This valus is serialized as a negative number.
//   (note VM objects are never serialized they are expected to be found
//    using ths unique ID assigned to them).
// - Reference to object that has already been written: (object id | 0x3)
//   This valus is serialized as a positive number.
// - Object that is seen for the first time (inlined in the stream):
//   (a unique id for this object | 0x1)
enum SerializedHeaderType {
  kInlined  = 0x1,
  kObjectId = 0x3,
};
static const int8_t kHeaderTagBits = 2;
static const int8_t kObjectIdBits = (kBitsPerWord - (kHeaderTagBits + 1));
static const intptr_t kMaxObjectId = (kUwordMax >> (kHeaderTagBits + 1));


class SerializedHeaderTag : public BitField<enum SerializedHeaderType,
                                            0,
                                            kHeaderTagBits> {
};


class SerializedHeaderData : public BitField<intptr_t,
                                             kHeaderTagBits,
                                             kObjectIdBits> {
};


enum DeserializeState {
  kIsDeserialized = 0,
  kIsNotDeserialized = 1,
};


enum SerializeState {
  kIsSerialized = 0,
  kIsNotSerialized = 1,
};


#define HEAP_SPACE(kind) (kind == Snapshot::kMessage) ? Heap::kNew : Heap::kOld


// Structure capturing the raw snapshot.
//
// TODO(turnidge): Remove this class once the snapshot does not have a
// header anymore.  This is pending on making the embedder pass in the
// length of their snapshot.
class Snapshot {
 public:
  enum Kind {
    kFull = 0,  // Full snapshot of the current dart heap.
    kScript,    // A partial snapshot of only the application script.
    kMessage,   // A partial snapshot used only for isolate messaging.
  };

  static const int kHeaderSize = 2 * sizeof(int64_t);
  static const int kLengthIndex = 0;
  static const int kSnapshotFlagIndex = 1;

  static const Snapshot* SetupFromBuffer(const void* raw_memory);

  // Getters.
  const uint8_t* content() const { return content_; }
  int64_t length() const { return length_; }
  Kind kind() const { return static_cast<Kind>(kind_); }

  bool IsMessageSnapshot() const { return kind_ == kMessage; }
  bool IsScriptSnapshot() const { return kind_ == kScript; }
  bool IsFullSnapshot() const { return kind_ == kFull; }
  uint8_t* Addr() { return reinterpret_cast<uint8_t*>(this); }

  static intptr_t length_offset() { return OFFSET_OF(Snapshot, length_); }
  static intptr_t kind_offset() {
    return OFFSET_OF(Snapshot, kind_);
  }

 private:
  Snapshot() : length_(0), kind_(kFull) {}

  int64_t length_;  // Stream length.
  int64_t kind_;  // Kind of snapshot.
  uint8_t content_[];  // Stream content.

  DISALLOW_COPY_AND_ASSIGN(Snapshot);
};


class BaseReader {
 public:
  BaseReader(const uint8_t* buffer, intptr_t size) : stream_(buffer, size) {}
  // Reads raw data (for basic types).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  T Read() {
    return ReadStream::Raw<sizeof(T), T>::Read(&stream_);
  }

  // Reads an intptr_t type value.
  intptr_t ReadIntptrValue() {
    int64_t value = Read<int64_t>();
    ASSERT((value <= kIntptrMax) && (value >= kIntptrMin));
    return static_cast<intptr_t>(value);
  }

  void ReadBytes(uint8_t* addr, intptr_t len) {
    stream_.ReadBytes(addr, len);
  }

  double ReadDouble() {
    double result;
    stream_.ReadBytes(reinterpret_cast<uint8_t*>(&result), sizeof(result));
    return result;
  }


  const uint8_t* CurrentBufferAddress() const {
    return stream_.AddressOfCurrentPosition();
  }

  void Advance(intptr_t value) {
    stream_.Advance(value);
  }

  RawSmi* ReadAsSmi();
  intptr_t ReadSmiValue();

  // Negative header value indicates VM isolate object id.
  bool IsVMIsolateObject(intptr_t header_value) { return (header_value < 0); }
  intptr_t GetVMIsolateObjectId(intptr_t header_val) {
    ASSERT(IsVMIsolateObject(header_val));
    intptr_t value = -header_val;  // Header is negative for VM isolate objects.
    ASSERT(SerializedHeaderTag::decode(value) == kObjectId);
    return SerializedHeaderData::decode(value);
  }

 private:
  ReadStream stream_;  // input stream.
};


// Reads a snapshot into objects.
class SnapshotReader : public BaseReader {
 public:
  SnapshotReader(const uint8_t* buffer,
                 intptr_t size,
                 Snapshot::Kind kind,
                 Isolate* isolate);
  ~SnapshotReader() { }

  Isolate* isolate() const { return isolate_; }
  Heap* heap() const { return isolate_->heap(); }
  ObjectStore* object_store() const { return isolate_->object_store(); }
  ClassTable* class_table() const { return isolate_->class_table(); }
  Object* ObjectHandle() { return &obj_; }
  Array* ArrayHandle() { return &array_; }
  String* StringHandle() { return &str_; }
  AbstractType* TypeHandle() { return &type_; }
  TypeArguments* TypeArgumentsHandle() { return &type_arguments_; }
  Array* TokensHandle() { return &tokens_; }
  TokenStream* StreamHandle() { return &stream_; }
  ExternalTypedData* DataHandle() { return &data_; }
  UnhandledException* ErrorHandle() { return &error_; }

  // Reads an object.
  RawObject* ReadObject();

  // Add object to backward references.
  void AddBackRef(intptr_t id, Object* obj, DeserializeState state);

  // Get an object from the backward references list.
  Object* GetBackRef(intptr_t id);

  // Read a full snap shot.
  void ReadFullSnapshot();

  // Helper functions for creating uninitialized versions
  // of various object types. These are used when reading a
  // full snapshot.
  RawArray* NewArray(intptr_t len);
  RawImmutableArray* NewImmutableArray(intptr_t len);
  RawOneByteString* NewOneByteString(intptr_t len);
  RawTwoByteString* NewTwoByteString(intptr_t len);
  RawTypeArguments* NewTypeArguments(intptr_t len);
  RawTokenStream* NewTokenStream(intptr_t len);
  RawContext* NewContext(intptr_t num_variables);
  RawClass* NewClass(intptr_t class_id);
  RawInstance* NewInstance();
  RawMint* NewMint(int64_t value);
  RawBigint* NewBigint(const char* hex_string);
  RawDouble* NewDouble(double value);
  RawUnresolvedClass* NewUnresolvedClass();
  RawType* NewType();
  RawTypeRef* NewTypeRef();
  RawTypeParameter* NewTypeParameter();
  RawBoundedType* NewBoundedType();
  RawMixinAppType* NewMixinAppType();
  RawPatchClass* NewPatchClass();
  RawClosureData* NewClosureData();
  RawRedirectionData* NewRedirectionData();
  RawFunction* NewFunction();
  RawField* NewField();
  RawLibrary* NewLibrary();
  RawLibraryPrefix* NewLibraryPrefix();
  RawNamespace* NewNamespace();
  RawScript* NewScript();
  RawLiteralToken* NewLiteralToken();
  RawGrowableObjectArray* NewGrowableObjectArray();
  RawFloat32x4* NewFloat32x4(float v0, float v1, float v2, float v3);
  RawInt32x4* NewInt32x4(uint32_t v0, uint32_t v1, uint32_t v2, uint32_t v3);
  RawFloat64x2* NewFloat64x2(double v0, double v1);
  RawApiError* NewApiError();
  RawLanguageError* NewLanguageError();
  RawObject* NewInteger(int64_t value);
  RawStacktrace* NewStacktrace();

 private:
  class BackRefNode : public ValueObject {
   public:
    BackRefNode(Object* reference, DeserializeState state)
        : reference_(reference), state_(state) {}
    Object* reference() const { return reference_; }
    bool is_deserialized() const { return state_ == kIsDeserialized; }
    void set_state(DeserializeState state) { state_ = state; }

    BackRefNode& operator=(const BackRefNode& other) {
      reference_ = other.reference_;
      state_ = other.state_;
      return *this;
    }

   private:
    Object* reference_;
    DeserializeState state_;
  };

  // Allocate uninitialized objects, this is used when reading a full snapshot.
  RawObject* AllocateUninitialized(const Class& cls, intptr_t size);

  RawClass* ReadClassId(intptr_t object_id);
  RawObject* ReadObjectImpl();
  RawObject* ReadObjectImpl(intptr_t header);
  RawObject* ReadObjectRef();

  // Read a VM isolate object that was serialized as an Id.
  RawObject* ReadVMIsolateObject(intptr_t object_id);

  // Read an object that was serialized as an Id (singleton in object store,
  // or an object that was already serialized before).
  RawObject* ReadIndexedObject(intptr_t object_id);

  // Read an inlined object from the stream.
  RawObject* ReadInlinedObject(intptr_t object_id);

  // Based on header field check to see if it is an internal VM class.
  RawClass* LookupInternalClass(intptr_t class_header);

  void ArrayReadFrom(const Array& result, intptr_t len, intptr_t tags);

  Snapshot::Kind kind_;  // Indicates type of snapshot(full, script, message).
  Isolate* isolate_;  // Current isolate.
  Class& cls_;  // Temporary Class handle.
  Object& obj_;  // Temporary Object handle.
  Array& array_;  // Temporary Array handle.
  Field& field_;  // Temporary Field handle.
  String& str_;  // Temporary String handle.
  Library& library_;  // Temporary library handle.
  AbstractType& type_;  // Temporary type handle.
  TypeArguments& type_arguments_;  // Temporary type argument handle.
  Array& tokens_;  // Temporary tokens handle.
  TokenStream& stream_;  // Temporary token stream handle.
  ExternalTypedData& data_;  // Temporary stream data handle.
  UnhandledException& error_;  // Error handle.
  GrowableArray<BackRefNode> backward_references_;

  friend class ApiError;
  friend class Array;
  friend class BoundedType;
  friend class MixinAppType;
  friend class Class;
  friend class Context;
  friend class ContextScope;
  friend class Field;
  friend class ClosureData;
  friend class RedirectionData;
  friend class Function;
  friend class GrowableObjectArray;
  friend class ImmutableArray;
  friend class JSRegExp;
  friend class LanguageError;
  friend class Library;
  friend class LibraryPrefix;
  friend class Namespace;
  friend class LiteralToken;
  friend class PatchClass;
  friend class Script;
  friend class Stacktrace;
  friend class TokenStream;
  friend class Type;
  friend class TypeArguments;
  friend class TypeParameter;
  friend class TypeRef;
  friend class UnresolvedClass;
  friend class WeakProperty;
  friend class MirrorReference;
  DISALLOW_COPY_AND_ASSIGN(SnapshotReader);
};


class BaseWriter {
 public:
  // Size of the snapshot.
  intptr_t BytesWritten() const { return stream_.bytes_written(); }

  // Writes raw data to the stream (basic type).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  void Write(T value) {
    WriteStream::Raw<sizeof(T), T>::Write(&stream_, value);
  }

  // Writes an intptr_t type value out.
  void WriteIntptrValue(intptr_t value) {
    Write<int64_t>(value);
  }

  // Write an object that is serialized as an Id (singleton in object store,
  // or an object that was already serialized before).
  void WriteIndexedObject(intptr_t object_id) {
    ASSERT(object_id <= kMaxObjectId);
    intptr_t value = 0;
    value = SerializedHeaderTag::update(kObjectId, value);
    value = SerializedHeaderData::update(object_id, value);
    WriteIntptrValue(value);
  }

  // Write a VM Isolateobject that is serialized as an Id.
  void WriteVMIsolateObject(intptr_t object_id) {
    ASSERT(object_id <= kMaxObjectId);
    intptr_t value = 0;
    value = SerializedHeaderTag::update(kObjectId, value);
    value = SerializedHeaderData::update(object_id, value);
    WriteIntptrValue(-value);  // Write as a negative value.
  }

  // Write serialization header information for an object.
  void WriteInlinedObjectHeader(intptr_t id) {
    ASSERT(id <= kMaxObjectId);
    intptr_t value = 0;
    value = SerializedHeaderTag::update(kInlined, value);
    value = SerializedHeaderData::update(id, value);
    WriteIntptrValue(value);
  }

  // Write out a buffer of bytes.
  void WriteBytes(const uint8_t* addr, intptr_t len) {
    stream_.WriteBytes(addr, len);
  }

  void WriteDouble(double value) {
    stream_.WriteBytes(reinterpret_cast<const uint8_t*>(&value), sizeof(value));
  }

 protected:
  BaseWriter(uint8_t** buffer,
             ReAlloc alloc,
             intptr_t initial_size) : stream_(buffer, alloc, initial_size) {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
  }
  ~BaseWriter() { }

  void ReserveHeader() {
    // Make room for recording snapshot buffer size.
    stream_.set_current(stream_.buffer() + Snapshot::kHeaderSize);
  }

  void FillHeader(Snapshot::Kind kind) {
    int64_t* data = reinterpret_cast<int64_t*>(stream_.buffer());
    data[Snapshot::kLengthIndex] = stream_.bytes_written();
    data[Snapshot::kSnapshotFlagIndex] = kind;
  }

 private:
  WriteStream stream_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BaseWriter);
};


class SnapshotWriter : public BaseWriter {
 protected:
  SnapshotWriter(Snapshot::Kind kind,
                 uint8_t** buffer,
                 ReAlloc alloc,
                 intptr_t initial_size);

 public:
  // Snapshot kind.
  Snapshot::Kind kind() const { return kind_; }

  // Serialize an object into the buffer.
  void WriteObject(RawObject* raw);

  uword GetObjectTags(RawObject* raw);

  Exceptions::ExceptionType exception_type() const {
    return exception_type_;
  }
  void set_exception_type(Exceptions::ExceptionType type) {
    exception_type_ = type;
  }
  const char* exception_msg() const { return exception_msg_; }
  void set_exception_msg(const char* msg) {
    exception_msg_ = msg;
  }
  void ThrowException(Exceptions::ExceptionType type, const char* msg);

 protected:
  class ForwardObjectNode : public ZoneAllocated {
   public:
    ForwardObjectNode(RawObject* raw, uword tags, SerializeState state)
        : raw_(raw), tags_(tags), state_(state) {}
    RawObject* raw() const { return raw_; }
    uword tags() const { return tags_; }
    bool is_serialized() const { return state_ == kIsSerialized; }
    void set_state(SerializeState value) { state_ = value; }

   private:
    RawObject* raw_;
    uword tags_;
    SerializeState state_;

    DISALLOW_COPY_AND_ASSIGN(ForwardObjectNode);
  };

  intptr_t MarkObject(RawObject* raw, SerializeState state);
  void UnmarkAll();

  bool CheckAndWritePredefinedObject(RawObject* raw);
  void HandleVMIsolateObject(RawObject* raw);

  void WriteObjectRef(RawObject* raw);
  void WriteClassId(RawClass* cls);
  void WriteObjectImpl(RawObject* raw);
  void WriteInlinedObject(RawObject* raw);
  void WriteForwardedObjects();
  void ArrayWriteTo(intptr_t object_id,
                    intptr_t array_kind,
                    intptr_t tags,
                    RawSmi* length,
                    RawTypeArguments* type_arguments,
                    RawObject* data[]);
  void CheckIfSerializable(RawClass* cls);
  void SetWriteException(Exceptions::ExceptionType type, const char* msg);
  void WriteInstance(intptr_t object_id,
                     RawObject* raw,
                     RawClass* cls,
                     intptr_t tags);
  void WriteInstanceRef(RawObject* raw, RawClass* cls);

  ObjectStore* object_store() const { return object_store_; }

 private:
  Snapshot::Kind kind_;
  ObjectStore* object_store_;  // Object store for common classes.
  ClassTable* class_table_;  // Class table for the class index to class lookup.
  GrowableArray<ForwardObjectNode*> forward_list_;
  Exceptions::ExceptionType exception_type_;  // Exception type.
  const char* exception_msg_;  // Message associated with exception.

  friend class RawArray;
  friend class RawClass;
  friend class RawClosureData;
  friend class RawGrowableObjectArray;
  friend class RawImmutableArray;
  friend class RawJSRegExp;
  friend class RawLibrary;
  friend class RawLiteralToken;
  friend class RawReceivePort;
  friend class RawScript;
  friend class RawStacktrace;
  friend class RawTokenStream;
  friend class RawTypeArguments;
  friend class RawMirrorReference;
  friend class SnapshotWriterVisitor;
  friend class RawUserTag;
  DISALLOW_COPY_AND_ASSIGN(SnapshotWriter);
};


class FullSnapshotWriter : public SnapshotWriter {
 public:
  static const intptr_t kInitialSize = 64 * KB;
  FullSnapshotWriter(uint8_t** buffer, ReAlloc alloc)
      : SnapshotWriter(Snapshot::kFull, buffer, alloc, kInitialSize) {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
  }
  ~FullSnapshotWriter() { }

  // Writes a full snapshot of the Isolate.
  void WriteFullSnapshot();

 private:
  DISALLOW_COPY_AND_ASSIGN(FullSnapshotWriter);
};


class ScriptSnapshotWriter : public SnapshotWriter {
 public:
  static const intptr_t kInitialSize = 64 * KB;
  ScriptSnapshotWriter(uint8_t** buffer, ReAlloc alloc)
      : SnapshotWriter(Snapshot::kScript, buffer, alloc, kInitialSize) {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
  }
  ~ScriptSnapshotWriter() { }

  // Writes a partial snapshot of the script.
  void WriteScriptSnapshot(const Library& lib);

 private:
  DISALLOW_COPY_AND_ASSIGN(ScriptSnapshotWriter);
};


class MessageWriter : public SnapshotWriter {
 public:
  static const intptr_t kInitialSize = 512;
  MessageWriter(uint8_t** buffer, ReAlloc alloc)
      : SnapshotWriter(Snapshot::kMessage, buffer, alloc, kInitialSize) {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
  }
  ~MessageWriter() { }

  void WriteMessage(const Object& obj);

 private:
  DISALLOW_COPY_AND_ASSIGN(MessageWriter);
};


// An object pointer visitor implementation which writes out
// objects to a snap shot.
class SnapshotWriterVisitor : public ObjectPointerVisitor {
 public:
  explicit SnapshotWriterVisitor(SnapshotWriter* writer)
      : ObjectPointerVisitor(Isolate::Current()),
        writer_(writer),
        as_references_(true) {}

  SnapshotWriterVisitor(SnapshotWriter* writer, bool as_references)
      : ObjectPointerVisitor(Isolate::Current()),
        writer_(writer),
        as_references_(as_references) {}

  virtual void VisitPointers(RawObject** first, RawObject** last);

 private:
  SnapshotWriter* writer_;
  bool as_references_;

  DISALLOW_COPY_AND_ASSIGN(SnapshotWriterVisitor);
};

}  // namespace dart

#endif  // VM_SNAPSHOT_H_
