// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SNAPSHOT_H_
#define RUNTIME_VM_SNAPSHOT_H_

#include <memory>
#include <utility>

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/datastream.h"
#include "vm/finalizable_data.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/message.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class AbstractType;
class Array;
class Class;
class ClassTable;
class Closure;
class Code;
class ExternalTypedData;
class TypedDataBase;
class GrowableObjectArray;
class Heap;
class Instance;
class Instructions;
class LanguageError;
class Library;
class LinkedHashMap;
class Object;
class PassiveObject;
class ObjectStore;
class MegamorphicCache;
class PageSpace;
class TypedDataView;
class RawApiError;
class RawArray;
class RawCapability;
class RawClass;
class RawClosure;
class RawClosureData;
class RawCodeSourceMap;
class RawContext;
class RawContextScope;
class RawDouble;
class RawExceptionHandlers;
class RawFfiTrampolineData;
class RawField;
class RawFloat32x4;
class RawFloat64x2;
class RawFunction;
class RawGrowableObjectArray;
class RawICData;
class RawImmutableArray;
class RawInstructions;
class RawInt32x4;
class RawRegExp;
class RawLanguageError;
class RawLibrary;
class RawLibraryPrefix;
class RawLinkedHashMap;
class RawLocalVarDescriptors;
class RawMegamorphicCache;
class RawMint;
class RawNamespace;
class RawObject;
class RawObjectPool;
class RawOneByteString;
class RawPatchClass;
class RawPcDescriptors;
class RawReceivePort;
class RawRedirectionData;
class RawNativeEntryData;
class RawScript;
class RawSignatureData;
class RawSendPort;
class RawSmi;
class RawStackMap;
class RawStackTrace;
class RawSubtypeTestCache;
class RawTwoByteString;
class RawType;
class RawTypeArguments;
class RawTypedData;
class RawTypedDataView;
class RawTypeParameter;
class RawTypeRef;
class RawUnhandledException;
class RawWeakProperty;
class String;
class TypeArguments;
class TypedData;
class UnhandledException;

// Serialized object header encoding is as follows:
// - Smi: the Smi value is written as is (last bit is not tagged).
// - VM object (from VM isolate): (object id in vm isolate | 0x3)
//   This value is serialized as a negative number.
//   (note VM objects are never serialized, they are expected to be found
//    using ths unique ID assigned to them).
// - Reference to object that has already been written: (object id | 0x3)
//   This valus is serialized as a positive number.
// - Object that is seen for the first time (inlined in the stream):
//   (a unique id for this object | 0x1)
enum SerializedHeaderType {
  kInlined = 0x1,
  kObjectId = 0x3,
};
static const int8_t kHeaderTagBits = 2;
static const int8_t kObjectIdBits = (kBitsPerInt32 - (kHeaderTagBits + 1));
static const intptr_t kMaxObjectId = (kMaxUint32 >> (kHeaderTagBits + 1));
static const bool kAsReference = true;
static const bool kAsInlinedObject = false;
static const intptr_t kInvalidPatchIndex = -1;

class SerializedHeaderTag
    : public BitField<intptr_t, enum SerializedHeaderType, 0, kHeaderTagBits> {
};

class SerializedHeaderData
    : public BitField<intptr_t, intptr_t, kHeaderTagBits, kObjectIdBits> {};

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
class Snapshot {
 public:
  enum Kind {
    kFull,     // Full snapshot of core libraries or an application.
    kFullJIT,  // Full + JIT code
    kFullAOT,  // Full + AOT code
    kMessage,  // A partial snapshot used only for isolate messaging.
    kNone,     // gen_snapshot
    kInvalid
  };
  static const char* KindToCString(Kind kind);

  static const Snapshot* SetupFromBuffer(const void* raw_memory);

  static const int32_t kMagicValue = 0xdcdcf5f5;
  static const intptr_t kMagicOffset = 0;
  static const intptr_t kMagicSize = sizeof(int32_t);
  static const intptr_t kLengthOffset = kMagicOffset + kMagicSize;
  static const intptr_t kLengthSize = sizeof(int64_t);
  static const intptr_t kKindOffset = kLengthOffset + kLengthSize;
  static const intptr_t kKindSize = sizeof(int64_t);
  static const intptr_t kHeaderSize = kKindOffset + kKindSize;

