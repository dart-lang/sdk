// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLASS_TABLE_H_
#define RUNTIME_VM_CLASS_TABLE_H_

#include "platform/assert.h"
#include "platform/atomic.h"

#include "vm/bitfield.h"
#include "vm/class_id.h"
#include "vm/globals.h"

namespace dart {

class Class;
class ClassStats;
class ClassTable;
class Isolate;
class IsolateGroup;
class IsolateGroupReloadContext;
class IsolateReloadContext;
class JSONArray;
class JSONObject;
class JSONStream;
template <typename T>
class MallocGrowableArray;
class ObjectPointerVisitor;
class RawClass;

class ClassAndSize {
 public:
  ClassAndSize() : class_(NULL), size_(0) {}
  explicit ClassAndSize(RawClass* clazz);
  ClassAndSize(RawClass* clazz, intptr_t size) : class_(clazz), size_(size) {}
  RawClass* get_raw_class() const { return class_; }
  intptr_t size() const { return size_; }

 private:
  RawClass* class_;
  intptr_t size_;

  friend class ClassTable;
  friend class IsolateReloadContext;  // For VisitObjectPointers.
};

#ifndef PRODUCT
template <typename T>
class AllocStats {
 public:
  RelaxedAtomic<T> new_count;
  RelaxedAtomic<T> new_size;
  RelaxedAtomic<T> new_external_size;
  RelaxedAtomic<T> old_count;
  RelaxedAtomic<T> old_size;
  RelaxedAtomic<T> old_external_size;

  void ResetNew() {
    new_count = 0;
    new_size = 0;
    new_external_size = 0;
    old_external_size = 0;
  }

  void AddNew(T size) {
    new_count.fetch_add(1);
    new_size.fetch_add(size);
  }

  void AddNewGC(T size) {
    new_count.fetch_add(1);
    new_size.fetch_add(size);
  }

  void AddNewExternal(T size) { new_external_size.fetch_add(size); }

  void ResetOld() {
    old_count = 0;
    old_size = 0;
    old_external_size = 0;
    new_external_size = 0;
  }

  void AddOld(T size, T count = 1) {
    old_count.fetch_add(count);
    old_size.fetch_add(size);
  }

  void AddOldGC(T size, T count = 1) {
    old_count.fetch_add(count);
    old_size.fetch_add(size);
  }

  void AddOldExternal(T size) { old_external_size.fetch_add(size); }

  void Reset() {
    ResetNew();
    ResetOld();
  }

  // For classes with fixed instance size we do not emit code to update
  // the size statistics. Update them by calling this method.
  void UpdateSize(intptr_t instance_size) {
    ASSERT(instance_size > 0);
    old_size = old_count * instance_size;
    new_size = new_count * instance_size;
  }

  void Verify() {
    ASSERT(new_count >= 0);
    ASSERT(new_size >= 0);
    ASSERT(new_external_size >= 0);
    ASSERT(old_count >= 0);
    ASSERT(old_size >= 0);
    ASSERT(old_external_size >= 0);
  }
};

class ClassHeapStats {
 public:
  // Snapshot before GC.
  AllocStats<intptr_t> pre_gc;
  // Live after GC.
  AllocStats<intptr_t> post_gc;
  // Allocations since the last GC.
  AllocStats<intptr_t> recent;
  // Accumulated (across GC) allocations .
  AllocStats<int64_t> accumulated;
  // Snapshot of recent at the time of the last reset.
  AllocStats<intptr_t> last_reset;
  // Promoted from new to old by last new GC.
  intptr_t promoted_count;
  intptr_t promoted_size;

  static intptr_t allocated_since_gc_new_space_offset() {
    return OFFSET_OF(ClassHeapStats, recent) +
           OFFSET_OF(AllocStats<intptr_t>, new_count);
  }
  static intptr_t allocated_since_gc_old_space_offset() {
    return OFFSET_OF(ClassHeapStats, recent) +
           OFFSET_OF(AllocStats<intptr_t>, old_count);
  }
  static intptr_t allocated_size_since_gc_new_space_offset() {
    return OFFSET_OF(ClassHeapStats, recent) +
           OFFSET_OF(AllocStats<intptr_t>, new_size);
  }
  static intptr_t allocated_size_since_gc_old_space_offset() {
    return OFFSET_OF(ClassHeapStats, recent) +
           OFFSET_OF(AllocStats<intptr_t>, old_size);
  }
  static intptr_t state_offset() { return OFFSET_OF(ClassHeapStats, state_); }
  static intptr_t TraceAllocationMask() { return (1 << kTraceAllocationBit); }

