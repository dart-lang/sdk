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

// Forward declarations.
class Serializer;
class Deserializer;
class ObjectStore;
class ImageWriter;
class ImageReader;

class LoadingUnitSerializationData : public ZoneAllocated {
 public:
  LoadingUnitSerializationData(intptr_t id,
                               LoadingUnitSerializationData* parent)
      : id_(id), parent_(parent), deferred_objects_(), objects_(nullptr) {}

  intptr_t id() const { return id_; }
  LoadingUnitSerializationData* parent() const { return parent_; }
  void AddDeferredObject(CodePtr obj) {
    deferred_objects_.Add(&Code::ZoneHandle(obj));
  }
  GrowableArray<Code*>* deferred_objects() { return &deferred_objects_; }
  ZoneGrowableArray<Object*>* objects() {
    ASSERT(objects_ != nullptr);
    return objects_;
  }
  void set_objects(ZoneGrowableArray<Object*>* objects) {
    ASSERT(objects_ == nullptr);
    objects_ = objects;
  }

 private:
  intptr_t id_;
  LoadingUnitSerializationData* parent_;
  GrowableArray<Code*> deferred_objects_;
  ZoneGrowableArray<Object*>* objects_;
};

class SerializationCluster : public ZoneAllocated {
 public:
  explicit SerializationCluster(const char* name)
      : name_(name), size_(0), num_objects_(0) {}
  virtual ~SerializationCluster() {}

  // Add [object] to the cluster and push its outgoing references.
  virtual void Trace(Serializer* serializer, ObjectPtr object) = 0;

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
  explicit DeserializationCluster(const char* name)
      : name_(name), start_index_(-1), stop_index_(-1) {}
  virtual ~DeserializationCluster() {}

  // Allocate memory for all objects in the cluster and write their addresses
  // into the ref array. Do not touch this memory.
  virtual void ReadAlloc(Deserializer* deserializer, bool is_canonical) = 0;

  // Initialize the cluster's objects. Do not touch the memory of other objects.
  virtual void ReadFill(Deserializer* deserializer, bool is_canonical) = 0;

  // Complete any action that requires the full graph to be deserialized, such
  // as rehashing.
  virtual void PostLoad(Deserializer* deserializer,
                        const Array& refs,
                        bool is_canonical) {}

  const char* name() const { return name_; }

 protected:
  const char* name_;
  // The range of the ref array that belongs to this cluster.
  intptr_t start_index_;
  intptr_t stop_index_;
};

class SerializationRoots {
 public:
  virtual ~SerializationRoots() {}
  virtual void AddBaseObjects(Serializer* serializer) = 0;
  virtual void PushRoots(Serializer* serializer) = 0;
  virtual void WriteRoots(Serializer* serializer) = 0;
};

class DeserializationRoots {
 public:
  virtual ~DeserializationRoots() {}
  virtual void AddBaseObjects(Deserializer* deserializer) = 0;
  virtual void ReadRoots(Deserializer* deserializer) = 0;
  virtual void PostLoad(Deserializer* deserializer, const Array& refs) = 0;
};

// Reference value for objects that either are not reachable from the roots or
// should never have a reference in the snapshot (because they are dropped,
// for example). Should be the default value for Heap::GetObjectId.
static constexpr intptr_t kUnreachableReference = 0;
COMPILE_ASSERT(kUnreachableReference == WeakTable::kNoValue);
static constexpr intptr_t kFirstReference = 1;

// Reference value for traced objects that have not been allocated their final
// reference ID.
static const intptr_t kUnallocatedReference = -1;

static constexpr bool IsAllocatedReference(intptr_t ref) {
  return ref > kUnreachableReference;
}

static constexpr bool IsArtificialReference(intptr_t ref) {
  return ref < kUnallocatedReference;
}

static constexpr bool IsReachableReference(intptr_t ref) {
  return ref == kUnallocatedReference || IsAllocatedReference(ref);
}

