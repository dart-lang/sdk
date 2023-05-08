// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_APP_SNAPSHOT_H_
#define RUNTIME_VM_APP_SNAPSHOT_H_

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
#include "vm/version.h"

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
  static constexpr intptr_t kSizeVaries = -1;
  explicit SerializationCluster(const char* name,
                                intptr_t cid,
                                intptr_t target_instance_size = kSizeVaries,
                                bool is_canonical = false)
      : name_(name),
        cid_(cid),
        target_instance_size_(target_instance_size),
        is_canonical_(is_canonical) {
    ASSERT(target_instance_size == kSizeVaries || target_instance_size >= 0);
  }
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
  intptr_t cid() const { return cid_; }
  bool is_canonical() const { return is_canonical_; }
  intptr_t size() const { return size_; }
  intptr_t num_objects() const { return num_objects_; }

  // Returns number of bytes needed for deserialized objects in
  // this cluster. Printed in --print_snapshot_sizes_verbose statistics.
  //
  // In order to calculate this size, clusters of fixed-size objects
  // can pass instance size as [target_instance_size] constructor parameter.
  // Otherwise clusters should count [target_memory_size] in
  // their [WriteAlloc] methods.
  intptr_t target_memory_size() const { return target_memory_size_; }

 protected:
  const char* const name_;
  const intptr_t cid_;
  const intptr_t target_instance_size_;
  const bool is_canonical_;
  intptr_t size_ = 0;
  intptr_t num_objects_ = 0;
  intptr_t target_memory_size_ = 0;
};

class DeserializationCluster : public ZoneAllocated {
 public:
  explicit DeserializationCluster(const char* name, bool is_canonical = false)
      : name_(name),
        is_canonical_(is_canonical),
        start_index_(-1),
        stop_index_(-1) {}
  virtual ~DeserializationCluster() {}

  // Allocate memory for all objects in the cluster and write their addresses
  // into the ref array. Do not touch this memory.
  virtual void ReadAlloc(Deserializer* deserializer) = 0;

  // Initialize the cluster's objects. Do not touch the memory of other objects.
  virtual void ReadFill(Deserializer* deserializer, bool primary) = 0;

  // Complete any action that requires the full graph to be deserialized, such
  // as rehashing.
  virtual void PostLoad(Deserializer* deserializer,
                        const Array& refs,
                        bool primary) {
    if (!primary && is_canonical()) {
      FATAL("%s needs canonicalization but doesn't define PostLoad", name());
    }
  }

  const char* name() const { return name_; }
  bool is_canonical() const { return is_canonical_; }

 protected:
  void ReadAllocFixedSize(Deserializer* deserializer, intptr_t instance_size);

  const char* const name_;
  const bool is_canonical_;
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

  virtual const CompressedStackMaps& canonicalized_stack_map_entries() const;
};

class DeserializationRoots {
 public:
  virtual ~DeserializationRoots() {}
  // Returns true if these roots are the first snapshot loaded into a heap, and
  // so can assume any canonical objects don't already exist. Returns false if
  // some other snapshot may be loaded before these roots, and so written
  // canonical objects need to run canonicalization during load.
  virtual bool AddBaseObjects(Deserializer* deserializer) = 0;
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
static constexpr intptr_t kUnallocatedReference = -1;

static constexpr bool IsAllocatedReference(intptr_t ref) {
  return ref > kUnreachableReference;
}

static constexpr bool IsArtificialReference(intptr_t ref) {
  return ref < kUnallocatedReference;
}

static constexpr bool IsReachableReference(intptr_t ref) {
  return ref == kUnallocatedReference || IsAllocatedReference(ref);
}

class CodeSerializationCluster;

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
  intptr_t AssignArtificialRef(ObjectPtr object = nullptr);

  intptr_t GetCodeIndex(CodePtr code);

  void Push(ObjectPtr object, intptr_t cid_override = kIllegalCid);
  void PushWeak(ObjectPtr object);

  void AddUntracedRef() { num_written_objects_++; }

  void Trace(ObjectPtr object, intptr_t cid_override);

  void UnexpectedObject(ObjectPtr object, const char* message);
#if defined(SNAPSHOT_BACKTRACE)
  ObjectPtr ParentOf(ObjectPtr object) const;
  ObjectPtr ParentOf(const Object& object) const;
#endif

  SerializationCluster* NewClusterForClass(intptr_t cid, bool is_canonical);

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

  NonStreamingWriteStream* stream() { return stream_; }
  intptr_t bytes_written() { return stream_->bytes_written(); }
  intptr_t bytes_heap_allocated() { return bytes_heap_allocated_; }

