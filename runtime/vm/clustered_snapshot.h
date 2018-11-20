// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLUSTERED_SNAPSHOT_H_
#define RUNTIME_VM_CLUSTERED_SNAPSHOT_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/datastream.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/heap/heap.h"
#include "vm/object.h"
#include "vm/snapshot.h"
#include "vm/type_testing_stubs.h"
#include "vm/v8_snapshot_writer.h"
#include "vm/version.h"

#if defined(DEBUG)
#define SNAPSHOT_BACKTRACE
#endif

namespace dart {

// Forward declarations.
class Serializer;
class Deserializer;
class ObjectStore;
class ImageWriter;
class ImageReader;

// For full snapshots, we use a clustered snapshot format that trades longer
// serialization time for faster deserialization time and smaller snapshots.
// Objects are clustered by class to allow writing type information once per
// class instead once per object, and to allow filling the objects in a tight
// loop. The snapshot has two major sections: the first describes how to
// allocate the objects and the second describes how to initialize them.
// Deserialization starts by allocating a reference array large enough to hold
// the base objects (objects already available to both the serializer and
// deserializer) and the objects written in the snapshot. The allocation section
// is then read for each cluster, filling the reference array. Then the
// initialization/fill secton is read for each cluster, using the indices into
// the reference array to fill pointers. At this point, every object has been
// touched exactly once and in order, making this approach very cache friendly.
// Finally, each cluster is given an opportunity to perform some fix-ups that
// require the graph has been fully loaded, such as rehashing, though most
// clusters do not require fixups.

class SerializationCluster : public ZoneAllocated {
 public:
  explicit SerializationCluster(const char* name)
      : name_(name), size_(0), num_objects_(0) {}
  virtual ~SerializationCluster() {}

  // Add [object] to the cluster and push its outgoing references.
  virtual void Trace(Serializer* serializer, RawObject* object) = 0;

  // Write the cluster type and information needed to allocate the cluster's
  // objects. For fixed sized objects, this is just the object count. For
  // variable sized objects, this is the object count and length of each object.
  virtual void WriteAlloc(Serializer* serializer) = 0;

  // Write the byte and reference data of the cluster's objects.
  virtual void WriteFill(Serializer* serializer) = 0;

  void WriteAndMeasureAlloc(Serializer* serializer);
  void WriteAndMeasureFill(Serializer* serializer);

  const char* name() const { return name_; }
  intptr_t size() const { return size_; }
  intptr_t num_objects() const { return num_objects_; }

 protected:
  const char* name_;
  intptr_t size_;
  intptr_t num_objects_;
};

class DeserializationCluster : public ZoneAllocated {
 public:
  DeserializationCluster() : start_index_(-1), stop_index_(-1) {}
  virtual ~DeserializationCluster() {}

  // Allocate memory for all objects in the cluster and write their addresses
  // into the ref array. Do not touch this memory.
  virtual void ReadAlloc(Deserializer* deserializer) = 0;

  // Initialize the cluster's objects. Do not touch the memory of other objects.
  virtual void ReadFill(Deserializer* deserializer) = 0;

  // Complete any action that requires the full graph to be deserialized, such
  // as rehashing.
  virtual void PostLoad(const Array& refs, Snapshot::Kind kind, Zone* zone) {}

 protected:
  // The range of the ref array that belongs to this cluster.
  intptr_t start_index_;
  intptr_t stop_index_;
};

class SmiObjectIdPair {
 public:
  SmiObjectIdPair() : smi_(NULL), id_(0) {}
  RawSmi* smi_;
  intptr_t id_;

  bool operator==(const SmiObjectIdPair& other) const {
    return (smi_ == other.smi_) && (id_ == other.id_);
  }
};

class SmiObjectIdPairTrait {
 public:
  typedef RawSmi* Key;
  typedef intptr_t Value;
  typedef SmiObjectIdPair Pair;

  static Key KeyOf(Pair kv) { return kv.smi_; }
  static Value ValueOf(Pair kv) { return kv.id_; }
  static inline intptr_t Hashcode(Key key) { return Smi::Value(key); }
  static inline bool IsKeyEqual(Pair kv, Key key) { return kv.smi_ == key; }
};

typedef DirectChainedHashMap<SmiObjectIdPairTrait> SmiObjectIdMap;

class Serializer : public StackResource {
 public:
  Serializer(Thread* thread,
             Snapshot::Kind kind,
             uint8_t** buffer,
             ReAlloc alloc,
             intptr_t initial_size,
             ImageWriter* image_writer_,
             bool vm_,
             V8SnapshotProfileWriter* profile_writer = nullptr);
  ~Serializer();

