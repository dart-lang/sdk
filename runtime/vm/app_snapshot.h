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
#include "vm/object.h"
#include "vm/snapshot.h"

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
class V8SnapshotProfileWriter;
class ImageWriter;
class Heap;

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

class FullSnapshotWriter {
 public:
  static constexpr intptr_t kInitialSize = 64 * KB;
  FullSnapshotWriter(Snapshot::Kind kind,
                     NonStreamingWriteStream* vm_snapshot_data,
                     NonStreamingWriteStream* isolate_snapshot_data,
                     ImageWriter* vm_image_writer,
                     ImageWriter* iso_image_writer);
  ~FullSnapshotWriter();

  // Writes a full snapshot of the program(VM isolate, regular isolate group).
  void WriteFullSnapshot(
      GrowableArray<LoadingUnitSerializationData*>* data = nullptr);
  void WriteUnitSnapshot(GrowableArray<LoadingUnitSerializationData*>* units,
                         LoadingUnitSerializationData* unit,
                         uint32_t program_hash);

  intptr_t VmIsolateSnapshotSize() const { return vm_isolate_snapshot_size_; }
  intptr_t IsolateSnapshotSize() const { return isolate_snapshot_size_; }

 private:
  Thread* thread() const { return thread_; }
  Zone* zone() const { return thread_->zone(); }
  IsolateGroup* isolate_group() const { return thread_->isolate_group(); }
  Heap* heap() const { return isolate_group()->heap(); }

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
