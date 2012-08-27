// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SNAPSHOT_H_
#define VM_SNAPSHOT_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/datastream.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class AbstractType;
class AbstractTypeArguments;
class Array;
class Class;
class ClassTable;
class GrowableObjectArray;
class Heap;
class Library;
class Object;
class ObjectStore;
class RawAbstractTypeArguments;
class RawApiError;
class RawArray;
class RawBigint;
class RawClass;
class RawContext;
class RawDouble;
class RawField;
class RawFourByteString;
class RawFunction;
class RawGrowableObjectArray;
class RawImmutableArray;
class RawLanguageError;
class RawLibrary;
class RawLibraryPrefix;
class RawLiteralToken;
class RawMint;
class RawObject;
class RawOneByteString;
class RawPatchClass;
class RawScript;
class RawSmi;
class RawTokenStream;
class RawType;
class RawTypeParameter;
class RawTypeArguments;
class RawTwoByteString;
class RawUnresolvedClass;
class String;

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

  static const int kHeaderSize = 2 * sizeof(int32_t);
  static const int kLengthIndex = 0;
  static const int kSnapshotFlagIndex = 1;

  static const Snapshot* SetupFromBuffer(const void* raw_memory);

  // Getters.
  const uint8_t* content() const { return content_; }
  int32_t length() const { return length_; }
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

  int32_t length_;  // Stream length.
  int32_t kind_;  // Kind of snapshot.
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
    return value;
  }

  void ReadBytes(uint8_t* addr, intptr_t len) {
    stream_.ReadBytes(addr, len);
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
  String* StringHandle() { return &str_; }
  AbstractType* TypeHandle() { return &type_; }
  AbstractTypeArguments* TypeArgumentsHandle() { return &type_arguments_; }
  Array* TokensHandle() { return &tokens_; }

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
  RawFourByteString* NewFourByteString(intptr_t len);
  RawTypeArguments* NewTypeArguments(intptr_t len);
  RawTokenStream* NewTokenStream(intptr_t len);
  RawContext* NewContext(intptr_t num_variables);
  RawClass* NewClass(intptr_t class_id, bool is_signature_class);
  RawMint* NewMint(int64_t value);
  RawBigint* NewBigint(const char* hex_string);
  RawDouble* NewDouble(double value);
  RawUnresolvedClass* NewUnresolvedClass();
  RawType* NewType();
  RawTypeParameter* NewTypeParameter();
  RawPatchClass* NewPatchClass();
  RawFunction* NewFunction();
  RawField* NewField();
  RawLibrary* NewLibrary();
  RawLibraryPrefix* NewLibraryPrefix();
  RawScript* NewScript();
  RawLiteralToken* NewLiteralToken();
  RawGrowableObjectArray* NewGrowableObjectArray();
  RawApiError* NewApiError();
  RawLanguageError* NewLanguageError();

 private:
  class BackRefNode : public ZoneAllocated {
   public:
    BackRefNode(Object* reference, DeserializeState state)
        : reference_(reference), state_(state) {}
    Object* reference() const { return reference_; }
    bool is_deserialized() const { return state_ == kIsDeserialized; }
    void set_state(DeserializeState state) { state_ = state; }

   private:
    Object* reference_;
    DeserializeState state_;

    DISALLOW_COPY_AND_ASSIGN(BackRefNode);
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
  String& str_;  // Temporary String handle.
  Library& library_;  // Temporary library handle.
  AbstractType& type_;  // Temporary type handle.
  AbstractTypeArguments& type_arguments_;  // Temporary type argument handle.
  Array& tokens_;  // Temporary tokens handle.
  GrowableArray<BackRefNode*> backward_references_;

  friend class ApiError;
  friend class Array;
  friend class Class;
  friend class Context;
  friend class ContextScope;
  friend class Field;
  friend class Function;
  friend class GrowableObjectArray;
  friend class ImmutableArray;
  friend class InstantiatedTypeArguments;
  friend class JSRegExp;
  friend class LanguageError;
  friend class Library;
  friend class LibraryPrefix;
  friend class LiteralToken;
  friend class PatchClass;
  friend class Script;
  friend class TokenStream;
  friend class Type;
  friend class TypeArguments;
  friend class TypeParameter;
  friend class UnresolvedClass;
  friend class WeakProperty;
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

 protected:
  BaseWriter(uint8_t** buffer, ReAlloc alloc) : stream_(buffer, alloc) {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
  }
  ~BaseWriter() { }

  void ReserveHeader() {
    // Make room for recording snapshot buffer size.
    stream_.set_current(stream_.buffer() + Snapshot::kHeaderSize);
  }

  void FillHeader(Snapshot::Kind kind) {
    int32_t* data = reinterpret_cast<int32_t*>(stream_.buffer());
    data[Snapshot::kLengthIndex] = stream_.bytes_written();
    data[Snapshot::kSnapshotFlagIndex] = kind;
  }

 private:
  WriteStream stream_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BaseWriter);
};


class SnapshotWriter : public BaseWriter {
 protected:
  SnapshotWriter(Snapshot::Kind kind, uint8_t** buffer, ReAlloc alloc)
      : BaseWriter(buffer, alloc),
        kind_(kind),
        object_store_(Isolate::Current()->object_store()),
        class_table_(Isolate::Current()->class_table()),
        forward_list_() {
  }

 public:
  // Snapshot kind.
  Snapshot::Kind kind() const { return kind_; }

  // Serialize an object into the buffer.
  void WriteObject(RawObject* raw);

  uword GetObjectTags(RawObject* raw);

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
                    RawAbstractTypeArguments* type_arguments,
                    RawObject* data[]);

  ObjectStore* object_store() const { return object_store_; }

 private:
  Snapshot::Kind kind_;
  ObjectStore* object_store_;  // Object store for common classes.
  ClassTable* class_table_;  // Class table for the class index to class lookup.
  GrowableArray<ForwardObjectNode*> forward_list_;

  friend class RawArray;
  friend class RawClass;
  friend class RawGrowableObjectArray;
  friend class RawImmutableArray;
  friend class RawJSRegExp;
  friend class RawLibrary;
  friend class RawLiteralToken;
  friend class RawScript;
  friend class RawTokenStream;
  friend class RawTypeArguments;
  friend class SnapshotWriterVisitor;
  DISALLOW_COPY_AND_ASSIGN(SnapshotWriter);
};


class FullSnapshotWriter : public SnapshotWriter {
 public:
  FullSnapshotWriter(uint8_t** buffer, ReAlloc alloc)
      : SnapshotWriter(Snapshot::kFull, buffer, alloc) {
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
  ScriptSnapshotWriter(uint8_t** buffer, ReAlloc alloc)
      : SnapshotWriter(Snapshot::kScript, buffer, alloc) {
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
  MessageWriter(uint8_t** buffer, ReAlloc alloc)
      : SnapshotWriter(Snapshot::kMessage, buffer, alloc) {
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