  void Initialize();
  void ResetAtNewGC();
  void ResetAtOldGC();
  void ResetAccumulator();
  void UpdatePromotedAfterNewGC();
  void UpdateSize(intptr_t instance_size);
#ifndef PRODUCT
  void PrintToJSONObject(const Class& cls,
                         JSONObject* obj,
                         bool internal) const;
#endif
  void Verify();

  bool trace_allocation() const { return TraceAllocationBit::decode(state_); }

  void set_trace_allocation(bool trace_allocation) {
    state_ = TraceAllocationBit::update(trace_allocation, state_);
  }

 private:
  enum StateBits {
    kTraceAllocationBit = 0,
  };

  class TraceAllocationBit
      : public BitField<intptr_t, bool, kTraceAllocationBit, 1> {};

  // Recent old at start of last new GC (used to compute promoted_*).
  intptr_t old_pre_new_gc_count_;
  intptr_t old_pre_new_gc_size_;
  intptr_t state_;
  intptr_t align_;  // Make SIMARM and ARM agree on the size of ClassHeapStats.
};
#endif  // !PRODUCT

// Registry of all known classes and their sizes.
//
// The GC will only need the information in this shared class table to scan
// object pointers.
class SharedClassTable {
 public:
  SharedClassTable();
  ~SharedClassTable();

  // Thread-safe.
  intptr_t SizeAt(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_[index];
  }

  bool HasValidClassAt(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    ASSERT(table_[index] >= 0);
    return table_[index] != 0;
  }

  void SetSizeAt(intptr_t index, intptr_t size) {
    ASSERT(IsValidIndex(index));
    // Ensure we never change size for a given cid from one non-zero size to
    // another non-zero size.
    RELEASE_ASSERT(table_[index] == 0 || table_[index] == size);
    table_[index] = size;
  }

  bool IsValidIndex(intptr_t index) const { return index > 0 && index < top_; }

  intptr_t NumCids() const { return top_; }
  intptr_t Capacity() const { return capacity_; }

  // Used to drop recently added classes.
  void SetNumCids(intptr_t num_cids) {
    ASSERT(num_cids <= top_);
    top_ = num_cids;
  }

  // Called whenever a old GC occurs.
  void ResetCountersOld();
  // Called whenever a new GC occurs.
  void ResetCountersNew();
  // Called immediately after a new GC.
  void UpdatePromoted();

  void CopyBeforeHotReload(intptr_t** copy, intptr_t* copy_num_cids) {
    // The [IsolateGroupReloadContext] will need to maintain a copy of the old
    // class table until instances have been morphed.
    const intptr_t num_cids = NumCids();
    const intptr_t bytes = sizeof(intptr_t) * num_cids;
    auto size_table = static_cast<intptr_t*>(malloc(bytes));
    memmove(size_table, table_, sizeof(intptr_t) * num_cids);
    *copy_num_cids = num_cids;
    *copy = size_table;
  }

  void ResetBeforeHotReload() {
    // The [IsolateReloadContext] is now source-of-truth for GC.
    memset(table_, 0, sizeof(intptr_t) * top_);
  }

  void ResetAfterHotReload(intptr_t* old_table,
                           intptr_t num_old_cids,
                           bool is_rollback) {
    // The [IsolateReloadContext] is no longer source-of-truth for GC after we
    // return, so we restore size information for all classes.
    if (is_rollback) {
      SetNumCids(num_old_cids);
      memmove(table_, old_table, sizeof(intptr_t) * num_old_cids);
    }

    // Can't free this table immediately as another thread (e.g., concurrent
    // marker or sweeper) may be between loading the table pointer and loading
    // the table element. The table will be freed at the next major GC or
    // isolate shutdown.
    AddOldTable(old_table);
  }

