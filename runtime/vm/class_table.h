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
class JSONStream;
class ObjectPointerVisitor;
class RawClass;


class ClassHeapStats {
 public:
  // Total allocated before GC.
  intptr_t allocated_before_gc_old_space;
  intptr_t allocated_before_gc_new_space;
  intptr_t allocated_size_before_gc_old_space;
  intptr_t allocated_size_before_gc_new_space;

  // Live after GC.
  intptr_t live_after_gc_old_space;
  intptr_t live_after_gc_new_space;
  intptr_t live_size_after_gc_old_space;
  intptr_t live_size_after_gc_new_space;

  // Allocated since GC.
  intptr_t allocated_since_gc_new_space;
  intptr_t allocated_since_gc_old_space;
  intptr_t allocated_size_since_gc_new_space;
  intptr_t allocated_size_since_gc_old_space;

  static intptr_t allocated_since_gc_new_space_offset() {
    return OFFSET_OF(ClassHeapStats, allocated_since_gc_new_space);
  }
  static intptr_t allocated_since_gc_old_space_offset() {
    return OFFSET_OF(ClassHeapStats, allocated_since_gc_old_space);
  }
  static intptr_t allocated_size_since_gc_new_space_offset() {
    return OFFSET_OF(ClassHeapStats, allocated_size_since_gc_new_space);
  }
  static intptr_t allocated_size_since_gc_old_space_offset() {
    return OFFSET_OF(ClassHeapStats, allocated_size_since_gc_old_space);
  }

  void Initialize();
  void ResetAtNewGC();
  void ResetAtOldGC();
  void UpdateSize(intptr_t instance_size);
  void PrintTOJSONArray(const Class& cls, JSONArray* array);
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

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void Print();

  void PrintToJSONStream(JSONStream* stream);

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


  void AllocationProfilePrintToJSONStream(JSONStream* stream);

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

  ClassHeapStats* StatsAt(intptr_t cid);
  void UpdateLiveOld(intptr_t cid, intptr_t size);
  void UpdateLiveNew(intptr_t cid, intptr_t size);

  DISALLOW_COPY_AND_ASSIGN(ClassTable);
};

}  // namespace dart

#endif  // VM_CLASS_TABLE_H_
