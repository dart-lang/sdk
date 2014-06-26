// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_table.h"
#include "vm/flags.h"
#include "vm/freelist.h"
#include "vm/heap.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, print_class_table, false, "Print initial class table.");

ClassTable::ClassTable()
    : top_(kNumPredefinedCids), capacity_(0), table_(NULL),
      class_heap_stats_table_(NULL),
      predefined_class_heap_stats_table_(NULL) {
  if (Dart::vm_isolate() == NULL) {
    capacity_ = initial_capacity_;
    table_ = reinterpret_cast<RawClass**>(
        calloc(capacity_, sizeof(RawClass*)));  // NOLINT
  } else {
    // Duplicate the class table from the VM isolate.
    ClassTable* vm_class_table = Dart::vm_isolate()->class_table();
    capacity_ = vm_class_table->capacity_;
    table_ = reinterpret_cast<RawClass**>(
        calloc(capacity_, sizeof(RawClass*)));  // NOLINT
    for (intptr_t i = kObjectCid; i < kInstanceCid; i++) {
      table_[i] = vm_class_table->At(i);
    }
    table_[kFreeListElement] = vm_class_table->At(kFreeListElement);
    table_[kDynamicCid] = vm_class_table->At(kDynamicCid);
    table_[kVoidCid] = vm_class_table->At(kVoidCid);
    class_heap_stats_table_ = reinterpret_cast<ClassHeapStats*>(
        calloc(capacity_, sizeof(ClassHeapStats)));  // NOLINT
    for (intptr_t i = 0; i < capacity_; i++) {
      class_heap_stats_table_[i].Initialize();
    }
  }
  predefined_class_heap_stats_table_ = reinterpret_cast<ClassHeapStats*>(
        calloc(kNumPredefinedCids, sizeof(ClassHeapStats)));  // NOLINT
  for (intptr_t i = 0; i < kNumPredefinedCids; i++) {
    predefined_class_heap_stats_table_[i].Initialize();
  }
}


ClassTable::~ClassTable() {
  free(table_);
  free(predefined_class_heap_stats_table_);
  free(class_heap_stats_table_);
}


void ClassTable::Register(const Class& cls) {
  intptr_t index = cls.id();
  if (index != kIllegalCid) {
    ASSERT(index > 0);
    ASSERT(index < kNumPredefinedCids);
    ASSERT(table_[index] == 0);
    ASSERT(index < capacity_);
    table_[index] = cls.raw();
    // Add the vtable for this predefined class into the static vtable registry
    // if it has not been setup yet.
    cpp_vtable cls_vtable = cls.handle_vtable();
    cpp_vtable table_entry = Object::builtin_vtables_[index];
    ASSERT((table_entry == 0) || (table_entry == cls_vtable));
    if (table_entry == 0) {
      Object::builtin_vtables_[index] = cls_vtable;
    }
  } else {
    if (top_ == capacity_) {
      // Grow the capacity of the class table.
      intptr_t new_capacity = capacity_ + capacity_increment_;
      RawClass** new_table = reinterpret_cast<RawClass**>(
          realloc(table_, new_capacity * sizeof(RawClass*)));  // NOLINT
      ClassHeapStats* new_stats_table = reinterpret_cast<ClassHeapStats*>(
          realloc(class_heap_stats_table_,
                  new_capacity * sizeof(ClassHeapStats)));  // NOLINT
      for (intptr_t i = capacity_; i < new_capacity; i++) {
        new_table[i] = NULL;
        new_stats_table[i].Initialize();
      }
      capacity_ = new_capacity;
      table_ = new_table;
      class_heap_stats_table_ = new_stats_table;
    }
    ASSERT(top_ < capacity_);
    if (!Class::is_valid_id(top_)) {
      FATAL1("Fatal error in ClassTable::Register: invalid index %" Pd "\n",
             top_);
    }
    cls.set_id(top_);
    table_[top_] = cls.raw();
    top_++;  // Increment next index.
  }
}