  // Accessors.
  bool check_magic() const {
    return Read<int32_t>(kMagicOffset) == kMagicValue;
  }
  void set_magic() { return Write<int32_t>(kMagicOffset, kMagicValue); }
  // Excluding the magic value from the size written in the buffer is needed
  // so we give a proper version mismatch error for snapshots create before
  // magic value was written by the VM instead of the embedder.
  int64_t large_length() const {
    return Read<int64_t>(kLengthOffset) + kMagicSize;
  }
  intptr_t length() const { return static_cast<intptr_t>(large_length()); }
  void set_length(intptr_t value) {
    return Write<int64_t>(kLengthOffset, value - kMagicSize);
  }
  Kind kind() const { return static_cast<Kind>(Read<int64_t>(kKindOffset)); }
  void set_kind(Kind value) { return Write<int64_t>(kKindOffset, value); }

  static bool IsFull(Kind kind) {
    return (kind == kFull) || (kind == kFullJIT) || (kind == kFullAOT);
  }
  static bool IncludesCode(Kind kind) {
    return (kind == kFullJIT) || (kind == kFullAOT);
  }
  static bool IncludesBytecode(Kind kind) {
    return (kind == kFull) || (kind == kFullJIT);
  }

  const uint8_t* Addr() const { return reinterpret_cast<const uint8_t*>(this); }

  const uint8_t* DataImage() const {
    if (!IncludesCode(kind())) {
      return NULL;
    }
    uword offset = Utils::RoundUp(length(), OS::kMaxPreferredCodeAlignment);
    return Addr() + offset;
  }

 private:
  // Prevent Snapshot from ever being allocated directly.
  Snapshot();

  template <typename T>
  T Read(intptr_t offset) const {
    return ReadUnaligned(
        reinterpret_cast<const T*>(reinterpret_cast<uword>(this) + offset));
  }

  template <typename T>
  void Write(intptr_t offset, T value) {
    return StoreUnaligned(
        reinterpret_cast<T*>(reinterpret_cast<uword>(this) + offset), value);
  }

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

  classid_t ReadClassIDValue() {
    uint32_t value = Read<uint32_t>();
    return static_cast<classid_t>(value);
  }
  COMPILE_ASSERT(sizeof(uint32_t) >= sizeof(classid_t));

  void ReadBytes(uint8_t* addr, intptr_t len) { stream_.ReadBytes(addr, len); }

  double ReadDouble() {
    double result;
    stream_.ReadBytes(reinterpret_cast<uint8_t*>(&result), sizeof(result));
    return result;
  }

  intptr_t ReadTags() {
    const intptr_t tags = static_cast<intptr_t>(Read<int8_t>()) & 0xff;
    return tags;
  }

  const uint8_t* CurrentBufferAddress() const {
    return stream_.AddressOfCurrentPosition();
  }

  void Advance(intptr_t value) { stream_.Advance(value); }

  intptr_t PendingBytes() const { return stream_.PendingBytes(); }

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

// Reads a snapshot into objects.
class SnapshotReader : public BaseReader {
 public:
  Thread* thread() const { return thread_; }
  Zone* zone() const { return zone_; }
  Isolate* isolate() const { return thread_->isolate(); }
  Heap* heap() const { return heap_; }
  ObjectStore* object_store() const { return isolate()->object_store(); }
  ClassTable* class_table() const { return isolate()->class_table(); }
  PassiveObject* PassiveObjectHandle() { return &pobj_; }
  Array* ArrayHandle() { return &array_; }
  Class* ClassHandle() { return &cls_; }
  Code* CodeHandle() { return &code_; }
  Instance* InstanceHandle() { return &instance_; }
  Instructions* InstructionsHandle() { return &instructions_; }
  String* StringHandle() { return &str_; }
  AbstractType* TypeHandle() { return &type_; }
  TypeArguments* TypeArgumentsHandle() { return &type_arguments_; }
  GrowableObjectArray* TokensHandle() { return &tokens_; }
  ExternalTypedData* DataHandle() { return &data_; }
  TypedDataBase* TypedDataBaseHandle() { return &typed_data_base_; }
  TypedData* TypedDataHandle() { return &typed_data_; }
  TypedDataView* TypedDataViewHandle() { return &typed_data_view_; }
  Function* FunctionHandle() { return &function_; }
  Snapshot::Kind kind() const { return kind_; }

