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
#include "vm/image_snapshot.h"
#include "vm/object.h"
#include "vm/raw_object_fields.h"
#include "vm/snapshot.h"
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

class Serializer : public ThreadStackResource {
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

  intptr_t WriteVMSnapshot(const Array& symbols);
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
  void PrintSnapshotSizes();

  FieldTable* field_table() { return field_table_; }

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
  void WriteUnsigned64(uint64_t value) { stream_.WriteUnsigned(value); }

  void WriteWordWith32BitWrites(uword value) {
    stream_.WriteWordWith32BitWrites(value);
  }

  void WriteBytes(const uint8_t* addr, intptr_t len) {
    stream_.WriteBytes(addr, len);
  }
  void Align(intptr_t alignment) { stream_.Align(alignment); }

 private:
  intptr_t WriteRefId(RawObject* object) {
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
          return WriteRefId(Object::null());
        }
#if !defined(DART_PRECOMPILED_RUNTIME)
        if (object->IsBytecode() && !Snapshot::IncludesBytecode(kind_)) {
          return WriteRefId(Object::null());
        }
#endif  // !DART_PRECOMPILED_RUNTIME
        FATAL("Missing ref");
      }
    }
    return id;
  }

 public:
  void WriteRootRef(RawObject* object) {
    intptr_t id = WriteRefId(object);
    WriteUnsigned(id);
    if (profile_writer_ != nullptr) {
      profile_writer_->AddRoot({V8SnapshotProfileWriter::kSnapshot, id});
    }
  }

  void WriteElementRef(RawObject* object, intptr_t index) {
    intptr_t id = WriteRefId(object);
    WriteUnsigned(id);
    if (profile_writer_ != nullptr) {
      profile_writer_->AttributeReferenceTo(
          {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_.id_},
          {{V8SnapshotProfileWriter::kSnapshot, id},
           V8SnapshotProfileWriter::Reference::kElement,
           index});
    }
  }

  void WritePropertyRef(RawObject* object, const char* property) {
    intptr_t id = WriteRefId(object);
    WriteUnsigned(id);
    if (profile_writer_ != nullptr) {
      profile_writer_->AttributeReferenceTo(
          {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_.id_},
          {{V8SnapshotProfileWriter::kSnapshot, id},
           V8SnapshotProfileWriter::Reference::kProperty,
           profile_writer_->EnsureString(property)});
    }
  }

  void WriteOffsetRef(RawObject* object, intptr_t offset) {
    intptr_t id = WriteRefId(object);
    WriteUnsigned(id);
    if (profile_writer_ != nullptr) {
      const char* property = offsets_table_->FieldNameForOffset(
          object_currently_writing_.cid_, offset);
      if (property != nullptr) {
        profile_writer_->AttributeReferenceTo(
            {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_.id_},
            {{V8SnapshotProfileWriter::kSnapshot, id},
             V8SnapshotProfileWriter::Reference::kProperty,
             profile_writer_->EnsureString(property)});
      } else {
        profile_writer_->AttributeReferenceTo(
            {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_.id_},
            {{V8SnapshotProfileWriter::kSnapshot, id},
             V8SnapshotProfileWriter::Reference::kElement,
             offset});
      }
    }
  }

  template <typename T, typename... P>
  void WriteFromTo(T* obj, P&&... args) {
    RawObject** from = obj->from();
    RawObject** to = obj->to_snapshot(kind(), args...);
    for (RawObject** p = from; p <= to; p++) {
      WriteOffsetRef(*p, (p - reinterpret_cast<RawObject**>(obj->ptr())) *
                             sizeof(RawObject*));
    }
  }

  template <typename T, typename... P>
  void PushFromTo(T* obj, P&&... args) {
    RawObject** from = obj->from();
    RawObject** to = obj->to_snapshot(kind(), args...);
    for (RawObject** p = from; p <= to; p++) {
      Push(*p);
    }
  }

  void WriteTokenPosition(TokenPosition pos) {
    Write<int32_t>(pos.SnapshotEncode());
  }

  void WriteCid(intptr_t cid) {
    COMPILE_ASSERT(RawObject::kClassIdTagSize <= 32);
    Write<int32_t>(cid);
  }

  void WriteInstructions(RawInstructions* instr,
                         uint32_t unchecked_offset,
                         RawCode* code,
                         intptr_t index);
  uint32_t GetDataOffset(RawObject* object) const;
  void TraceDataOffset(uint32_t offset);
  intptr_t GetDataSize() const;
  intptr_t GetTextSize() const;

  Snapshot::Kind kind() const { return kind_; }
  intptr_t next_ref_index() const { return next_ref_index_; }

  void DumpCombinedCodeStatistics();

 private:
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
  FieldTable* field_table_;

  intptr_t dispatch_table_size_ = 0;

  // True if writing VM snapshot, false for Isolate snapshot.
  bool vm_;

  V8SnapshotProfileWriter* profile_writer_ = nullptr;
  struct ProfilingObject {
    RawObject* object_ = nullptr;
    intptr_t id_ = 0;
    intptr_t stream_start_ = 0;
    intptr_t cid_ = -1;
  } object_currently_writing_;
  OffsetsTable* offsets_table_ = nullptr;