  class WritingObjectScope : ValueObject {
   public:
    WritingObjectScope(Serializer* serializer,
                       const char* type,
                       ObjectPtr object,
                       StringPtr name)
        : WritingObjectScope(
              serializer,
              ReserveId(serializer,
                        type,
                        object,
                        String::ToCString(serializer->thread(), name)),
              object) {}

    WritingObjectScope(Serializer* serializer,
                       const char* type,
                       ObjectPtr object,
                       const char* name)
        : WritingObjectScope(serializer,
                             ReserveId(serializer, type, object, name),
                             object) {}

    WritingObjectScope(Serializer* serializer,
                       const V8SnapshotProfileWriter::ObjectId& id,
                       ObjectPtr object = nullptr);

    WritingObjectScope(Serializer* serializer, ObjectPtr object)
        : WritingObjectScope(serializer,
                             serializer->GetProfileId(object),
                             object) {}

    ~WritingObjectScope();

   private:
    static V8SnapshotProfileWriter::ObjectId ReserveId(Serializer* serializer,
                                                       const char* type,
                                                       ObjectPtr object,
                                                       const char* name);

   private:
    Serializer* const serializer_;
    const ObjectPtr old_object_;
    const V8SnapshotProfileWriter::ObjectId old_id_;
    const classid_t old_cid_;
  };