  // Reads an object.
  RawObject* ReadObject();

  // Add object to backward references.
  void AddBackRef(intptr_t id, Object* obj, DeserializeState state);

  // Get an object from the backward references list.
  Object* GetBackRef(intptr_t id);

  // Read version number of snapshot and verify.
  RawApiError* VerifyVersionAndFeatures(Isolate* isolate);

  RawObject* NewInteger(int64_t value);

 protected:
  SnapshotReader(const uint8_t* buffer,
                 intptr_t size,
                 Snapshot::Kind kind,
                 ZoneGrowableArray<BackRefNode>* backward_references,
                 Thread* thread);
  ~SnapshotReader() {}

  ZoneGrowableArray<BackRefNode>* GetBackwardReferenceTable() const {
    return backward_references_;
  }
  void ResetBackwardReferenceTable() { backward_references_ = NULL; }
  PageSpace* old_space() const { return old_space_; }

 private:
  void EnqueueTypePostprocessing(const AbstractType& type);
  void RunDelayedTypePostprocessing();

  void EnqueueRehashingOfMap(const LinkedHashMap& map);
  void EnqueueRehashingOfSet(const Object& set);
  RawObject* RunDelayedRehashingOfMaps();

  RawClass* ReadClassId(intptr_t object_id);
  RawObject* ReadStaticImplicitClosure(intptr_t object_id, intptr_t cls_header);

  // Implementation to read an object.
  RawObject* ReadObjectImpl(bool as_reference);
  RawObject* ReadObjectImpl(intptr_t header, bool as_reference);

  // Read a Dart Instance object.
  RawObject* ReadInstance(intptr_t object_id, intptr_t tags, bool as_reference);

  // Read a VM isolate object that was serialized as an Id.
  RawObject* ReadVMIsolateObject(intptr_t object_id);

  // Read an object that was serialized as an Id (singleton in object store,
  // or an object that was already serialized before).
  RawObject* ReadIndexedObject(intptr_t object_id);

  // Decode class id from the header field.
  intptr_t LookupInternalClass(intptr_t class_header);

  void ArrayReadFrom(intptr_t object_id,
                     const Array& result,
                     intptr_t len,
                     intptr_t tags);

  intptr_t NextAvailableObjectId() const;

  void SetReadException(const char* msg);

  RawObject* VmIsolateSnapshotObject(intptr_t index) const;

  bool is_vm_isolate() const;

  Snapshot::Kind kind_;            // Indicates type of the snapshot.
  Thread* thread_;                 // Current thread.
  Zone* zone_;                     // Zone for allocations while reading.
  Heap* heap_;                     // Heap of the current isolate.
  PageSpace* old_space_;           // Old space of the current isolate.
  Class& cls_;                     // Temporary Class handle.
  Code& code_;                     // Temporary Code handle.
  Instance& instance_;             // Temporary Instance handle
  Instructions& instructions_;     // Temporary Instructions handle
  Object& obj_;                    // Temporary Object handle.
  PassiveObject& pobj_;            // Temporary PassiveObject handle.
  Array& array_;                   // Temporary Array handle.
  Field& field_;                   // Temporary Field handle.
  String& str_;                    // Temporary String handle.
  Library& library_;               // Temporary library handle.
  AbstractType& type_;             // Temporary type handle.
  TypeArguments& type_arguments_;  // Temporary type argument handle.
  GrowableObjectArray& tokens_;    // Temporary tokens handle.
  ExternalTypedData& data_;        // Temporary stream data handle.
  TypedDataBase& typed_data_base_;  // Temporary typed data base handle.
  TypedData& typed_data_;          // Temporary typed data handle.
  TypedDataView& typed_data_view_;  // Temporary typed data view handle.
  Function& function_;             // Temporary function handle.
  UnhandledException& error_;      // Error handle.
  const Class& set_class_;         // The LinkedHashSet class.
  intptr_t max_vm_isolate_object_id_;
  ZoneGrowableArray<BackRefNode>* backward_references_;
  GrowableObjectArray& types_to_postprocess_;
  GrowableObjectArray& objects_to_rehash_;