  intptr_t WriteVMSnapshot(const Array& symbols,
                           ZoneGrowableArray<Object*>* seeds);
  void WriteIsolateSnapshot(intptr_t num_base_objects,
                            ObjectStore* object_store);

  void AddVMIsolateBaseObjects();

  void AddBaseObject(RawObject* base_object,
                     const char* type = nullptr,
                     const char* name = nullptr) {
    intptr_t ref = AssignRef(base_object);
    num_base_objects_++;

    if (profile_writer_ != nullptr) {
      if (type == nullptr) {
        type = "Unknown";
      }
      if (name == nullptr) {
        name = "<base object>";
      }
      profile_writer_->SetObjectTypeAndName(
          {V8SnapshotProfileWriter::kSnapshot, ref}, type, name);
      profile_writer_->AddRoot({V8SnapshotProfileWriter::kSnapshot, ref});
    }
  }

  intptr_t AssignRef(RawObject* object) {
    ASSERT(next_ref_index_ != 0);
    if (object->IsHeapObject()) {
      // The object id weak table holds image offsets for Instructions instead
      // of ref indices.
      ASSERT(!object->IsInstructions());
      heap_->SetObjectId(object, next_ref_index_);
      ASSERT(heap_->GetObjectId(object) == next_ref_index_);
    } else {
      RawSmi* smi = Smi::RawCast(object);
      SmiObjectIdPair* existing_pair = smi_ids_.Lookup(smi);
      if (existing_pair != NULL) {
        ASSERT(existing_pair->id_ == 1);
        existing_pair->id_ = next_ref_index_;
      } else {
        SmiObjectIdPair new_pair;
        new_pair.smi_ = smi;
        new_pair.id_ = next_ref_index_;
        smi_ids_.Insert(new_pair);
      }
    }
    return next_ref_index_++;
  }

  void Push(RawObject* object);

  void AddUntracedRef() { num_written_objects_++; }

  void Trace(RawObject* object);

  void UnexpectedObject(RawObject* object, const char* message);
#if defined(SNAPSHOT_BACKTRACE)
  RawObject* ParentOf(const Object& object);
#endif

  SerializationCluster* NewClusterForClass(intptr_t cid);

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

  void WriteVersionAndFeatures(bool is_vm_snapshot);

  void Serialize();
  WriteStream* stream() { return &stream_; }
  intptr_t bytes_written() { return stream_.bytes_written(); }

  void TraceStartWritingObject(const char* type,
                               RawObject* obj,
                               RawString* name);
  void TraceEndWritingObject();

  // Writes raw data to the stream (basic type).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  void Write(T value) {
    WriteStream::Raw<sizeof(T), T>::Write(&stream_, value);
  }
  void WriteUnsigned(intptr_t value) { stream_.WriteUnsigned(value); }
  void WriteBytes(const uint8_t* addr, intptr_t len) {
    stream_.WriteBytes(addr, len);
  }
  void Align(intptr_t alignment) { stream_.Align(alignment); }

  void WriteRef(RawObject* object, bool is_root = false) {
    intptr_t id = 0;
    if (!object->IsHeapObject()) {
      RawSmi* smi = Smi::RawCast(object);
      id = smi_ids_.Lookup(smi)->id_;
      if (id == 0) {
        FATAL("Missing ref");
      }
    } else {
      // The object id weak table holds image offsets for Instructions instead
      // of ref indices.
      ASSERT(!object->IsInstructions());
      id = heap_->GetObjectId(object);
      if (id == 0) {
        if (object->IsCode() && !Snapshot::IncludesCode(kind_)) {
          WriteRef(Object::null());
          return;
        }
#if !defined(DART_PRECOMPILED_RUNTIME)
        if (object->IsBytecode() && !Snapshot::IncludesBytecode(kind_)) {
          WriteRef(Object::null());
          return;
        }
#endif  // !DART_PRECOMPILED_RUNTIME
        if (object->IsSendPort()) {
          // TODO(rmacnak): Do a better job of resetting fields in
          // precompilation and assert this is unreachable.
          WriteRef(Object::null());
          return;
        }
        FATAL("Missing ref");
      }
    }

    WriteUnsigned(id);

    if (profile_writer_ != nullptr) {
      if (object_currently_writing_id_ != 0) {
        profile_writer_->AttributeReferenceTo(
            {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_id_},
            {V8SnapshotProfileWriter::kSnapshot, id});
      } else {
        ASSERT(is_root);
        profile_writer_->AddRoot({V8SnapshotProfileWriter::kSnapshot, id});
      }
    }
  }