  // Writes raw data to the stream (basic type).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  void Write(T value) {
    BaseWriteStream::Raw<sizeof(T), T>::Write(stream_, value);
  }
  void WriteRefId(intptr_t value) {
    stream_->WriteRefId(value);
  }
  void WriteUnsigned(intptr_t value) { stream_->WriteUnsigned(value); }
  void WriteUnsigned64(uint64_t value) { stream_->WriteUnsigned(value); }

  void WriteWordWith32BitWrites(uword value) {
    stream_->WriteWordWith32BitWrites(value);
  }

  void WriteBytes(const uint8_t* addr, intptr_t len) {
    stream_->WriteBytes(addr, len);
  }
  void Align(intptr_t alignment, intptr_t offset = 0) {
    stream_->Align(alignment, offset);
  }

  V8SnapshotProfileWriter::ObjectId GetProfileId(ObjectPtr object) const;
  V8SnapshotProfileWriter::ObjectId GetProfileId(intptr_t ref) const;

  void WriteRootRef(ObjectPtr object, const char* name = nullptr) {
    intptr_t id = RefId(object);
    WriteRefId(id);
    if (profile_writer_ != nullptr) {
      profile_writer_->AddRoot(GetProfileId(object), name);
    }
  }

  // Record a reference from the currently written object to the given object
  // and return reference id for the given object.
  void AttributeReference(ObjectPtr object,
                          const V8SnapshotProfileWriter::Reference& reference);

  void AttributeElementRef(ObjectPtr object, intptr_t index) {
    AttributeReference(object,
                       V8SnapshotProfileWriter::Reference::Element(index));
  }

  void WriteElementRef(ObjectPtr object, intptr_t index) {
    AttributeElementRef(object, index);
    WriteRefId(RefId(object));
  }

  void AttributePropertyRef(ObjectPtr object, const char* property) {
    AttributeReference(object,
                       V8SnapshotProfileWriter::Reference::Property(property));
  }

  void WritePropertyRef(ObjectPtr object, const char* property) {
    AttributePropertyRef(object, property);
    WriteRefId(RefId(object));
  }

  void WriteOffsetRef(ObjectPtr object, intptr_t offset) {
    intptr_t id = RefId(object);
    WriteRefId(id);
    if (profile_writer_ != nullptr) {
      if (auto const property = offsets_table_->FieldNameForOffset(
              object_currently_writing_.cid_, offset)) {
        AttributePropertyRef(object, property);
      } else {
        AttributeElementRef(object, offset);
      }
    }
  }

  template <typename T, typename... P>
  void WriteFromTo(T obj, P&&... args) {
    auto* from = obj->untag()->from();
    auto* to = obj->untag()->to_snapshot(kind(), args...);
    WriteRange(obj, from, to);
  }

  template <typename T>
  DART_NOINLINE void WriteRange(ObjectPtr obj, T from, T to) {
    for (auto* p = from; p <= to; p++) {
      WriteOffsetRef(
          p->Decompress(obj->heap_base()),
          reinterpret_cast<uword>(p) - reinterpret_cast<uword>(obj->untag()));
    }
  }

  template <typename T, typename... P>
  void PushFromTo(T obj, P&&... args) {
    auto* from = obj->untag()->from();
    auto* to = obj->untag()->to_snapshot(kind(), args...);
    PushRange(obj, from, to);
  }

  template <typename T>
  DART_NOINLINE void PushRange(ObjectPtr obj, T from, T to) {
    for (auto* p = from; p <= to; p++) {
      Push(p->Decompress(obj->heap_base()));
    }
  }

  void WriteTokenPosition(TokenPosition pos) { Write(pos.Serialize()); }

  void WriteCid(intptr_t cid) {
    COMPILE_ASSERT(UntaggedObject::kClassIdTagSize <= 32);
    Write<int32_t>(cid);
  }

  // Sorts Code objects and reorders instructions before writing snapshot.
  // Builds binary search table for stack maps.
  void PrepareInstructions(const CompressedStackMaps& canonical_smap);

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

  // If the given [obj] was not included into the snapshot and have not
  // yet gotten an artificial node created for it create an artificial node
  // in the profile representing this object.
  // Returns true if [obj] has an artificial profile node associated with it.
  bool CreateArtificialNodeIfNeeded(ObjectPtr obj);

  bool InCurrentLoadingUnitOrRoot(ObjectPtr obj);
  void RecordDeferredCode(CodePtr ptr);
  GrowableArray<LoadingUnitSerializationData*>* loading_units() const {
    return loading_units_;
  }
  void set_loading_units(GrowableArray<LoadingUnitSerializationData*>* units) {
    loading_units_ = units;
  }
  intptr_t current_loading_unit_id() const { return current_loading_unit_id_; }
  void set_current_loading_unit_id(intptr_t id) {
    current_loading_unit_id_ = id;
  }

  // Returns the reference ID for the object. Fails for objects that have not
  // been allocated a reference ID yet, so should be used only after all
  // WriteAlloc calls.
  intptr_t RefId(ObjectPtr object) const;

  // Same as RefId, but allows artificial and unreachable references. Still
  // fails for unallocated references.
  intptr_t UnsafeRefId(ObjectPtr object) const;

  // Whether the object is reachable.
  bool IsReachable(ObjectPtr object) const {
    return IsReachableReference(heap_->GetObjectId(object));
  }
  // Whether the object has an allocated reference.
  bool HasRef(ObjectPtr object) const {
    return IsAllocatedReference(heap_->GetObjectId(object));
  }
  // Whether the object only appears in the V8 snapshot profile.
  bool HasArtificialRef(ObjectPtr object) const {
    return IsArtificialReference(heap_->GetObjectId(object));
  }
  // Whether a node for the object already has been added to the V8 snapshot
  // profile.
  bool HasProfileNode(ObjectPtr object) const {
    ASSERT(profile_writer_ != nullptr);
    return profile_writer_->HasId(GetProfileId(object));
  }
  bool IsWritten(ObjectPtr object) const {
    return heap_->GetObjectId(object) > num_base_objects_;
  }

 private:
  const char* ReadOnlyObjectType(intptr_t cid);
  void FlushProfile();

  Heap* heap_;
  Zone* zone_;
  Snapshot::Kind kind_;
  NonStreamingWriteStream* stream_;
  ImageWriter* image_writer_;
  SerializationCluster** canonical_clusters_by_cid_;
  SerializationCluster** clusters_by_cid_;
  CodeSerializationCluster* code_cluster_ = nullptr;

  struct StackEntry {
    ObjectPtr obj;
    intptr_t cid_override;
  };
  GrowableArray<StackEntry> stack_;

  intptr_t num_cids_;
  intptr_t num_tlc_cids_;
  intptr_t num_base_objects_;
  intptr_t num_written_objects_;
  intptr_t next_ref_index_;

  intptr_t dispatch_table_size_ = 0;
  intptr_t bytes_heap_allocated_ = 0;
  intptr_t instructions_table_len_ = 0;
  intptr_t instructions_table_rodata_offset_ = 0;

  // True if writing VM snapshot, false for Isolate snapshot.
  bool vm_;

  V8SnapshotProfileWriter* profile_writer_ = nullptr;
  struct ProfilingObject {
    ObjectPtr object_ = nullptr;
    // Unless within a WritingObjectScope, any bytes written are attributed to
    // the artificial root.
    V8SnapshotProfileWriter::ObjectId id_ =
        V8SnapshotProfileWriter::kArtificialRootId;
    intptr_t last_stream_position_ = 0;
    intptr_t cid_ = -1;
  } object_currently_writing_;
  OffsetsTable* offsets_table_ = nullptr;

#if defined(SNAPSHOT_BACKTRACE)
  ObjectPtr current_parent_;
  GrowableArray<Object*> parent_pairs_;