  friend class ApiError;
  friend class Array;
  friend class Class;
  friend class Closure;
  friend class ClosureData;
  friend class Context;
  friend class ContextScope;
  friend class ExceptionHandlers;
  friend class Field;
  friend class Function;
  friend class GrowableObjectArray;
  friend class ICData;
  friend class ImmutableArray;
  friend class KernelProgramInfo;
  friend class LanguageError;
  friend class Library;
  friend class LibraryPrefix;
  friend class LinkedHashMap;
  friend class MirrorReference;
  friend class Namespace;
  friend class PatchClass;
  friend class RedirectionData;
  friend class RegExp;
  friend class Script;
  friend class SignatureData;
  friend class SubtypeTestCache;
  friend class TransferableTypedData;
  friend class Type;
  friend class TypedDataView;
  friend class TypeArguments;
  friend class TypeParameter;
  friend class TypeRef;
  friend class UnhandledException;
  friend class WeakProperty;
  DISALLOW_COPY_AND_ASSIGN(SnapshotReader);
};

class MessageSnapshotReader : public SnapshotReader {
 public:
  MessageSnapshotReader(Message* message, Thread* thread);
  ~MessageSnapshotReader();

  MessageFinalizableData* finalizable_data() const { return finalizable_data_; }

 private:
  MessageFinalizableData* finalizable_data_;

  DISALLOW_COPY_AND_ASSIGN(MessageSnapshotReader);
};

class BaseWriter : public StackResource {
 public:
  uint8_t* buffer() { return stream_.buffer(); }
  intptr_t BytesWritten() const { return stream_.bytes_written(); }

  // Writes raw data to the stream (basic type).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  void Write(T value) {
    WriteStream::Raw<sizeof(T), T>::Write(&stream_, value);
  }

  void WriteClassIDValue(classid_t value) { Write<uint32_t>(value); }
  COMPILE_ASSERT(sizeof(uint32_t) >= sizeof(classid_t));

  // Write an object that is serialized as an Id (singleton in object store,
  // or an object that was already serialized before).
  void WriteIndexedObject(intptr_t object_id) {
    ASSERT(object_id <= kMaxObjectId);
    intptr_t value = 0;
    value = SerializedHeaderTag::update(kObjectId, value);
    value = SerializedHeaderData::update(object_id, value);
    Write<int32_t>(value);
  }

  // Write a VM Isolateobject that is serialized as an Id.
  void WriteVMIsolateObject(intptr_t object_id) {
    ASSERT(object_id <= kMaxObjectId);
    intptr_t value = 0;
    value = SerializedHeaderTag::update(kObjectId, value);
    value = SerializedHeaderData::update(object_id, value);
    Write<int32_t>(-value);  // Write as a negative value.
  }

  // Write serialization header information for an object.
  void WriteInlinedObjectHeader(intptr_t id) {
    ASSERT(id <= kMaxObjectId);
    intptr_t value = 0;
    value = SerializedHeaderTag::update(kInlined, value);
    value = SerializedHeaderData::update(id, value);
    Write<int32_t>(value);
  }

  void WriteTags(intptr_t tags) {
    const intptr_t flags = tags & 0xff;
    Write<int8_t>(static_cast<int8_t>(flags));
  }

  // Write out a buffer of bytes.
  void WriteBytes(const uint8_t* addr, intptr_t len) {
    stream_.WriteBytes(addr, len);
  }

  void WriteDouble(double value) {
    stream_.WriteBytes(reinterpret_cast<const uint8_t*>(&value), sizeof(value));
  }