  // Deallocates table copies. Do not call during concurrent access to table.
  void FreeOldTables();

#if !defined(PRODUCT)
  // Called whenever a class is allocated in the runtime.
  void UpdateAllocatedNew(intptr_t cid, intptr_t size) {
    ClassHeapStats* stats = PreliminaryStatsAt(cid);
    ASSERT(stats != NULL);
    ASSERT(size != 0);
    stats->recent.AddNew(size);
  }
  void UpdateAllocatedOld(intptr_t cid, intptr_t size) {
    ClassHeapStats* stats = PreliminaryStatsAt(cid);
    ASSERT(stats != NULL);
    ASSERT(size != 0);
    stats->recent.AddOld(size);
  }
  void UpdateAllocatedOldGC(intptr_t cid, intptr_t size);
  void UpdateAllocatedExternalNew(intptr_t cid, intptr_t size);
  void UpdateAllocatedExternalOld(intptr_t cid, intptr_t size);

  void ResetAllocationAccumulators();

  void SetTraceAllocationFor(intptr_t cid, bool trace) {
    ClassHeapStats* stats = PreliminaryStatsAt(cid);
    stats->set_trace_allocation(trace);
  }
  bool TraceAllocationFor(intptr_t cid) {
    ClassHeapStats* stats = PreliminaryStatsAt(cid);
    return stats->trace_allocation();
  }

  ClassHeapStats* StatsWithUpdatedSize(intptr_t cid, intptr_t size);

#if !defined(DART_PRECOMPILED_RUNTIME)
  bool IsReloading() const { return reload_context_ != nullptr; }

  IsolateGroupReloadContext* reload_context() { return reload_context_; }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#endif  // !defined(PRODUCT)

  // Returns the newly allocated cid.
  //
  // [index] is kIllegalCid or a predefined cid.
  intptr_t Register(intptr_t index, intptr_t size);
  void AllocateIndex(intptr_t index);
  void Unregister(intptr_t index);

  void Remap(intptr_t* old_to_new_cids);

  // Used by the generated code.
#ifndef PRODUCT
  static intptr_t class_heap_stats_table_offset() {
    return OFFSET_OF(SharedClassTable, class_heap_stats_table_);
  }
#endif

  // Used by the generated code.
  static intptr_t ClassOffsetFor(intptr_t cid);

  // Used by the generated code.
  static intptr_t NewSpaceCounterOffsetFor(intptr_t cid);

  // Used by the generated code.
  static intptr_t StateOffsetFor(intptr_t cid);

  // Used by the generated code.
  static intptr_t NewSpaceSizeOffsetFor(intptr_t cid);

  static const int kInitialCapacity = 512;
  static const int kCapacityIncrement = 256;

 private:
  friend class ClassTable;
  friend class GCMarker;
  friend class MarkingWeakVisitor;
  friend class Scavenger;
  friend class ScavengerWeakVisitor;
  friend class ClassHeapStatsTestHelper;
  friend class HeapTestsHelper;

  static bool ShouldUpdateSizeForClassId(intptr_t cid);

#ifndef PRODUCT
  // May not have updated size for variable size classes.
  ClassHeapStats* PreliminaryStatsAt(intptr_t cid) {
    ASSERT(cid > 0);
    ASSERT(cid < top_);
    return &class_heap_stats_table_[cid];
  }
  void UpdateLiveOld(intptr_t cid, intptr_t size, intptr_t count = 1);
  void UpdateLiveNew(intptr_t cid, intptr_t size);
  void UpdateLiveNewGC(intptr_t cid, intptr_t size);
  void UpdateLiveOldExternal(intptr_t cid, intptr_t size);
  void UpdateLiveNewExternal(intptr_t cid, intptr_t size);

  ClassHeapStats* class_heap_stats_table_ = nullptr;
#endif  // !PRODUCT

  void AddOldTable(intptr_t* old_table);

  void Grow(intptr_t new_capacity);

  intptr_t top_;
  intptr_t capacity_;

  // Copy-on-write is used for table_, with old copies stored in old_tables_.
  intptr_t* table_;  // Maps the cid to the instance size.
  MallocGrowableArray<intptr_t*>* old_tables_;

  IsolateGroupReloadContext* reload_context_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(SharedClassTable);
};

class ClassTable {
 public:
  explicit ClassTable(SharedClassTable* shared_class_table_);

  // Creates a shallow copy of the original class table for some read-only
  // access, without support for stats data.
  ClassTable(ClassTable* original, SharedClassTable* shared_class_table);
  ~ClassTable();

  SharedClassTable* shared_class_table() const { return shared_class_table_; }