#endif

#if defined(DART_PRECOMPILER)
  IntMap<intptr_t> deduped_instructions_sources_;
  IntMap<intptr_t> code_index_;
#endif

  intptr_t current_loading_unit_id_ = 0;
  GrowableArray<LoadingUnitSerializationData*>* loading_units_ = nullptr;
  ZoneGrowableArray<Object*>* objects_ = new ZoneGrowableArray<Object*>();

  DISALLOW_IMPLICIT_CONSTRUCTORS(Serializer);
};

#define AutoTraceObject(obj)                                                   \
  Serializer::WritingObjectScope scope_##__COUNTER__(s, name(), obj, nullptr)

#define AutoTraceObjectName(obj, str)                                          \
  Serializer::WritingObjectScope scope_##__COUNTER__(s, name(), obj, str)

#define WriteFieldValue(field, value) s->WritePropertyRef(value, #field);

#define WriteFromTo(obj, ...) s->WriteFromTo(obj, ##__VA_ARGS__);

#define PushFromTo(obj, ...) s->PushFromTo(obj, ##__VA_ARGS__);

#define WriteField(obj, field) s->WritePropertyRef(obj->untag()->field, #field)
#define WriteCompressedField(obj, name)                                        \
  s->WritePropertyRef(obj->untag()->name(), #name "_")

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
  char* VerifyVersionAndFeatures(IsolateGroup* isolate_group, intptr_t* offset);

 private:
  char* VerifyVersion();
  char* ReadFeatures(const char** features, intptr_t* features_length);
  char* VerifyFeatures(IsolateGroup* isolate_group);
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
  intptr_t ReadRefId() { return stream_.ReadRefId(); }
  intptr_t ReadUnsigned() { return stream_.ReadUnsigned(); }
  uint64_t ReadUnsigned64() { return stream_.ReadUnsigned<uint64_t>(); }
  void ReadBytes(uint8_t* addr, intptr_t len) { stream_.ReadBytes(addr, len); }

  uword ReadWordWith32BitReads() { return stream_.ReadWordWith32BitReads(); }

  intptr_t position() const { return stream_.Position(); }
  void set_position(intptr_t p) { stream_.SetPosition(p); }
  const uint8_t* AddressOfCurrentPosition() const {
    return stream_.AddressOfCurrentPosition();
  }

  void Advance(intptr_t value) { stream_.Advance(value); }
  void Align(intptr_t alignment, intptr_t offset = 0) {
    stream_.Align(alignment, offset);
  }

  void AddBaseObject(ObjectPtr base_object) { AssignRef(base_object); }

  void AssignRef(ObjectPtr object) {
    ASSERT(next_ref_index_ <= num_objects_);
    refs_->untag()->data()[next_ref_index_] = object;
    next_ref_index_++;
  }

  ObjectPtr Ref(intptr_t index) const {
    ASSERT(index > 0);
    ASSERT(index <= num_objects_);
    return refs_->untag()->element(index);
  }

  CodePtr GetCodeByIndex(intptr_t code_index, uword* entry_point) const;
  uword GetEntryPointByCodeIndex(intptr_t code_index) const;

  // If |code_index| corresponds to a non-discarded Code object returns
  // index within the code cluster that corresponds to this Code object.
  // Otherwise, if |code_index| corresponds to the discarded Code then
  // returns -1.
  static intptr_t CodeIndexToClusterIndex(const InstructionsTable& table,
                                          intptr_t code_index);

  ObjectPtr ReadRef() { return Ref(ReadRefId()); }

  TokenPosition ReadTokenPosition() {
    return TokenPosition::Deserialize(Read<int32_t>());
  }

  intptr_t ReadCid() {
    COMPILE_ASSERT(UntaggedObject::kClassIdTagSize <= 32);
    return Read<int32_t>();
  }

  void ReadInstructions(CodePtr code, bool deferred);
  void EndInstructions();
  ObjectPtr GetObjectAt(uint32_t offset) const;

  void Deserialize(DeserializationRoots* roots);

  DeserializationCluster* ReadCluster();

  void ReadDispatchTable() {
    ReadDispatchTable(&stream_, /*deferred=*/false, InstructionsTable::Handle(),
                      -1, -1);
  }
  void ReadDispatchTable(ReadStream* stream,
                         bool deferred,
                         const InstructionsTable& root_instruction_table,
                         intptr_t deferred_code_start_index,
                         intptr_t deferred_code_end_index);

  intptr_t next_index() const { return next_ref_index_; }
  Heap* heap() const { return heap_; }
  Zone* zone() const { return zone_; }
  Snapshot::Kind kind() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return Snapshot::kFullAOT;
#else
    return kind_;
#endif
  }
  bool is_non_root_unit() const { return is_non_root_unit_; }
  void set_code_start_index(intptr_t value) { code_start_index_ = value; }
  intptr_t code_start_index() const { return code_start_index_; }
  void set_code_stop_index(intptr_t value) { code_stop_index_ = value; }
  intptr_t code_stop_index() const { return code_stop_index_; }
  const InstructionsTable& instructions_table() const {
    return instructions_table_;
  }
  intptr_t num_base_objects() const { return num_base_objects_; }

  // This serves to make the snapshot cursor, ref table and null be locals
  // during ReadFill, which allows the C compiler to see they are not aliased
  // and can be kept in registers.
  class Local : public ReadStream {
   public:
    explicit Local(Deserializer* d)
        : ReadStream(d->stream_.buffer_, d->stream_.current_, d->stream_.end_),
          d_(d),
          refs_(d->refs_),
          null_(Object::null()) {
#if defined(DEBUG)
      // Can't mix use of Deserializer::Read*.
      d->stream_.current_ = nullptr;
#endif
    }
    ~Local() {
      d_->stream_.current_ = current_;
    }

    ObjectPtr Ref(intptr_t index) const {
      ASSERT(index > 0);
      ASSERT(index <= d_->num_objects_);
      return refs_->untag()->element(index);
    }

    template <typename T>
    T Read() {
      return ReadStream::Raw<sizeof(T), T>::Read(this);
    }
    uint64_t ReadUnsigned64() {
      return ReadUnsigned<uint64_t>();
    }

    ObjectPtr ReadRef() {
      return Ref(ReadRefId());
    }
    TokenPosition ReadTokenPosition() {
      return TokenPosition::Deserialize(Read<int32_t>());
    }

    intptr_t ReadCid() {
      COMPILE_ASSERT(UntaggedObject::kClassIdTagSize <= 32);
      return Read<int32_t>();
    }

    template <typename T, typename... P>
    void ReadFromTo(T obj, P&&... params) {
      auto* from = obj->untag()->from();
      auto* to_snapshot = obj->untag()->to_snapshot(d_->kind(), params...);
      auto* to = obj->untag()->to(params...);
      for (auto* p = from; p <= to_snapshot; p++) {
        *p = ReadRef();
      }
      // This is necessary because, unlike Object::Allocate, the clustered
      // deserializer allocates object without null-initializing them. Instead,
      // each deserialization cluster is responsible for initializing every
      // field, ensuring that every field is written to exactly once.
      for (auto* p = to_snapshot + 1; p <= to; p++) {
        *p = null_;
      }
    }

   private:
    Deserializer* const d_;
    const ArrayPtr refs_;
    const ObjectPtr null_;
  };

 private:
  Heap* heap_;
  Zone* zone_;
  Snapshot::Kind kind_;
  ReadStream stream_;
  ImageReader* image_reader_;
  intptr_t num_base_objects_;
  intptr_t num_objects_;
  intptr_t num_clusters_;
  ArrayPtr refs_;
  intptr_t next_ref_index_;
  intptr_t code_start_index_ = 0;
  intptr_t code_stop_index_ = 0;
  intptr_t instructions_index_ = 0;
  DeserializationCluster** clusters_;
  const bool is_non_root_unit_;
  InstructionsTable& instructions_table_;
};

class FullSnapshotWriter {
 public:
  static constexpr intptr_t kInitialSize = 64 * KB;
  FullSnapshotWriter(Snapshot::Kind kind,
                     NonStreamingWriteStream* vm_snapshot_data,
                     NonStreamingWriteStream* isolate_snapshot_data,
                     ImageWriter* vm_image_writer,
                     ImageWriter* iso_image_writer);
  ~FullSnapshotWriter();

  Thread* thread() const { return thread_; }
  Zone* zone() const { return thread_->zone(); }
  IsolateGroup* isolate_group() const { return thread_->isolate_group(); }
  Heap* heap() const { return isolate_group()->heap(); }

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
  intptr_t clustered_vm_size_ = 0;
  intptr_t clustered_isolate_size_ = 0;
  intptr_t mapped_data_size_ = 0;
  intptr_t mapped_text_size_ = 0;
  intptr_t heap_vm_size_ = 0;
  intptr_t heap_isolate_size_ = 0;

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
  IsolateGroup* isolate_group() const { return thread_->isolate_group(); }

  ApiErrorPtr ConvertToApiError(char* message);
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

#endif  // RUNTIME_VM_APP_SNAPSHOT_H_
