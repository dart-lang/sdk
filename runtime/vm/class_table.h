// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLASS_TABLE_H_
#define RUNTIME_VM_CLASS_TABLE_H_

#include "platform/assert.h"
#include "vm/atomic.h"
#include "vm/bitfield.h"
#include "vm/globals.h"

namespace dart {

class Class;
class ClassStats;
class JSONArray;
class JSONObject;
class JSONStream;
template <typename T>
class MallocGrowableArray;
class ObjectPointerVisitor;
class RawClass;

#ifndef PRODUCT
template <typename T>
class AllocStats {
 public:
  T new_count;
  T new_size;
  T new_external_size;
  T old_count;
  T old_size;
  T old_external_size;

  void ResetNew() {
    new_count = 0;
    new_size = 0;
    new_external_size = 0;
  }

  void AddNew(T size) {
    AtomicOperations::IncrementBy(&new_count, 1);
    AtomicOperations::IncrementBy(&new_size, size);
  }

  void AddNewExternal(T size) {
    AtomicOperations::IncrementBy(&new_external_size, size);
  }

  void ResetOld() {
    old_count = 0;
    old_size = 0;
    old_external_size = 0;
  }

  void AddOld(T size, T count = 1) {
    AtomicOperations::IncrementBy(&old_count, count);
    AtomicOperations::IncrementBy(&old_size, size);
  }

  void AddOldExternal(T size) {
    AtomicOperations::IncrementBy(&old_external_size, size);
  }

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
  void PrintToJSONObject(const Class& cls, JSONObject* obj) const;
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

class ClassTable {
 public:
  ClassTable();
  // Creates a shallow copy of the original class table for some read-only
  // access, without support for stats data.
  explicit ClassTable(ClassTable* original);
  ~ClassTable();

  // Thread-safe.
  RawClass* At(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_[index];
  }

  void SetAt(intptr_t index, RawClass* raw_cls) { table_[index] = raw_cls; }

  bool IsValidIndex(intptr_t index) const {
    return (index > 0) && (index < top_);
  }

  bool HasValidClassAt(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_[index] != NULL;
  }

  intptr_t NumCids() const { return top_; }

  // Used to drop recently added classes.
  void SetNumCids(intptr_t num_cids) {
    ASSERT(num_cids <= top_);
    top_ = num_cids;
  }

  void Register(const Class& cls);

  void AllocateIndex(intptr_t index);

  void RegisterAt(intptr_t index, const Class& cls);

#if defined(DEBUG)
  void Unregister(intptr_t index);
#endif

  void Remap(intptr_t* old_to_new_cids);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void Validate();

  void Print();

  // Used by the generated code.
  static intptr_t table_offset() { return OFFSET_OF(ClassTable, table_); }

  // Used by the generated code.
  static intptr_t ClassOffsetFor(intptr_t cid);

#ifndef PRODUCT
  // Called whenever a class is allocated in the runtime.
  void UpdateAllocatedNew(intptr_t cid, intptr_t size);
  void UpdateAllocatedOld(intptr_t cid, intptr_t size);

  void UpdateAllocatedExternalNew(intptr_t cid, intptr_t size);
  void UpdateAllocatedExternalOld(intptr_t cid, intptr_t size);

  // Called whenever a old GC occurs.
  void ResetCountersOld();
  // Called whenever a new GC occurs.
  void ResetCountersNew();
  // Called immediately after a new GC.
  void UpdatePromoted();

  // Used by the generated code.
  ClassHeapStats** TableAddressFor(intptr_t cid);
  static intptr_t TableOffsetFor(intptr_t cid);

  // Used by the generated code.
  static intptr_t CounterOffsetFor(intptr_t cid, bool is_new_space);

  // Used by the generated code.
  static intptr_t StateOffsetFor(intptr_t cid);

  // Used by the generated code.
  static intptr_t SizeOffsetFor(intptr_t cid, bool is_new_space);

  ClassHeapStats* StatsWithUpdatedSize(intptr_t cid);

  void AllocationProfilePrintJSON(JSONStream* stream);
  void ResetAllocationAccumulators();

  void PrintToJSONObject(JSONObject* object);
#endif  // !PRODUCT

  void AddOldTable(RawClass** old_table);
  // Deallocates table copies. Do not call during concurrent access to table.
  void FreeOldTables();

  void SetTraceAllocationFor(intptr_t cid, bool trace);
  bool TraceAllocationFor(intptr_t cid);

 private:
  friend class GCMarker;
  friend class MarkingWeakVisitor;
  friend class ScavengerVisitor;
  friend class ScavengerWeakVisitor;
  friend class ClassHeapStatsTestHelper;
  static const int initial_capacity_ = 512;
  static const int capacity_increment_ = 256;

  static bool ShouldUpdateSizeForClassId(intptr_t cid);

  intptr_t top_;
  intptr_t capacity_;

  // Copy-on-write is used for table_, with old copies stored in old_tables_.
  RawClass** table_;
  MallocGrowableArray<RawClass**>* old_tables_;

#ifndef PRODUCT
  ClassHeapStats* class_heap_stats_table_;
  ClassHeapStats* predefined_class_heap_stats_table_;

  // May not have updated size for variable size classes.
  ClassHeapStats* PreliminaryStatsAt(intptr_t cid);
  void UpdateLiveOld(intptr_t cid, intptr_t size, intptr_t count = 1);
  void UpdateLiveNew(intptr_t cid, intptr_t size);
  void UpdateLiveOldExternal(intptr_t cid, intptr_t size);
  void UpdateLiveNewExternal(intptr_t cid, intptr_t size);
#endif  // !PRODUCT

  DISALLOW_COPY_AND_ASSIGN(ClassTable);
};

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_TABLE_H_