  void CopyBeforeHotReload(RawClass*** copy, intptr_t* copy_num_cids) {
    // The [IsolateReloadContext] will need to maintain a copy of the old class
    // table until instances have been morphed.
    const intptr_t num_cids = NumCids();
    const intptr_t bytes = sizeof(RawClass*) * num_cids;
    auto class_table = static_cast<RawClass**>(malloc(bytes));
    memmove(class_table, table_, sizeof(RawClass*) * num_cids);
    *copy_num_cids = num_cids;
    *copy = class_table;
  }

  void ResetBeforeHotReload() {
    // We cannot clear out the class pointers, because a hot-reload
    // contains only a diff: If e.g. a class included in the hot-reload has a
    // super class not included in the diff, it will look up in this class table
    // to find the super class (e.g. `cls.SuperClass` will cause us to come
    // here).
  }

  void ResetAfterHotReload(RawClass** old_table,
                           intptr_t num_old_cids,
                           bool is_rollback) {
    // The [IsolateReloadContext] is no longer source-of-truth for GC after we
    // return, so we restore size information for all classes.
    if (is_rollback) {
      SetNumCids(num_old_cids);
      memmove(table_, old_table, sizeof(RawClass*) * num_old_cids);
    } else {
      CopySizesFromClassObjects();
    }

    // Can't free this table immediately as another thread (e.g., concurrent
    // marker or sweeper) may be between loading the table pointer and loading
    // the table element. The table will be freed at the next major GC or
    // isolate shutdown.
    AddOldTable(old_table);
  }

  // Thread-safe.
  RawClass* At(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_[index];
  }

  intptr_t SizeAt(intptr_t index) const {
    return shared_class_table_->SizeAt(index);
  }

  void SetAt(intptr_t index, RawClass* raw_cls);

  bool IsValidIndex(intptr_t index) const {
    return shared_class_table_->IsValidIndex(index);
  }

  bool HasValidClassAt(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_[index] != nullptr;
  }

  intptr_t NumCids() const { return shared_class_table_->NumCids(); }
  intptr_t Capacity() const { return shared_class_table_->Capacity(); }

  // Used to drop recently added classes.
  void SetNumCids(intptr_t num_cids) {
    shared_class_table_->SetNumCids(num_cids);

    ASSERT(num_cids <= top_);
    top_ = num_cids;
  }

  void Register(const Class& cls);
  void AllocateIndex(intptr_t index);
  void Unregister(intptr_t index);

  void Remap(intptr_t* old_to_new_cids);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // If a snapshot reader has populated the class table then the
  // sizes in the class table are not correct. Iterates through the
  // table, updating the sizes.
  void CopySizesFromClassObjects();

  void Validate();

  void Print();

  // Used by the generated code.
  static intptr_t table_offset() { return OFFSET_OF(ClassTable, table_); }

  // Used by the generated code.
  static intptr_t shared_class_table_offset() {
    return OFFSET_OF(ClassTable, shared_class_table_);
  }

#ifndef PRODUCT
  // Describes layout of heap stats for code generation. See offset_extractor.cc
  struct ArrayLayout {
    static intptr_t elements_start_offset() { return 0; }

    static constexpr intptr_t kElementSize = sizeof(ClassHeapStats);
  };
#endif

#ifndef PRODUCT

  ClassHeapStats* StatsWithUpdatedSize(intptr_t cid);

  void AllocationProfilePrintJSON(JSONStream* stream, bool internal);

  void PrintToJSONObject(JSONObject* object);
#endif  // !PRODUCT

  // Deallocates table copies. Do not call during concurrent access to table.
  void FreeOldTables();

 private:
  friend class GCMarker;
  friend class MarkingWeakVisitor;
  friend class Scavenger;
  friend class ScavengerWeakVisitor;
  friend class ClassHeapStatsTestHelper;
  friend class HeapTestsHelper;
  static const int kInitialCapacity = SharedClassTable::kInitialCapacity;
  static const int kCapacityIncrement = SharedClassTable::kCapacityIncrement;

  void AddOldTable(RawClass** old_table);

  void Grow(intptr_t index);

  intptr_t top_;
  intptr_t capacity_;

  // Copy-on-write is used for table_, with old copies stored in
  // old_class_tables_.
  RawClass** table_;
  MallocGrowableArray<RawClass**>* old_class_tables_;
  SharedClassTable* shared_class_table_;

  DISALLOW_COPY_AND_ASSIGN(ClassTable);
};

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_TABLE_H_