 protected:
  BaseWriter(ReAlloc alloc, DeAlloc dealloc, intptr_t initial_size)
      : StackResource(Thread::Current()),
        buffer_(NULL),
        stream_(&buffer_, alloc, initial_size),
        dealloc_(dealloc) {
    ASSERT(alloc != NULL);
  }
  ~BaseWriter() {}

  void ReserveHeader() {
    // Make room for recording snapshot buffer size.
    stream_.SetPosition(Snapshot::kHeaderSize);
  }

  void FillHeader(Snapshot::Kind kind) {
    Snapshot* header = reinterpret_cast<Snapshot*>(stream_.buffer());
    header->set_magic();
    header->set_length(stream_.bytes_written());
    header->set_kind(kind);
  }

  void FreeBuffer() {
    dealloc_(stream_.buffer());
    stream_.set_buffer(NULL);
  }

 private:
  uint8_t* buffer_;
  WriteStream stream_;
  DeAlloc dealloc_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BaseWriter);
};

class ForwardList {
 public:
  explicit ForwardList(Thread* thread, intptr_t first_object_id);
  ~ForwardList();

  class Node : public ZoneAllocated {
   public:
    Node(const Object* obj, SerializeState state) : obj_(obj), state_(state) {}
    const Object* obj() const { return obj_; }
    bool is_serialized() const { return state_ == kIsSerialized; }

   private:
    // Private to ensure the invariant of first_unprocessed_object_id_.
    void set_state(SerializeState value) { state_ = value; }

    const Object* obj_;
    SerializeState state_;

    friend class ForwardList;
    DISALLOW_COPY_AND_ASSIGN(Node);
  };

  Node* NodeForObjectId(intptr_t object_id) const {
    return nodes_[object_id - first_object_id_];
  }

  // Returns the id for the added object.
  intptr_t AddObject(Zone* zone, RawObject* raw, SerializeState state);

  // Returns the id for the object it it exists in the list.
  intptr_t FindObject(RawObject* raw);

  // Exhaustively processes all unserialized objects in this list. 'writer' may
  // concurrently add more objects.
  void SerializeAll(ObjectVisitor* writer);

  // Set state of object in forward list.
  void SetState(intptr_t object_id, SerializeState state) {
    NodeForObjectId(object_id)->set_state(state);
  }

 private:
  intptr_t first_object_id() const { return first_object_id_; }
  intptr_t next_object_id() const { return nodes_.length() + first_object_id_; }
  Heap* heap() const { return thread_->isolate()->heap(); }

  Thread* thread_;
  const intptr_t first_object_id_;
  GrowableArray<Node*> nodes_;
  intptr_t first_unprocessed_object_id_;

  DISALLOW_COPY_AND_ASSIGN(ForwardList);
};

class SnapshotWriter : public BaseWriter {
 protected:
  SnapshotWriter(Thread* thread,
                 Snapshot::Kind kind,
                 ReAlloc alloc,
                 DeAlloc dealloc,
                 intptr_t initial_size,
                 ForwardList* forward_list,
                 bool can_send_any_object);

 public:
  // Snapshot kind.
  Snapshot::Kind kind() const { return kind_; }
  Thread* thread() const { return thread_; }
  Zone* zone() const { return thread_->zone(); }
  Isolate* isolate() const { return thread_->isolate(); }
  Heap* heap() const { return isolate()->heap(); }

  // Serialize an object into the buffer.
  void WriteObject(RawObject* raw);

  static uint32_t GetObjectTags(RawObject* raw);
  static uword GetObjectTagsAndHash(RawObject* raw);

  Exceptions::ExceptionType exception_type() const { return exception_type_; }
  void set_exception_type(Exceptions::ExceptionType type) {
    exception_type_ = type;
  }
  const char* exception_msg() const { return exception_msg_; }
  void set_exception_msg(const char* msg) { exception_msg_ = msg; }
  bool can_send_any_object() const { return can_send_any_object_; }
  void ThrowException(Exceptions::ExceptionType type, const char* msg);

  // Write a version string for the snapshot.
  void WriteVersionAndFeatures();

  RawFunction* IsSerializableClosure(RawClosure* closure);

  void WriteStaticImplicitClosure(intptr_t object_id,
                                  RawFunction* func,
                                  intptr_t tags);