void ClassTable::RegisterAt(intptr_t index, const Class& cls) {
  ASSERT(index != kIllegalCid);
  ASSERT(index >= kNumPredefinedCids);
  if (index >= capacity_) {
    // Grow the capacity of the class table.
    intptr_t new_capacity = index + capacity_increment_;
    if (!Class::is_valid_id(index) || new_capacity < capacity_) {
      FATAL1("Fatal error in ClassTable::Register: invalid index %" Pd "\n",
             index);
    }
    RawClass** new_table = reinterpret_cast<RawClass**>(
        realloc(table_, new_capacity * sizeof(RawClass*)));  // NOLINT
    ClassHeapStats* new_stats_table = reinterpret_cast<ClassHeapStats*>(
        realloc(class_heap_stats_table_,
                new_capacity * sizeof(ClassHeapStats)));  // NOLINT
    for (intptr_t i = capacity_; i < new_capacity; i++) {
      new_table[i] = NULL;
      new_stats_table[i].Initialize();
    }
    capacity_ = new_capacity;
    table_ = new_table;
    class_heap_stats_table_ = new_stats_table;
    ASSERT(capacity_increment_ >= 1);
  }
  ASSERT(table_[index] == 0);
  cls.set_id(index);
  table_[index] = cls.raw();
  if (index >= top_) {
    top_ = index + 1;
  }
}


void ClassTable::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->VisitPointers(reinterpret_cast<RawObject**>(&table_[0]), top_);
}


void ClassTable::Validate() {
  Class& cls = Class::Handle();
  for (intptr_t i = kNumPredefinedCids; i < top_; i++) {
    // Some of the class table entries maybe NULL as we create some
    // top level classes but do not add them to the list of anonymous
    // classes in a library if there are no top level fields or functions.
    // Since there are no references to these top level classes they are
    // not written into a full snapshot and will not be recreated when
    // we read back the full snapshot. These class slots end up with NULL
    // entries.
    if (HasValidClassAt(i)) {
      cls = At(i);
      ASSERT(cls.IsClass());
    }
  }
}


void ClassTable::Print() {
  Class& cls = Class::Handle();
  String& name = String::Handle();

  for (intptr_t i = 1; i < top_; i++) {
    cls = At(i);
    if (cls.raw() != reinterpret_cast<RawClass*>(0)) {
      name = cls.Name();
      OS::Print("%" Pd ": %s\n", i, name.ToCString());
    }
  }
}


void ClassTable::PrintToJSONObject(JSONObject* object) {
  Class& cls = Class::Handle();
  object->AddProperty("type", "ClassList");
  object->AddProperty("id", "classes");
  {
    JSONArray members(object, "members");
    for (intptr_t i = 1; i < top_; i++) {
      if (HasValidClassAt(i)) {
        cls = At(i);
        members.AddValue(cls);
      }
    }
  }
}


void ClassHeapStats::Initialize() {
  pre_gc.Reset();
  post_gc.Reset();
  recent.Reset();
  accumulated.Reset();
  last_reset.Reset();
}


void ClassHeapStats::ResetAtNewGC() {
  pre_gc.new_count = post_gc.new_count + recent.new_count;
  pre_gc.new_size = post_gc.new_size + recent.new_size;
  // Accumulate allocations.
  accumulated.new_count += recent.new_count - last_reset.new_count;
  accumulated.new_size += recent.new_size - last_reset.new_size;
  last_reset.ResetNew();
  post_gc.ResetNew();
  recent.ResetNew();
}


void ClassHeapStats::ResetAtOldGC() {
  pre_gc.old_count = post_gc.old_count + recent.old_count;
  pre_gc.old_size = post_gc.old_size + recent.old_size;
  // Accumulate allocations.
  accumulated.old_count += recent.old_count - last_reset.old_count;
  accumulated.old_size += recent.old_size - last_reset.old_size;
  last_reset.ResetOld();
  post_gc.ResetOld();
  recent.ResetOld();
}


void ClassHeapStats::UpdateSize(intptr_t instance_size) {
  pre_gc.UpdateSize(instance_size);
  post_gc.UpdateSize(instance_size);
  recent.UpdateSize(instance_size);
  accumulated.UpdateSize(instance_size);
  last_reset.UpdateSize(instance_size);
}


void ClassHeapStats::ResetAccumulator() {
  // Remember how much was allocated so we can subtract this from the result
  // when printing.
  last_reset.new_count = recent.new_count;
  last_reset.new_size = recent.new_size;
  last_reset.old_count = recent.old_count;
  last_reset.old_size = recent.old_size;
  accumulated.Reset();
}