  void WriteRootRef(RawObject* object) {
    WriteRef(object, /* is_root = */ true);
  }

  void WriteTokenPosition(TokenPosition pos) {
    Write<int32_t>(pos.SnapshotEncode());
  }

  void WriteCid(intptr_t cid) {
    COMPILE_ASSERT(RawObject::kClassIdTagSize <= 32);
    Write<int32_t>(cid);
  }

  void WriteInstructions(RawInstructions* instr, RawCode* code);
  bool GetSharedDataOffset(RawObject* object, uint32_t* offset) const;
  uint32_t GetDataOffset(RawObject* object) const;
  void TraceDataOffset(uint32_t offset);
  intptr_t GetDataSize() const;
  intptr_t GetTextSize() const;

  Snapshot::Kind kind() const { return kind_; }
  intptr_t next_ref_index() const { return next_ref_index_; }

  void DumpCombinedCodeStatistics();

 private:
  TypeTestingStubFinder type_testing_stubs_;
  Heap* heap_;
  Zone* zone_;
  Snapshot::Kind kind_;
  WriteStream stream_;
  ImageWriter* image_writer_;
  SerializationCluster** clusters_by_cid_;
  GrowableArray<RawObject*> stack_;
  intptr_t num_cids_;
  intptr_t num_base_objects_;
  intptr_t num_written_objects_;
  intptr_t next_ref_index_;
  SmiObjectIdMap smi_ids_;

  // True if writing VM snapshot, false for Isolate snapshot.
  bool vm_;

  V8SnapshotProfileWriter* profile_writer_ = nullptr;
  intptr_t object_currently_writing_id_ = 0;
  intptr_t object_currently_writing_start_ = 0;

#if defined(SNAPSHOT_BACKTRACE)
  RawObject* current_parent_;
  GrowableArray<Object*> parent_pairs_;
#endif

  DISALLOW_IMPLICIT_CONSTRUCTORS(Serializer);
};

struct SerializerWritingObjectScope {
  SerializerWritingObjectScope(Serializer* serializer,
                               const char* type,
                               RawObject* object,
                               RawString* name)
      : serializer_(serializer) {
    serializer_->TraceStartWritingObject(type, object, name);
  }

  ~SerializerWritingObjectScope() { serializer_->TraceEndWritingObject(); }

 private:
  Serializer* serializer_;
};

#define AutoTraceObject(obj)                                                   \
  SerializerWritingObjectScope scope_##__COUNTER__(s, name(), obj, nullptr)

#define AutoTraceObjectName(obj, str)                                          \
  SerializerWritingObjectScope scope_##__COUNTER__(s, name(), obj, str)

class Deserializer : public StackResource {
 public:
  Deserializer(Thread* thread,
               Snapshot::Kind kind,
               const uint8_t* buffer,
               intptr_t size,
               const uint8_t* data_buffer,
               const uint8_t* instructions_buffer,
               const uint8_t* shared_data_buffer,
               const uint8_t* shared_instructions_buffer);
  ~Deserializer();

  void ReadIsolateSnapshot(ObjectStore* object_store);
  void ReadVMSnapshot();

  void AddVMIsolateBaseObjects();

  static void InitializeHeader(RawObject* raw,
                               intptr_t cid,
                               intptr_t size,
                               bool is_vm_isolate,
                               bool is_canonical = false);

