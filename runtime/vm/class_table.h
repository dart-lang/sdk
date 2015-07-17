// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CLASS_TABLE_H_
#define VM_CLASS_TABLE_H_

#include "platform/assert.h"
#include "vm/bitfield.h"
#include "vm/globals.h"

namespace dart {

class Class;
class ClassStats;
class JSONArray;
class JSONObject;
class JSONStream;
template<typename T> class MallocGrowableArray;
class ObjectPointerVisitor;
class RawClass;

template<typename T>
class AllocStats {
 public:
  T new_count;
  T new_size;
  T old_count;
  T old_size;

  void ResetNew() {
    new_count = 0;
    new_size = 0;
  }

  void AddNew(T size) {
    new_count++;
    new_size += size;
  }

  void ResetOld() {
    old_count = 0;
    old_size = 0;
  }

  void AddOld(T size) {
    old_count++;
    old_size += size;
  }

  void Reset() {
    new_count = 0;
    new_size = 0;
    old_count = 0;
    old_size = 0;
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
    ASSERT(old_count >= 0);
    ASSERT(old_size >= 0);
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
  static intptr_t state_offset() {
    return OFFSET_OF(ClassHeapStats, state_);
  }
  static intptr_t TraceAllocationMask() {
    return (1 << kTraceAllocationBit);
  }

  void Initialize();
  void ResetAtNewGC();
  void ResetAtOldGC();
  void ResetAccumulator();
  void UpdatePromotedAfterNewGC();
  void UpdateSize(intptr_t instance_size);
  void PrintToJSONObject(const Class& cls, JSONObject* obj) const;
  void Verify();

  bool trace_allocation() const {
    return TraceAllocationBit::decode(state_);
  }

  void set_trace_allocation(bool trace_allocation) {
    state_ = TraceAllocationBit::update(trace_allocation, state_);
  }

 private:
  enum StateBits {
    kTraceAllocationBit = 0,
  };

  class TraceAllocationBit : public BitField<bool, kTraceAllocationBit, 1> {};

  // Recent old at start of last new GC (used to compute promoted_*).
  intptr_t old_pre_new_gc_count_;
  intptr_t old_pre_new_gc_size_;
  intptr_t state_;
};


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

  intptr_t IsValidIndex(intptr_t index) const {
    return (index > 0) && (index < top_);
  }

  bool HasValidClassAt(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_[index] != NULL;
  }

  intptr_t NumCids() const { return top_; }

  void Register(const Class& cls);

  void RegisterAt(intptr_t index, const Class& cls);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void Validate();

  void Print();

  void PrintToJSONObject(JSONObject* object);

  // Used by the generated code.
  static intptr_t table_offset() {
    return OFFSET_OF(ClassTable, table_);
  }

  // Called whenever a class is allocated in the runtime.
  void UpdateAllocatedNew(intptr_t cid, intptr_t size);
  void UpdateAllocatedOld(intptr_t cid, intptr_t size);

  // Called whenever a old GC occurs.
  void ResetCountersOld();
  // Called whenever a new GC occurs.
  void ResetCountersNew();
  // Called immediately after a new GC.
  void UpdatePromoted();

  // Used by the generated code.
  static intptr_t ClassOffsetFor(intptr_t cid);

  // Used by the generated code.
  ClassHeapStats** TableAddressFor(intptr_t cid);
  static intptr_t TableOffsetFor(intptr_t cid);

  // Used by the generated code.
  static intptr_t CounterOffsetFor(intptr_t cid, bool is_new_space);

  // Used by the generated code.
  ClassHeapStats** StateAddressFor(intptr_t cid,
                                   intptr_t* state_offset);

  // Used by the generated code.
  static intptr_t SizeOffsetFor(intptr_t cid, bool is_new_space);

  ClassHeapStats* StatsWithUpdatedSize(intptr_t cid);

  void AllocationProfilePrintJSON(JSONStream* stream);
  void ResetAllocationAccumulators();

  // Deallocates table copies. Do not call during concurrent access to table.
  void FreeOldTables();

  void TraceAllocationsFor(intptr_t cid, bool trace);

 private:
  friend class MarkingVisitor;
  friend class ScavengerVisitor;
  friend class ClassHeapStatsTestHelper;
  static const int initial_capacity_ = 512;
  static const int capacity_increment_ = 256;

  static bool ShouldUpdateSizeForClassId(intptr_t cid);

  intptr_t top_;
  intptr_t capacity_;

  // Copy-on-write is used for table_, with old copies stored in old_tables_.
  RawClass** table_;
  MallocGrowableArray<RawClass**>* old_tables_;

  ClassHeapStats* class_heap_stats_table_;

  ClassHeapStats* predefined_class_heap_stats_table_;

  // May not have updated size for variable size classes.
  ClassHeapStats* PreliminaryStatsAt(intptr_t cid);
  void UpdateLiveOld(intptr_t cid, intptr_t size);
  void UpdateLiveNew(intptr_t cid, intptr_t size);

  DISALLOW_COPY_AND_ASSIGN(ClassTable);
};

}  // namespace dart

#endif  // VM_CLASS_TABLE_H_