class Serializer : public ThreadStackResource {
 public:
  Serializer(Thread* thread,
             Snapshot::Kind kind,
             NonStreamingWriteStream* stream,
             ImageWriter* image_writer_,
             bool vm_,
             V8SnapshotProfileWriter* profile_writer = nullptr);
  ~Serializer();

  void AddBaseObject(ObjectPtr base_object,
                     const char* type = nullptr,
                     const char* name = nullptr);
  intptr_t AssignRef(ObjectPtr object);
  intptr_t AssignArtificialRef(ObjectPtr object);

  void Push(ObjectPtr object);

  void AddUntracedRef() { num_written_objects_++; }

  void Trace(ObjectPtr object);

  void UnexpectedObject(ObjectPtr object, const char* message);
#if defined(SNAPSHOT_BACKTRACE)
  ObjectPtr ParentOf(const Object& object);
#endif

  SerializationCluster* NewClusterForClass(intptr_t cid);

  void ReserveHeader() {
    // Make room for recording snapshot buffer size.
    stream_->SetPosition(Snapshot::kHeaderSize);
  }

  void FillHeader(Snapshot::Kind kind) {
    Snapshot* header = reinterpret_cast<Snapshot*>(stream_->buffer());
    header->set_magic();
    header->set_length(stream_->bytes_written());
    header->set_kind(kind);
  }

  void WriteVersionAndFeatures(bool is_vm_snapshot);

  ZoneGrowableArray<Object*>* Serialize(SerializationRoots* roots);
  void PrintSnapshotSizes();

  FieldTable* initial_field_table() const { return initial_field_table_; }

  NonStreamingWriteStream* stream() { return stream_; }
  intptr_t bytes_written() { return stream_->bytes_written(); }

  void FlushBytesWrittenToRoot();
  void TraceStartWritingObject(const char* type, ObjectPtr obj, StringPtr name);
  void TraceStartWritingObject(const char* type,
                               ObjectPtr obj,
                               const char* name);
  void TraceEndWritingObject();