void ClassHeapStats::PrintToJSONObject(const Class& cls,
                                       JSONObject* obj) const {
  obj->AddProperty("type", "ClassHeapStats");
  obj->AddPropertyF("id", "allocationprofile/%" Pd "", cls.id());
  obj->AddProperty("class", cls);
  {
    JSONArray new_stats(obj, "new");
    new_stats.AddValue(pre_gc.new_count);
    new_stats.AddValue(pre_gc.new_size);
    new_stats.AddValue(post_gc.new_count);
    new_stats.AddValue(post_gc.new_size);
    new_stats.AddValue(recent.new_count);
    new_stats.AddValue(recent.new_size);
    new_stats.AddValue64(accumulated.new_count + recent.new_count -
                         last_reset.new_count);
    new_stats.AddValue64(accumulated.new_size + recent.new_size -
                         last_reset.new_size);
  }
  {
    JSONArray old_stats(obj, "old");
    old_stats.AddValue(pre_gc.old_count);
    old_stats.AddValue(pre_gc.old_size);
    old_stats.AddValue(post_gc.old_count);
    old_stats.AddValue(post_gc.old_size);
    old_stats.AddValue(recent.old_count);
    old_stats.AddValue(recent.old_size);
    old_stats.AddValue64(accumulated.old_count + recent.old_count -
                         last_reset.old_count);
    old_stats.AddValue64(accumulated.old_size + recent.old_size -
                         last_reset.old_size);
  }
}


void ClassTable::UpdateAllocatedNew(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size != 0);
  stats->recent.AddNew(size);
}


void ClassTable::UpdateAllocatedOld(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size != 0);
  stats->recent.AddOld(size);
}


bool ClassTable::ShouldUpdateSizeForClassId(intptr_t cid) {
  return !RawObject::IsVariableSizeClassId(cid);
}


ClassHeapStats* ClassTable::PreliminaryStatsAt(intptr_t cid) {
  ASSERT(cid > 0);
  if (cid < kNumPredefinedCids) {
    return &predefined_class_heap_stats_table_[cid];
  }
  ASSERT(cid < top_);
  return &class_heap_stats_table_[cid];
}


ClassHeapStats* ClassTable::StatsWithUpdatedSize(intptr_t cid) {
  if (!HasValidClassAt(cid) || (cid == kFreeListElement) || (cid == kSmiCid)) {
    return NULL;
  }
  Class& cls = Class::Handle(At(cid));
  if (!(cls.is_finalized() || cls.is_prefinalized())) {
    // Not finalized.
    return NULL;
  }
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  if (ShouldUpdateSizeForClassId(cid)) {
    stats->UpdateSize(cls.instance_size());
  }
  return stats;
}


void ClassTable::ResetCountersOld() {
  for (intptr_t i = 0; i < kNumPredefinedCids; i++) {
    predefined_class_heap_stats_table_[i].ResetAtOldGC();
  }
  for (intptr_t i = kNumPredefinedCids; i < top_; i++) {
    class_heap_stats_table_[i].ResetAtOldGC();
  }
}


void ClassTable::ResetCountersNew() {
  for (intptr_t i = 0; i < kNumPredefinedCids; i++) {
    predefined_class_heap_stats_table_[i].ResetAtNewGC();
  }
  for (intptr_t i = kNumPredefinedCids; i < top_; i++) {
    class_heap_stats_table_[i].ResetAtNewGC();
  }
}


void ClassTable::AllocationProfilePrintJSON(JSONStream* stream) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  Heap* heap = isolate->heap();
  ASSERT(heap != NULL);
  JSONObject obj(stream);
  obj.AddProperty("type", "AllocationProfile");
  obj.AddProperty("id", "allocationprofile");
  obj.AddPropertyF(
      "dateLastAccumulatorReset",
      "%" Pd64 "",
      isolate->last_allocationprofile_accumulator_reset_timestamp());
  obj.AddPropertyF(
      "dateLastServiceGC",
      "%" Pd64 "",
      isolate->last_allocationprofile_gc_timestamp());

  {
    JSONObject heaps(&obj, "heaps");
    {
      heap->PrintToJSONObject(Heap::kNew, &heaps);
    }
    {
      heap->PrintToJSONObject(Heap::kOld, &heaps);
    }
  }
  {
    JSONArray arr(&obj, "members");
    Class& cls = Class::Handle();
    for (intptr_t i = 1; i < top_; i++) {
      const ClassHeapStats* stats = StatsWithUpdatedSize(i);
      if (stats != NULL) {
        JSONObject obj(&arr);
        cls = At(i);
        stats->PrintToJSONObject(cls, &obj);
      }
    }
  }
}


void ClassTable::ResetAllocationAccumulators() {
  for (intptr_t i = 1; i < top_; i++) {
    ClassHeapStats* stats = StatsWithUpdatedSize(i);
    if (stats != NULL) {
      stats->ResetAccumulator();
    }
  }
}


void ClassTable::UpdateLiveOld(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  stats->post_gc.AddOld(size);
}


void ClassTable::UpdateLiveNew(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  stats->post_gc.AddNew(size);
}


}  // namespace dart
