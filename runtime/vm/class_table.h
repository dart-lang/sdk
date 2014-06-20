// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CLASS_TABLE_H_
#define VM_CLASS_TABLE_H_

#include "platform/assert.h"
#include "vm/globals.h"

namespace dart {

class Class;
class ClassStats;
class JSONArray;
class JSONObject;
class JSONStream;
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

  void Initialize();
  void ResetAtNewGC();
  void ResetAtOldGC();
  void ResetAccumulator();
  void UpdateSize(intptr_t instance_size);
  void PrintToJSONObject(const Class& cls, JSONObject* obj) const;
};


class ClassTable {
 public:
  ClassTable();
  ~ClassTable();

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

  // Used by the generated code.
  uword PredefinedClassHeapStatsTableAddress() {
    return reinterpret_cast<uword>(predefined_class_heap_stats_table_);
  }

  // Used by generated code.
  uword ClassStatsTableAddress() {
    return reinterpret_cast<uword>(&class_heap_stats_table_);
  }

  ClassHeapStats* StatsWithUpdatedSize(intptr_t cid);

  void AllocationProfilePrintJSON(JSONStream* stream);
  void ResetAllocationAccumulators();

 private:
  friend class MarkingVisitor;
  friend class ScavengerVisitor;
  friend class ClassHeapStatsTestHelper;
  static const int initial_capacity_ = 512;
  static const int capacity_increment_ = 256;

  static bool ShouldUpdateSizeForClassId(intptr_t cid);

  intptr_t top_;
  intptr_t capacity_;

  RawClass** table_;
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