  // Writes raw data to the stream (basic type).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  void Write(T value) {
    BaseWriteStream::Raw<sizeof(T), T>::Write(stream_, value);
  }
  void WriteUnsigned(intptr_t value) { stream_->WriteUnsigned(value); }
  void WriteUnsigned64(uint64_t value) { stream_->WriteUnsigned(value); }

  void WriteWordWith32BitWrites(uword value) {
    stream_->WriteWordWith32BitWrites(value);
  }

  void WriteBytes(const uint8_t* addr, intptr_t len) {
    stream_->WriteBytes(addr, len);
  }
  void Align(intptr_t alignment) { stream_->Align(alignment); }

  void WriteRootRef(ObjectPtr object, const char* name = nullptr) {
    intptr_t id = RefId(object);
    WriteUnsigned(id);
    if (profile_writer_ != nullptr) {
      profile_writer_->AddRoot({V8SnapshotProfileWriter::kSnapshot, id}, name);
    }
  }

  void WriteElementRef(ObjectPtr object, intptr_t index) {
    WriteUnsigned(AttributeElementRef(object, index));
  }

  // Record a reference from the currently written object to the given object
  // and return reference id for the given object.
  intptr_t AttributeElementRef(ObjectPtr object,
                               intptr_t index,
                               bool permit_artificial_ref = false) {
    intptr_t id = RefId(object, permit_artificial_ref);
    if (profile_writer_ != nullptr) {
      profile_writer_->AttributeReferenceTo(
          {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_.id_},
          {{V8SnapshotProfileWriter::kSnapshot, id},
           V8SnapshotProfileWriter::Reference::kElement,
           index});
    }
    return id;
  }

  void WritePropertyRef(ObjectPtr object, const char* property) {
    WriteUnsigned(AttributePropertyRef(object, property));
  }

  // Record a reference from the currently written object to the given object
  // and return reference id for the given object.
  intptr_t AttributePropertyRef(ObjectPtr object,
                                const char* property,
                                bool permit_artificial_ref = false) {
    intptr_t id = RefId(object, permit_artificial_ref);
    if (profile_writer_ != nullptr) {
      profile_writer_->AttributeReferenceTo(
          {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_.id_},
          {{V8SnapshotProfileWriter::kSnapshot, id},
           V8SnapshotProfileWriter::Reference::kProperty,
           profile_writer_->EnsureString(property)});
    }
    return id;
  }

  void WriteOffsetRef(ObjectPtr object, intptr_t offset) {
    intptr_t id = RefId(object);
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
  void WriteFromTo(T obj, P&&... args) {
    ObjectPtr* from = obj->ptr()->from();
    ObjectPtr* to = obj->ptr()->to_snapshot(kind(), args...);
    for (ObjectPtr* p = from; p <= to; p++) {
      WriteOffsetRef(*p, (p - reinterpret_cast<ObjectPtr*>(obj->ptr())) *
                             sizeof(ObjectPtr));
    }
  }

  template <typename T, typename... P>
  void PushFromTo(T obj, P&&... args) {
    ObjectPtr* from = obj->ptr()->from();
    ObjectPtr* to = obj->ptr()->to_snapshot(kind(), args...);
    for (ObjectPtr* p = from; p <= to; p++) {
      Push(*p);
    }
  }

  void WriteTokenPosition(TokenPosition pos) { Write(pos.Serialize()); }

  void WriteCid(intptr_t cid) {
    COMPILE_ASSERT(ObjectLayout::kClassIdTagSize <= 32);
    Write<int32_t>(cid);
  }

  void PrepareInstructions(GrowableArray<CodePtr>* codes);
  void WriteInstructions(InstructionsPtr instr,
                         uint32_t unchecked_offset,
                         CodePtr code,
                         bool deferred);
  uint32_t GetDataOffset(ObjectPtr object) const;
  void TraceDataOffset(uint32_t offset);
  intptr_t GetDataSize() const;

  void WriteDispatchTable(const Array& entries);

  Heap* heap() const { return heap_; }
  Zone* zone() const { return zone_; }
  Snapshot::Kind kind() const { return kind_; }
  intptr_t next_ref_index() const { return next_ref_index_; }

  void DumpCombinedCodeStatistics();

  V8SnapshotProfileWriter* profile_writer() const { return profile_writer_; }

  // If the given [obj] was not included into the snaposhot and have not
  // yet gotten an artificial node created for it create an artificial node
  // in the profile representing this object.
  // Returns true if [obj] has an artificial profile node associated with it.
  bool CreateArtificalNodeIfNeeded(ObjectPtr obj);

  bool InCurrentLoadingUnit(ObjectPtr obj, bool record = false);
  GrowableArray<LoadingUnitSerializationData*>* loading_units() {
    return loading_units_;
  }
  void set_loading_units(GrowableArray<LoadingUnitSerializationData*>* units) {
    loading_units_ = units;
  }
  void set_current_loading_unit_id(intptr_t id) {
    current_loading_unit_id_ = id;
  }

  // Returns the reference ID for the object. Fails for objects that have not
  // been allocated a reference ID yet, so should be used only after all
  // WriteAlloc calls.
  intptr_t RefId(ObjectPtr object, bool permit_artificial_ref = false) {
    // The object id weak table holds image offsets for Instructions instead
    // of ref indices.
    ASSERT(!object->IsHeapObject() || !object->IsInstructions());
    auto const id = heap_->GetObjectId(object);
    if (permit_artificial_ref && IsArtificialReference(id)) {
      return -id;
    }
    ASSERT(!IsArtificialReference(id));
    if (IsAllocatedReference(id)) return id;
    if (object->IsWeakSerializationReference()) {
      // If a reachable WSR has an object ID of 0, then its target was marked
      // for serialization due to reachable strong references and the WSR will
      // be dropped instead. Thus, we change the reference to the WSR to a
      // direct reference to the serialized target.
      auto const ref = WeakSerializationReference::RawCast(object);
      auto const target = WeakSerializationReference::TargetOf(ref);
      auto const target_id = heap_->GetObjectId(target);
      ASSERT(IsAllocatedReference(target_id));
      return target_id;
    }
    if (object->IsCode() && !Snapshot::IncludesCode(kind_)) {
      return RefId(Object::null());
    }
    FATAL("Missing ref");
  }

 private:
  const char* ReadOnlyObjectType(intptr_t cid);

  Heap* heap_;
  Zone* zone_;
  Snapshot::Kind kind_;
  NonStreamingWriteStream* stream_;
  ImageWriter* image_writer_;
  SerializationCluster** canonical_clusters_by_cid_;
  SerializationCluster** clusters_by_cid_;
  GrowableArray<ObjectPtr> stack_;
  intptr_t num_cids_;
  intptr_t num_tlc_cids_;
  intptr_t num_base_objects_;
  intptr_t num_written_objects_;
  intptr_t next_ref_index_;
  intptr_t previous_text_offset_;
  FieldTable* initial_field_table_;

  intptr_t dispatch_table_size_ = 0;

  // True if writing VM snapshot, false for Isolate snapshot.
  bool vm_;

  V8SnapshotProfileWriter* profile_writer_ = nullptr;
  struct ProfilingObject {
    ObjectPtr object_ = nullptr;
    intptr_t id_ = 0;
    intptr_t stream_start_ = 0;
    intptr_t cid_ = -1;
  } object_currently_writing_;
  OffsetsTable* offsets_table_ = nullptr;

#if defined(SNAPSHOT_BACKTRACE)
  ObjectPtr current_parent_;
  GrowableArray<Object*> parent_pairs_;
#endif

#if defined(DART_PRECOMPILER)
  IntMap<intptr_t> deduped_instructions_sources_;
#endif

  intptr_t current_loading_unit_id_ = 0;
  GrowableArray<LoadingUnitSerializationData*>* loading_units_ = nullptr;
  ZoneGrowableArray<Object*>* objects_ = new ZoneGrowableArray<Object*>();

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

class SerializerWritingObjectScope {
 public:
  SerializerWritingObjectScope(Serializer* serializer,
                               const char* type,
                               ObjectPtr object,
                               StringPtr name)
      : serializer_(serializer) {
    serializer_->TraceStartWritingObject(type, object, name);
  }

  SerializerWritingObjectScope(Serializer* serializer,
                               const char* type,
                               ObjectPtr object,
                               const char* name)
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
  static bool NullSafetyFromSnapshot(const Snapshot* snapshot);

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
               bool is_non_root_unit,
               intptr_t offset = 0);
  ~Deserializer();

  // Verifies the image alignment.
  //
  // Returns ApiError::null() on success and an ApiError with an an appropriate
  // message otherwise.
  ApiErrorPtr VerifyImageAlignment();

  static void InitializeHeader(ObjectPtr raw,
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

  void AddBaseObject(ObjectPtr base_object) { AssignRef(base_object); }

  void AssignRef(ObjectPtr object) {
    ASSERT(next_ref_index_ <= num_objects_);
    refs_->ptr()->data()[next_ref_index_] = object;
    next_ref_index_++;
  }

  ObjectPtr Ref(intptr_t index) const {
    ASSERT(index > 0);
    ASSERT(index <= num_objects_);
    return refs_->ptr()->data()[index];
  }

  ObjectPtr ReadRef() { return Ref(ReadUnsigned()); }

  template <typename T, typename... P>
  void ReadFromTo(T obj, P&&... params) {
    ObjectPtr* from = obj->ptr()->from();
    ObjectPtr* to_snapshot = obj->ptr()->to_snapshot(kind(), params...);
    ObjectPtr* to = obj->ptr()->to(params...);
    for (ObjectPtr* p = from; p <= to_snapshot; p++) {
      *p = ReadRef();
    }
    // This is necessary because, unlike Object::Allocate, the clustered
    // deserializer allocates object without null-initializing them. Instead,
    // each deserialization cluster is responsible for initializing every field,
    // ensuring that every field is written to exactly once.
    for (ObjectPtr* p = to_snapshot + 1; p <= to; p++) {
      *p = Object::null();
    }
  }

  TokenPosition ReadTokenPosition() {
    return TokenPosition::Deserialize(Read<int32_t>());
  }

  intptr_t ReadCid() {
    COMPILE_ASSERT(ObjectLayout::kClassIdTagSize <= 32);
    return Read<int32_t>();
  }

  void ReadInstructions(CodePtr code, bool deferred);
  void EndInstructions(const Array& refs,
                       intptr_t start_index,
                       intptr_t stop_index);
  ObjectPtr GetObjectAt(uint32_t offset) const;

  void Deserialize(DeserializationRoots* roots);

  DeserializationCluster* ReadCluster();

  void ReadDispatchTable() { ReadDispatchTable(&stream_); }
  void ReadDispatchTable(ReadStream* stream);

  intptr_t next_index() const { return next_ref_index_; }
  Heap* heap() const { return heap_; }
  Zone* zone() const { return zone_; }
  Snapshot::Kind kind() const { return kind_; }
  FieldTable* initial_field_table() const { return initial_field_table_; }

 private:
  Heap* heap_;
  Zone* zone_;
  Snapshot::Kind kind_;
  ReadStream stream_;
  ImageReader* image_reader_;
  intptr_t num_base_objects_;
  intptr_t num_objects_;
  intptr_t num_canonical_clusters_;
  intptr_t num_clusters_;
  ArrayPtr refs_;
  intptr_t next_ref_index_;
  intptr_t previous_text_offset_;
  DeserializationCluster** canonical_clusters_;
  DeserializationCluster** clusters_;
  FieldTable* initial_field_table_;
  const bool is_non_root_unit_;
};

#define ReadFromTo(obj, ...) d->ReadFromTo(obj, ##__VA_ARGS__);

class FullSnapshotWriter {
 public:
  static const intptr_t kInitialSize = 64 * KB;
  FullSnapshotWriter(Snapshot::Kind kind,
                     NonStreamingWriteStream* vm_snapshot_data,
                     NonStreamingWriteStream* isolate_snapshot_data,
                     ImageWriter* vm_image_writer,
                     ImageWriter* iso_image_writer);
  ~FullSnapshotWriter();

  Thread* thread() const { return thread_; }
  Zone* zone() const { return thread_->zone(); }
  Isolate* isolate() const { return thread_->isolate(); }
  Heap* heap() const { return isolate()->heap(); }

  // Writes a full snapshot of the program(VM isolate, regular isolate group).
  void WriteFullSnapshot(
      GrowableArray<LoadingUnitSerializationData*>* data = nullptr);
  void WriteUnitSnapshot(GrowableArray<LoadingUnitSerializationData*>* units,
                         LoadingUnitSerializationData* unit,
                         uint32_t program_hash);

  intptr_t VmIsolateSnapshotSize() const { return vm_isolate_snapshot_size_; }
  intptr_t IsolateSnapshotSize() const { return isolate_snapshot_size_; }

 private:
  // Writes a snapshot of the VM Isolate.
  ZoneGrowableArray<Object*>* WriteVMSnapshot();

  // Writes a full snapshot of regular Dart isolate group.
  void WriteProgramSnapshot(ZoneGrowableArray<Object*>* objects,
                            GrowableArray<LoadingUnitSerializationData*>* data);

  Thread* thread_;
  Snapshot::Kind kind_;
  NonStreamingWriteStream* const vm_snapshot_data_;
  NonStreamingWriteStream* const isolate_snapshot_data_;
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

  ApiErrorPtr ReadVMSnapshot();
  ApiErrorPtr ReadProgramSnapshot();
  ApiErrorPtr ReadUnitSnapshot(const LoadingUnit& unit);

 private:
  ApiErrorPtr ConvertToApiError(char* message);
  void PatchGlobalObjectPool();
  void InitializeBSS();

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
