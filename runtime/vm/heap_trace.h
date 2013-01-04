// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_HEAP_TRACE_H_
#define VM_HEAP_TRACE_H_

#include "include/dart_api.h"
#include "vm/globals.h"
#include "vm/object_set.h"

namespace dart {

// Forward declarations.
class HeapTraceVisitor;
class Isolate;
class RawClass;
class RawObject;
class RawString;
class BaseZone;

class HeapTrace {
 public:
  enum RecordSize {
    kRootSize = 5,
    kAllocSize = 9,
    kSnapshotAllocSize = 9,
    kCopySize = 9,
    kStoreSize = 13,
    kSweepSize = 5,
    kDeathRangeSize = 9,
    kPromotionSize = 9,
    kAllocZoneHandleSize = 9,
    kDeleteZoneSize = 5,
    kRegisterClassSize = 5,
    kAllocScopedHandleSize = 5,
    kDeleteScopedHandlesSize = 1,
    kMarkSweepStartSize = 1,
    kMarkSweepFinishSize = 1,
    kObjectStoreSize = 5
  };

  enum RecordType {
    kRootType = 'R',
    kAllocType = 'A',
    kSnapshotAllocType = 'B',
    kCopyType = 'C',
    kStoreType = 'U',
    kSweepType = 'S',
    kDeathRangeType = 'L',
    kPromotionType = 'P',
    kAllocZoneHandleType = 'Z',
    kDeleteZoneType = 'z',
    kRegisterClassType = 'K',
    kAllocScopedHandleType = 'H',
    kDeleteScopedHandlesType = 'h',
    kMarkSweepStartType = '{',
    kMarkSweepFinishType = '}',
    kObjectStoreType = 'O'
  };

  template <RecordType T, RecordSize N>
  class Record {
   public:
    explicit Record(HeapTrace* trace): cursor_(0), trace_(trace) {
      ASSERT(N >= 1);
      buffer_[0] = T;
      ++cursor_;
    }
    ~Record() {
      (*trace_->write_callback_)(Buffer(), Length(), trace_->output_stream_);
    }

    void Write(uword word) {
      ASSERT(cursor_ + sizeof(word) <= N);
      memmove(&buffer_[cursor_], &word, sizeof(word));
      cursor_ += sizeof(word);
    }

    intptr_t Length() const { return cursor_; }

    const uint8_t* Buffer() const {
      ASSERT(cursor_ == N);
      return buffer_;
    }

   private:
    uint8_t buffer_[N];
    intptr_t cursor_;
    HeapTrace* trace_;
    DISALLOW_COPY_AND_ASSIGN(Record);
  };

  typedef Record<kRootType, kRootSize> RootRecord;
  typedef Record<kAllocType, kAllocSize> AllocationRecord;
  typedef Record<kSnapshotAllocType, kSnapshotAllocSize>
  SnapshotAllocationRecord;
  typedef Record<kCopyType, kCopySize> CopyRecord;
  typedef Record<kStoreType, kStoreSize> StoreRecord;
  typedef Record<kSweepType, kSweepSize> SweepRecord;
  typedef Record<kDeathRangeType, kDeathRangeSize> DeathRangeRecord;
  typedef Record<kPromotionType, kPromotionSize> PromotionRecord;
  typedef Record<kAllocZoneHandleType, kAllocZoneHandleSize>
  AllocZoneHandleRecord;
  typedef Record<kDeleteZoneType, kDeleteZoneSize>
  DeleteZoneRecord;
  typedef Record<kRegisterClassType, kRegisterClassSize> RegisterClassRecord;
  typedef Record<kAllocScopedHandleType, kAllocScopedHandleSize>
  AllocScopedHandleRecord;
  typedef Record<kDeleteScopedHandlesType, kDeleteScopedHandlesSize>
  DeleteScopedHandlesRecord;
  typedef Record<kMarkSweepStartType, kMarkSweepStartSize> MarkSweepStartRecord;
  typedef Record<kMarkSweepFinishType, kMarkSweepFinishSize>
  MarkSweepFinishRecord;
  typedef Record<kObjectStoreType, kObjectStoreSize> ObjectStoreRecord;

  HeapTrace();
  ~HeapTrace();

  // Called by the isolate just before EnableGrowthControl.  Indicates
  // the Isolate is initialized and enables tracing.
  void Init(Isolate* isolate);

  // Called when an object is allocated in the heap.
  void TraceAllocation(uword addr, intptr_t size);

  // Invoked after the snapshot is loaded at Isolate startup time.
  void TraceSnapshotAlloc(RawObject* obj, intptr_t size);

  // Rename to something like TraceAllocateZoneHandle (or whatever)
  void TraceAllocateZoneHandle(uword handle, uword zone_addr);

  // Invoked when a Zone block is deleted.
  void TraceDeleteZone(Zone* zone);

  // Invoked whenever the scoped handles are delelted.
  void TraceDeleteScopedHandles();

  // Invoked when objects are coped from the from space to the to space
  // by the scavenger.
  void TraceCopy(uword from_addr, uword to_addr);

  // Invoked on each pointer in the object store.
  void TraceObjectStorePointer(uword addr);

  // Invoked when an object is promoted from the new space to the old space.
  void TracePromotion(uword old_addr, uword promoted_addr);

  // Invoked after a scavenge with the addressed range of from-space
  void TraceDeathRange(uword inclusive_start, uword exclusive_end);

  // Invoked whenever a class is registered in the class table.
  void TraceRegisterClass(const Class& cls);

  // Invoked when an address is swept.
  void TraceSweep(uword sweept_addr);

  // Invoked when storing value into origin, and value is an object.
  void TraceStoreIntoObject(uword origin_object_addr,
                            uword slot_addr,
                            uword value);

  // Invoked when starting a mark-sweep collection on old space
  void TraceMarkSweepStart();

  // Invoked after finishing a mark sweep collection on old space.
  void TraceMarkSweepFinish();

  // Initialize tracing globablly across the VM. Invidual isolates
  // will still have to initialized themselves when they are started.
  static void InitOnce(Dart_FileOpenCallback open_callback,
                       Dart_FileWriteCallback write_callback,
                       Dart_FileCloseCallback close_callback);

  // Returns true if tracign is enabled for the VM.
  static bool is_enabled() { return is_enabled_; }

 private:
  ObjectSet* CreateEmptyObjectSet() const;
  void ResizeObjectSet();

  void TraceScopedHandle(uword handle);

  // A helper for PutRoots, called by HeapTraceVisitor.
  void TraceSingleRoot(uword root);

  // Invoked while tracing an allocation.
  void TraceRoots(Isolate* isolate);

  // Is the isolate we are tracing initialized?
  bool isolate_initialized_;

  void* output_stream_;

  ObjectSet object_set_;

  static Dart_FileOpenCallback open_callback_;
  static Dart_FileWriteCallback write_callback_;
  static Dart_FileCloseCallback close_callback_;

  static bool is_enabled_;

  friend class HeapTraceVisitor;
  friend class HeapTraceScopedHandleVisitor;
  friend class HeapTraceObjectStoreVisitor;
  friend class HeapTraceDebugObjectVisitor;

  DISALLOW_COPY_AND_ASSIGN(HeapTrace);
};

}  // namespace dart

#endif  // VM_HEAP_TRACE_H_