#if defined(SNAPSHOT_BACKTRACE)
  RawObject* current_parent_;
  GrowableArray<Object*> parent_pairs_;
#endif

#if defined(DART_PRECOMPILER)
  IntMap<intptr_t> deduped_instructions_sources_;
#endif

  DISALLOW_IMPLICIT_CONSTRUCTORS(Serializer);
};

#define AutoTraceObject(obj)                                                   \
  SerializerWritingObjectScope scope_##__COUNTER__(s, name(), obj, nullptr)

#define AutoTraceObjectName(obj, str)                                          \
  SerializerWritingObjectScope scope_##__COUNTER__(s, name(), obj, str)

#define WriteFieldValue(field, value) s->WritePropertyRef(value, #field);

#define WriteFromTo(obj, ...) s->WriteFromTo(obj, ##__VA_ARGS__);

#define PushFromTo(obj, ...) s->PushFromTo(obj, ##__VA_ARGS__);

#define WriteField(obj, field) s->WritePropertyRef(obj->ptr()->field, #field)

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

// This class can be used to read version and features from a snapshot before
// the VM has been initialized.
class SnapshotHeaderReader {
 public:
  static char* InitializeGlobalVMFlagsFromSnapshot(const Snapshot* snapshot);

  explicit SnapshotHeaderReader(const Snapshot* snapshot)
      : SnapshotHeaderReader(snapshot->kind(),
                             snapshot->Addr(),
                             snapshot->length()) {}

  SnapshotHeaderReader(Snapshot::Kind kind,
                       const uint8_t* buffer,
                       intptr_t size)
      : kind_(kind), stream_(buffer, size) {
    stream_.SetPosition(Snapshot::kHeaderSize);
  }

  // Verifies the version and features in the snapshot are compatible with the
  // current VM.  If isolate is non-null it validates isolate-specific features.
  //
  // Returns null on success and a malloc()ed error on failure.
  // The [offset] will be the next position in the snapshot stream after the
  // features.
  char* VerifyVersionAndFeatures(Isolate* isolate, intptr_t* offset);

 private:
  char* VerifyVersion();
  char* ReadFeatures(const char** features, intptr_t* features_length);
  char* VerifyFeatures(Isolate* isolate);
  char* BuildError(const char* message);

  Snapshot::Kind kind_;
  ReadStream stream_;
};

class Deserializer : public ThreadStackResource {
 public:
  Deserializer(Thread* thread,
               Snapshot::Kind kind,
               const uint8_t* buffer,
               intptr_t size,
               const uint8_t* data_buffer,
               const uint8_t* instructions_buffer,
               intptr_t offset = 0);
  ~Deserializer();

  // Verifies the image alignment.
  //
  // Returns ApiError::null() on success and an ApiError with an an appropriate
  // message otherwise.
  RawApiError* VerifyImageAlignment();

  void ReadIsolateSnapshot(ObjectStore* object_store);
  void ReadVMSnapshot();

  void AddVMIsolateBaseObjects();

  static void InitializeHeader(RawObject* raw,
                               intptr_t cid,
                               intptr_t size,
                               bool is_canonical = false);