  // Reads raw data (for basic types).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  T Read() {
    return ReadStream::Raw<sizeof(T), T>::Read(&stream_);
  }
  intptr_t ReadUnsigned() { return stream_.ReadUnsigned(); }
  void ReadBytes(uint8_t* addr, intptr_t len) { stream_.ReadBytes(addr, len); }

  const uint8_t* CurrentBufferAddress() const {
    return stream_.AddressOfCurrentPosition();
  }

  void Advance(intptr_t value) { stream_.Advance(value); }
  void Align(intptr_t alignment) { stream_.Align(alignment); }

  intptr_t PendingBytes() const { return stream_.PendingBytes(); }

  void AddBaseObject(RawObject* base_object) { AssignRef(base_object); }

  void AssignRef(RawObject* object) {
    ASSERT(next_ref_index_ <= num_objects_);
    refs_->ptr()->data()[next_ref_index_] = object;
    next_ref_index_++;
  }

  RawObject* Ref(intptr_t index) const {
    ASSERT(index > 0);
    ASSERT(index <= num_objects_);
    return refs_->ptr()->data()[index];
  }

  RawObject* ReadRef() { return Ref(ReadUnsigned()); }

  TokenPosition ReadTokenPosition() {
    return TokenPosition::SnapshotDecode(Read<int32_t>());
  }

  intptr_t ReadCid() {
    COMPILE_ASSERT(RawObject::kClassIdTagSize <= 32);
    return Read<int32_t>();
  }

  RawInstructions* ReadInstructions();
  RawObject* GetObjectAt(uint32_t offset) const;
  RawObject* GetSharedObjectAt(uint32_t offset) const;

  void SkipHeader() { stream_.SetPosition(Snapshot::kHeaderSize); }

  RawApiError* VerifyVersionAndFeatures(Isolate* isolate);

  void Prepare();
  void Deserialize();

  DeserializationCluster* ReadCluster();

  intptr_t next_index() const { return next_ref_index_; }
  Heap* heap() const { return heap_; }
  Snapshot::Kind kind() const { return kind_; }

 private:
  Heap* heap_;
  Zone* zone_;
  Snapshot::Kind kind_;
  ReadStream stream_;
  ImageReader* image_reader_;
  intptr_t num_base_objects_;
  intptr_t num_objects_;
  intptr_t num_clusters_;
  RawArray* refs_;
  intptr_t next_ref_index_;
  DeserializationCluster** clusters_;
};

class FullSnapshotWriter {
 public:
  static const intptr_t kInitialSize = 64 * KB;
  FullSnapshotWriter(Snapshot::Kind kind,
                     uint8_t** vm_snapshot_data_buffer,
                     uint8_t** isolate_snapshot_data_buffer,
                     ReAlloc alloc,
                     ImageWriter* vm_image_writer,
                     ImageWriter* iso_image_writer);
  ~FullSnapshotWriter();

  uint8_t** vm_snapshot_data_buffer() const { return vm_snapshot_data_buffer_; }

  uint8_t** isolate_snapshot_data_buffer() const {
    return isolate_snapshot_data_buffer_;
  }

  Thread* thread() const { return thread_; }
  Zone* zone() const { return thread_->zone(); }
  Isolate* isolate() const { return thread_->isolate(); }
  Heap* heap() const { return isolate()->heap(); }

  // Writes a full snapshot of the Isolate.
  void WriteFullSnapshot();

  intptr_t VmIsolateSnapshotSize() const { return vm_isolate_snapshot_size_; }
  intptr_t IsolateSnapshotSize() const { return isolate_snapshot_size_; }

 private:
  // Writes a snapshot of the VM Isolate.
  intptr_t WriteVMSnapshot();

  // Writes a full snapshot of a regular Dart Isolate.
  void WriteIsolateSnapshot(intptr_t num_base_objects);

  Thread* thread_;
  Snapshot::Kind kind_;
  uint8_t** vm_snapshot_data_buffer_;
  uint8_t** isolate_snapshot_data_buffer_;
  ReAlloc alloc_;
  intptr_t vm_isolate_snapshot_size_;
  intptr_t isolate_snapshot_size_;
  ForwardList* forward_list_;
  ImageWriter* vm_image_writer_;
  ImageWriter* isolate_image_writer_;
  ZoneGrowableArray<Object*>* seeds_;
  Array& saved_symbol_table_;
  Array& new_vm_symbol_table_;

  // Stats for benchmarking.
  intptr_t clustered_vm_size_;
  intptr_t clustered_isolate_size_;
  intptr_t mapped_data_size_;
  intptr_t mapped_text_size_;

  V8SnapshotProfileWriter* profile_writer_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(FullSnapshotWriter);
};

class FullSnapshotReader {
 public:
  FullSnapshotReader(const Snapshot* snapshot,
                     const uint8_t* instructions_buffer,
                     const uint8_t* shared_data,
                     const uint8_t* shared_instructions,
                     Thread* thread);
  ~FullSnapshotReader() {}

  RawApiError* ReadVMSnapshot();
  RawApiError* ReadIsolateSnapshot();

 private:
  Snapshot::Kind kind_;
  Thread* thread_;
  const uint8_t* buffer_;
  intptr_t size_;
  const uint8_t* data_image_;
  const uint8_t* instructions_image_;
  const uint8_t* shared_data_image_;
  const uint8_t* shared_instructions_image_;

  DISALLOW_COPY_AND_ASSIGN(FullSnapshotReader);
};

}  // namespace dart

#endif  // RUNTIME_VM_CLUSTERED_SNAPSHOT_H_