 protected:
  bool CheckAndWritePredefinedObject(RawObject* raw);
  bool HandleVMIsolateObject(RawObject* raw);

  void WriteClassId(RawClass* cls);
  void WriteObjectImpl(RawObject* raw, bool as_reference);
  void WriteMarkedObjectImpl(RawObject* raw,
                             intptr_t tags,
                             intptr_t object_id,
                             bool as_reference);
  void WriteForwardedObjects();
  void ArrayWriteTo(intptr_t object_id,
                    intptr_t array_kind,
                    intptr_t tags,
                    RawSmi* length,
                    RawTypeArguments* type_arguments,
                    RawObject* data[],
                    bool as_reference);
  RawClass* GetFunctionOwner(RawFunction* func);
  void CheckForNativeFields(RawClass* cls);
  void SetWriteException(Exceptions::ExceptionType type, const char* msg);
  void WriteInstance(RawObject* raw,
                     RawClass* cls,
                     intptr_t tags,
                     intptr_t object_id,
                     bool as_reference);
  bool AllowObjectsInDartLibrary(RawLibrary* library);
  intptr_t FindVmSnapshotObject(RawObject* rawobj);

  ObjectStore* object_store() const { return object_store_; }

 private:
  Thread* thread_;
  Snapshot::Kind kind_;
  ObjectStore* object_store_;  // Object store for common classes.
  ClassTable* class_table_;  // Class table for the class index to class lookup.
  ForwardList* forward_list_;
  Exceptions::ExceptionType exception_type_;  // Exception type.
  const char* exception_msg_;  // Message associated with exception.
  bool can_send_any_object_;   // True if any Dart instance can be sent.

  friend class RawArray;
  friend class RawClass;
  friend class RawClosureData;
  friend class RawCode;
  friend class RawContextScope;
  friend class RawDynamicLibrary;
  friend class RawExceptionHandlers;
  friend class RawField;
  friend class RawFunction;
  friend class RawGrowableObjectArray;
  friend class RawImmutableArray;
  friend class RawInstructions;
  friend class RawLibrary;
  friend class RawLinkedHashMap;
  friend class RawLocalVarDescriptors;
  friend class RawMirrorReference;
  friend class RawObjectPool;
  friend class RawPointer;
  friend class RawReceivePort;
  friend class RawRegExp;
  friend class RawScript;
  friend class RawStackTrace;
  friend class RawSubtypeTestCache;
  friend class RawTransferableTypedData;
  friend class RawType;
  friend class RawTypeArguments;
  friend class RawTypeParameter;
  friend class RawTypeRef;
  friend class RawTypedDataView;
  friend class RawUserTag;
  friend class SnapshotWriterVisitor;
  friend class WriteInlinedObjectVisitor;
  DISALLOW_COPY_AND_ASSIGN(SnapshotWriter);
};

class SerializedObjectBuffer : public StackResource {
 public:
  SerializedObjectBuffer()
      : StackResource(Thread::Current()), message_(nullptr) {}

  void set_message(std::unique_ptr<Message> message) {
    ASSERT(message_ == nullptr);
    message_ = std::move(message);
  }
  std::unique_ptr<Message> StealMessage() { return std::move(message_); }

 private:
  std::unique_ptr<Message> message_;
};

class MessageWriter : public SnapshotWriter {
 public:
  static const intptr_t kInitialSize = 512;
  explicit MessageWriter(bool can_send_any_object);
  ~MessageWriter();

  std::unique_ptr<Message> WriteMessage(const Object& obj,
                                        Dart_Port dest_port,
                                        Message::Priority priority);

  MessageFinalizableData* finalizable_data() const { return finalizable_data_; }

 private:
  ForwardList forward_list_;
  MessageFinalizableData* finalizable_data_;

  DISALLOW_COPY_AND_ASSIGN(MessageWriter);
};

// An object pointer visitor implementation which writes out
// objects to a snap shot.
class SnapshotWriterVisitor : public ObjectPointerVisitor {
 public:
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

#endif  // RUNTIME_VM_SNAPSHOT_H_
