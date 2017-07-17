// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLUSTERED_SNAPSHOT_H_
#define RUNTIME_VM_CLUSTERED_SNAPSHOT_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/datastream.h"
#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/snapshot.h"
#include "vm/version.h"
#include "vm/visitor.h"

#if defined(DEBUG)
#define SNAPSHOT_BACKTRACE
#endif

namespace dart {

// Forward declarations.
class Serializer;
class Deserializer;
class ObjectStore;

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
  virtual ~SerializationCluster() {}

  // Add [object] to the cluster and push its outgoing references.
  virtual void Trace(Serializer* serializer, RawObject* object) = 0;

  // Write the cluster type and information needed to allocate the cluster's
  // objects. For fixed sized objects, this is just the object count. For
  // variable sized objects, this is the object count and length of each object.
  virtual void WriteAlloc(Serializer* serializer) = 0;

  // Write the byte and reference data of the cluster's objects.
  virtual void WriteFill(Serializer* serializer) = 0;
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
             ImageWriter* image_writer_);
  ~Serializer();

  intptr_t WriteVMSnapshot(const Array& symbols, const Array& scripts);
  void WriteIsolateSnapshot(intptr_t num_base_objects,
                            ObjectStore* object_store);

  void AddVMIsolateBaseObjects();

  void AddBaseObject(RawObject* base_object) {
    AssignRef(base_object);
    num_base_objects_++;
  }

  void AssignRef(RawObject* object) {
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
    next_ref_index_++;
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
    stream_.set_current(stream_.buffer() + Snapshot::kHeaderSize);
  }

  void FillHeader(Snapshot::Kind kind) {
    int64_t* data = reinterpret_cast<int64_t*>(stream_.buffer());
    data[Snapshot::kLengthIndex] = stream_.bytes_written();
    data[Snapshot::kSnapshotFlagIndex] = kind;
  }

  void WriteVersionAndFeatures();

  void Serialize();
  WriteStream* stream() { return &stream_; }
  intptr_t bytes_written() { return stream_.bytes_written(); }

  // Writes raw data to the stream (basic type).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  void Write(T value) {
    WriteStream::Raw<sizeof(T), T>::Write(&stream_, value);
  }

  void WriteBytes(const uint8_t* addr, intptr_t len) {
    stream_.WriteBytes(addr, len);
  }

  void WriteRef(RawObject* object) {
    if (!object->IsHeapObject()) {
      RawSmi* smi = Smi::RawCast(object);
      intptr_t id = smi_ids_.Lookup(smi)->id_;
      if (id == 0) {
        FATAL("Missing ref");
      }
      Write<int32_t>(id);
      return;
    }

    // The object id weak table holds image offsets for Instructions instead
    // of ref indices.
    ASSERT(!object->IsInstructions());
    intptr_t id = heap_->GetObjectId(object);
    if (id == 0) {
      if (object->IsCode() && !Snapshot::IncludesCode(kind_)) {
        WriteRef(Object::null());
        return;
      }
      if (object->IsSendPort()) {
        // TODO(rmacnak): Do a better job of resetting fields in precompilation
        // and assert this is unreachable.
        WriteRef(Object::null());
        return;
      }
      FATAL("Missing ref");
    }
    Write<int32_t>(id);
  }

  void WriteTokenPosition(TokenPosition pos) {
    Write<int32_t>(pos.SnapshotEncode());
  }

  void WriteCid(intptr_t cid) {
    COMPILE_ASSERT(RawObject::kClassIdTagSize <= 32);
    Write<int32_t>(cid);
  }

  int32_t GetTextOffset(RawInstructions* instr, RawCode* code) {
    intptr_t offset = heap_->GetObjectId(instr);
    if (offset == 0) {
      offset = image_writer_->GetTextOffsetFor(instr, code);
      ASSERT(offset != 0);
      heap_->SetObjectId(instr, offset);
    }
    return offset;
  }

  int32_t GetDataOffset(RawObject* object) {
    return image_writer_->GetDataOffsetFor(object);
  }

  Snapshot::Kind kind() const { return kind_; }

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

#if defined(SNAPSHOT_BACKTRACE)
  RawObject* current_parent_;
  GrowableArray<Object*> parent_pairs_;
#endif

  DISALLOW_IMPLICIT_CONSTRUCTORS(Serializer);
};

class Deserializer : public StackResource {
 public:
  Deserializer(Thread* thread,
               Snapshot::Kind kind,
               const uint8_t* buffer,
               intptr_t size,
               const uint8_t* instructions_buffer,
               const uint8_t* data_buffer);
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

  void ReadBytes(uint8_t* addr, intptr_t len) { stream_.ReadBytes(addr, len); }

  const uint8_t* CurrentBufferAddress() const {
    return stream_.AddressOfCurrentPosition();
  }

  void Advance(intptr_t value) { stream_.Advance(value); }

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

  RawObject* ReadRef() {
    int32_t index = Read<int32_t>();
    return Ref(index);
  }

  TokenPosition ReadTokenPosition() {
    return TokenPosition::SnapshotDecode(Read<int32_t>());
  }

  intptr_t ReadCid() {
    COMPILE_ASSERT(RawObject::kClassIdTagSize <= 32);
    return Read<int32_t>();
  }

  RawInstructions* GetInstructionsAt(int32_t offset) {
    return image_reader_->GetInstructionsAt(offset);
  }

  RawObject* GetObjectAt(int32_t offset) {
    return image_reader_->GetObjectAt(offset);
  }

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
  Array& token_streams_;
  Array& saved_symbol_table_;
  Array& new_vm_symbol_table_;

  // Stats for benchmarking.
  intptr_t clustered_vm_size_;
  intptr_t clustered_isolate_size_;
  intptr_t mapped_data_size_;
  intptr_t mapped_instructions_size_;

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
  Snapshot::Kind kind_;
  Thread* thread_;
  const uint8_t* buffer_;
  intptr_t size_;
  const uint8_t* instructions_buffer_;
  const uint8_t* data_buffer_;

  DISALLOW_COPY_AND_ASSIGN(FullSnapshotReader);
};

}  // namespace dart

#endif  // RUNTIME_VM_CLUSTERED_SNAPSHOT_H_