  // Reads raw data (for basic types).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  T Read() {
    return ReadStream::Raw<sizeof(T), T>::Read(&stream_);
  }
  intptr_t ReadUnsigned() { return stream_.ReadUnsigned(); }
  uint64_t ReadUnsigned64() { return stream_.ReadUnsigned<uint64_t>(); }
  void ReadBytes(uint8_t* addr, intptr_t len) { stream_.ReadBytes(addr, len); }

  uword ReadWordWith32BitReads() { return stream_.ReadWordWith32BitReads(); }

  const uint8_t* CurrentBufferAddress() const {
    return stream_.AddressOfCurrentPosition();
  }

  void Advance(intptr_t value) { stream_.Advance(value); }
  void Align(intptr_t alignment) { stream_.Align(alignment); }

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

  template <typename T, typename... P>
  void ReadFromTo(T* obj, P&&... params) {
    RawObject** from = obj->from();
    RawObject** to_snapshot = obj->to_snapshot(kind(), params...);
    RawObject** to = obj->to(params...);
    for (RawObject** p = from; p <= to_snapshot; p++) {
      *p = ReadRef();
    }
    // This is necessary because, unlike Object::Allocate, the clustered
    // deserializer allocates object without null-initializing them. Instead,
    // each deserialization cluster is responsible for initializing every field,
    // ensuring that every field is written to exactly once.
    for (RawObject** p = to_snapshot + 1; p <= to; p++) {
      *p = Object::null();
    }
  }

  TokenPosition ReadTokenPosition() {
    return TokenPosition::SnapshotDecode(Read<int32_t>());
  }

  intptr_t ReadCid() {
    COMPILE_ASSERT(RawObject::kClassIdTagSize <= 32);
    return Read<int32_t>();
  }

  void ReadInstructions(RawCode* code, intptr_t index, intptr_t start_index);
  RawObject* GetObjectAt(uint32_t offset) const;

  void SkipHeader() { stream_.SetPosition(Snapshot::kHeaderSize); }

  void Prepare();
  void Deserialize();

  DeserializationCluster* ReadCluster();

  intptr_t next_index() const { return next_ref_index_; }
  Heap* heap() const { return heap_; }
  Snapshot::Kind kind() const { return kind_; }
  FieldTable* field_table() const { return field_table_; }

  // The number of code objects which were relocated during AOT snapshot
  // writing.
  //
  // After relocating the instructions in the ".text" segment, the
  // [CodeSerializationCluster] will re-order those code objects that get
  // written out in the cluster.  The order will be dictated by the order of
  // the code's instructions in the ".text" segment.
  //
  // The [code_order_length] represents therefore the prefix of code objects in
  // the written out code cluster. (There might be code objects for which no
  // relocation was performed.)
  //
  // This will be used to construct [ObjectStore::code_order_table].
  intptr_t code_order_length() const { return code_order_length_; }

 private:
  Heap* heap_;
  Zone* zone_;
  Snapshot::Kind kind_;
  ReadStream stream_;
  ImageReader* image_reader_;
  intptr_t num_base_objects_;
  intptr_t num_objects_;
  intptr_t num_clusters_;
  intptr_t code_order_length_ = 0;
  RawArray* refs_;
  intptr_t next_ref_index_;
  DeserializationCluster** clusters_;
  FieldTable* field_table_;
};

#define ReadFromTo(obj, ...) d->ReadFromTo(obj, ##__VA_ARGS__);

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
  ImageWriter* vm_image_writer_;
  ImageWriter* isolate_image_writer_;

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
                     Thread* thread);
  ~FullSnapshotReader() {}

  RawApiError* ReadVMSnapshot();
  RawApiError* ReadIsolateSnapshot();

 private:
  RawApiError* ConvertToApiError(char* message);

  Snapshot::Kind kind_;
  Thread* thread_;
  const uint8_t* buffer_;
  intptr_t size_;
  const uint8_t* data_image_;
  const uint8_t* instructions_image_;

  DISALLOW_COPY_AND_ASSIGN(FullSnapshotReader);
};

}  // namespace dart

#endif  // RUNTIME_VM_CLUSTERED_SNAPSHOT_H_
