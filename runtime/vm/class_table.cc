// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_table.h"

#include "platform/atomic.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/heap/heap.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, print_class_table, false, "Print initial class table.");

ClassTable::ClassTable()
    : top_(kNumPredefinedCids),
      capacity_(0),
      table_(NULL),
      old_tables_(new MallocGrowableArray<ClassAndSize*>()) {
  NOT_IN_PRODUCT(class_heap_stats_table_ = NULL);
  NOT_IN_PRODUCT(predefined_class_heap_stats_table_ = NULL);
  if (Dart::vm_isolate() == NULL) {
    capacity_ = initial_capacity_;
    table_ = reinterpret_cast<ClassAndSize*>(
        calloc(capacity_, sizeof(ClassAndSize)));  // NOLINT
  } else {
    // Duplicate the class table from the VM isolate.
    ClassTable* vm_class_table = Dart::vm_isolate()->class_table();
    capacity_ = vm_class_table->capacity_;
    table_ = reinterpret_cast<ClassAndSize*>(
        calloc(capacity_, sizeof(ClassAndSize)));  // NOLINT
    for (intptr_t i = kObjectCid; i < kInstanceCid; i++) {
      table_[i] = vm_class_table->PairAt(i);
    }
    table_[kTypeArgumentsCid] = vm_class_table->PairAt(kTypeArgumentsCid);
    table_[kFreeListElement] = vm_class_table->PairAt(kFreeListElement);
    table_[kForwardingCorpse] = vm_class_table->PairAt(kForwardingCorpse);
    table_[kDynamicCid] = vm_class_table->PairAt(kDynamicCid);
    table_[kVoidCid] = vm_class_table->PairAt(kVoidCid);

#ifndef PRODUCT
    class_heap_stats_table_ = reinterpret_cast<ClassHeapStats*>(
        calloc(capacity_, sizeof(ClassHeapStats)));  // NOLINT
    for (intptr_t i = 0; i < capacity_; i++) {
      class_heap_stats_table_[i].Initialize();
    }
#endif  // !PRODUCT
  }
#ifndef PRODUCT
  predefined_class_heap_stats_table_ = reinterpret_cast<ClassHeapStats*>(
      calloc(kNumPredefinedCids, sizeof(ClassHeapStats)));  // NOLINT
  for (intptr_t i = 0; i < kNumPredefinedCids; i++) {
    predefined_class_heap_stats_table_[i].Initialize();
  }
#endif  // !PRODUCT
}

ClassTable::ClassTable(ClassTable* original)
    : top_(original->top_),
      capacity_(original->top_),
      table_(original->table_),
      old_tables_(NULL) {
  NOT_IN_PRODUCT(class_heap_stats_table_ = NULL);
  NOT_IN_PRODUCT(predefined_class_heap_stats_table_ = NULL);
}

ClassTable::~ClassTable() {
  if (old_tables_ != NULL) {
    FreeOldTables();
    delete old_tables_;
    free(table_);
    NOT_IN_PRODUCT(free(predefined_class_heap_stats_table_));
    NOT_IN_PRODUCT(free(class_heap_stats_table_));
  } else {
    // This instance was a shallow copy. It doesn't own any memory.
    NOT_IN_PRODUCT(ASSERT(predefined_class_heap_stats_table_ == NULL));
    NOT_IN_PRODUCT(ASSERT(class_heap_stats_table_ == NULL));
  }
}

void ClassTable::AddOldTable(ClassAndSize* old_table) {
  ASSERT(Thread::Current()->IsMutatorThread());
  old_tables_->Add(old_table);
}

void ClassTable::FreeOldTables() {
  while (old_tables_->length() > 0) {
    free(old_tables_->RemoveLast());
  }
}

#ifndef PRODUCT
void ClassTable::SetTraceAllocationFor(intptr_t cid, bool trace) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  stats->set_trace_allocation(trace);
}

bool ClassTable::TraceAllocationFor(intptr_t cid) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  return stats->trace_allocation();
}
#endif  // !PRODUCT

void ClassTable::Register(const Class& cls) {
  ASSERT(Thread::Current()->IsMutatorThread());
  intptr_t index = cls.id();
  if (index != kIllegalCid) {
    ASSERT(index > 0);
    ASSERT(index < kNumPredefinedCids);
    ASSERT(table_[index].class_ == NULL);
    ASSERT(index < capacity_);
    table_[index] = ClassAndSize(cls.raw(), Class::instance_size(cls.raw()));
    // Add the vtable for this predefined class into the static vtable registry
    // if it has not been setup yet.
    cpp_vtable cls_vtable = cls.handle_vtable();
    cpp_vtable old_cls_vtable = AtomicOperations::CompareAndSwapWord(
        &(Object::builtin_vtables_[index]), 0, cls_vtable);
    if (old_cls_vtable != 0) {
      ASSERT(old_cls_vtable == cls_vtable);
    }
  } else {
    if (top_ == capacity_) {
      // Grow the capacity of the class table.
      // TODO(koda): Add ClassTable::Grow to share code.

#ifndef PRODUCT
      // Wait for any marking tasks to complete. Allocation stats in the
      // marker rely on the class table size not changing.
      Thread* thread = Thread::Current();
      thread->heap()->WaitForMarkerTasks(thread);
#endif

      intptr_t new_capacity = capacity_ + capacity_increment_;
      ClassAndSize* new_table = reinterpret_cast<ClassAndSize*>(
          malloc(new_capacity * sizeof(ClassAndSize)));  // NOLINT
      memmove(new_table, table_, capacity_ * sizeof(ClassAndSize));
#ifndef PRODUCT
      ClassHeapStats* new_stats_table = reinterpret_cast<ClassHeapStats*>(
          realloc(class_heap_stats_table_,
                  new_capacity * sizeof(ClassHeapStats)));  // NOLINT
#endif
      for (intptr_t i = capacity_; i < new_capacity; i++) {
        new_table[i] = ClassAndSize(NULL, 0);
        NOT_IN_PRODUCT(new_stats_table[i].Initialize());
      }
      capacity_ = new_capacity;
      old_tables_->Add(table_);
      table_ = new_table;  // TODO(koda): This should use atomics.
      NOT_IN_PRODUCT(class_heap_stats_table_ = new_stats_table);
    }
    ASSERT(top_ < capacity_);
    if (!Class::is_valid_id(top_)) {
      FATAL1("Fatal error in ClassTable::Register: invalid index %" Pd "\n",
             top_);
    }
    cls.set_id(top_);
    table_[top_] = ClassAndSize(cls.raw());
    top_++;  // Increment next index.
  }
}

void ClassTable::AllocateIndex(intptr_t index) {
  if (index >= capacity_) {
    // Grow the capacity of the class table.
    // TODO(koda): Add ClassTable::Grow to share code.

#ifndef PRODUCT
    // Wait for any marking tasks to complete. Allocation stats in the
    // marker rely on the class table size not changing.
    Thread* thread = Thread::Current();
    thread->heap()->WaitForMarkerTasks(thread);
#endif

    intptr_t new_capacity = index + capacity_increment_;
    if (!Class::is_valid_id(index) || new_capacity < capacity_) {
      FATAL1("Fatal error in ClassTable::Register: invalid index %" Pd "\n",
             index);
    }
    ClassAndSize* new_table = reinterpret_cast<ClassAndSize*>(
        malloc(new_capacity * sizeof(ClassAndSize)));  // NOLINT
    memmove(new_table, table_, capacity_ * sizeof(ClassAndSize));
#ifndef PRODUCT
    ClassHeapStats* new_stats_table = reinterpret_cast<ClassHeapStats*>(
        realloc(class_heap_stats_table_,
                new_capacity * sizeof(ClassHeapStats)));  // NOLINT
#endif
    for (intptr_t i = capacity_; i < new_capacity; i++) {
      new_table[i] = ClassAndSize(NULL);
      NOT_IN_PRODUCT(new_stats_table[i].Initialize());
    }
    capacity_ = new_capacity;
    old_tables_->Add(table_);
    table_ = new_table;  // TODO(koda): This should use atomics.
    NOT_IN_PRODUCT(class_heap_stats_table_ = new_stats_table);
    ASSERT(capacity_increment_ >= 1);
  }

  ASSERT(table_[index].class_ == NULL);
  if (index >= top_) {
    top_ = index + 1;
  }
}

#if defined(DEBUG)
void ClassTable::Unregister(intptr_t index) {
  table_[index] = ClassAndSize(NULL);
}
#endif

void ClassTable::Remap(intptr_t* old_to_new_cid) {
  ASSERT(Thread::Current()->IsAtSafepoint());
  intptr_t num_cids = NumCids();
  ClassAndSize* cls_by_old_cid = new ClassAndSize[num_cids];
  for (intptr_t i = 0; i < num_cids; i++) {
    cls_by_old_cid[i] = table_[i];
  }
  for (intptr_t i = 0; i < num_cids; i++) {
    table_[old_to_new_cid[i]] = cls_by_old_cid[i];
  }
  delete[] cls_by_old_cid;
}

void ClassTable::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  for (intptr_t i = 0; i < top_; i++) {
    visitor->VisitPointer(reinterpret_cast<RawObject**>(&(table_[i].class_)));
  }
}

void ClassTable::CopySizesFromClassObjects() {
  ASSERT(kIllegalCid == 0);
  for (intptr_t i = 1; i < top_; i++) {
    SetAt(i, At(i));
  }
}

void ClassTable::Validate() {
  Class& cls = Class::Handle();
  for (intptr_t cid = kNumPredefinedCids; cid < top_; cid++) {
    // Some of the class table entries maybe NULL as we create some
    // top level classes but do not add them to the list of anonymous
    // classes in a library if there are no top level fields or functions.
    // Since there are no references to these top level classes they are
    // not written into a full snapshot and will not be recreated when
    // we read back the full snapshot. These class slots end up with NULL
    // entries.
    if (HasValidClassAt(cid)) {
      cls = At(cid);
      ASSERT(cls.IsClass());
      ASSERT(cls.id() == cid);
    }
  }
}

void ClassTable::Print() {
  Class& cls = Class::Handle();
  String& name = String::Handle();

  for (intptr_t i = 1; i < top_; i++) {
    if (!HasValidClassAt(i)) {
      continue;
    }
    cls = At(i);
    if (cls.raw() != reinterpret_cast<RawClass*>(0)) {
      name = cls.Name();
      OS::PrintErr("%" Pd ": %s\n", i, name.ToCString());
    }
  }
}

void ClassTable::SetAt(intptr_t index, RawClass* raw_cls) {
  ASSERT(index < capacity_);
  if (raw_cls == NULL) {
    table_[index] = ClassAndSize(raw_cls, 0);
  } else {
    table_[index] = ClassAndSize(raw_cls, Class::instance_size(raw_cls));
  }
}

ClassAndSize::ClassAndSize(RawClass* clazz) : class_(clazz) {
  size_ = clazz == NULL ? 0 : Class::instance_size(clazz);
}

#ifndef PRODUCT
void ClassTable::PrintToJSONObject(JSONObject* object) {
  if (!FLAG_support_service) {
    return;
  }
  Class& cls = Class::Handle();
  object->AddProperty("type", "ClassList");
  {
    JSONArray members(object, "classes");
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
  promoted_count = 0;
  promoted_size = 0;
  state_ = 0;
  USE(align_);
}

void ClassHeapStats::ResetAtNewGC() {
  Verify();
  pre_gc.new_count = post_gc.new_count + recent.new_count;
  pre_gc.new_size = post_gc.new_size + recent.new_size;
  pre_gc.new_external_size =
      post_gc.new_external_size + recent.new_external_size;
  // Accumulate allocations.
  accumulated.new_count += recent.new_count - last_reset.new_count;
  accumulated.new_size += recent.new_size - last_reset.new_size;
  accumulated.new_external_size +=
      recent.new_external_size - last_reset.new_external_size;
  last_reset.ResetNew();
  post_gc.ResetNew();
  recent.ResetNew();
  old_pre_new_gc_count_ = recent.old_count;
  old_pre_new_gc_size_ = recent.old_size;
}

void ClassHeapStats::ResetAtOldGC() {
  Verify();
  pre_gc.old_count = post_gc.old_count + recent.old_count;
  pre_gc.old_size = post_gc.old_size + recent.old_size;
  pre_gc.old_external_size =
      post_gc.old_external_size + recent.old_external_size;
  // Accumulate allocations.
  accumulated.old_count += recent.old_count - last_reset.old_count;
  accumulated.old_size += recent.old_size - last_reset.old_size;
  accumulated.old_external_size +=
      recent.old_external_size - last_reset.old_external_size;
  last_reset.ResetOld();
  post_gc.ResetOld();
  recent.ResetOld();
}

void ClassHeapStats::Verify() {
  pre_gc.Verify();
  post_gc.Verify();
  recent.Verify();
  accumulated.Verify();
  last_reset.Verify();
}

void ClassHeapStats::UpdateSize(intptr_t instance_size) {
  pre_gc.UpdateSize(instance_size);
  post_gc.UpdateSize(instance_size);
  recent.UpdateSize(instance_size);
  accumulated.UpdateSize(instance_size);
  last_reset.UpdateSize(instance_size);
  promoted_size = promoted_count * instance_size;
  old_pre_new_gc_size_ = old_pre_new_gc_count_ * instance_size;
}

void ClassHeapStats::ResetAccumulator() {
  // Remember how much was allocated so we can subtract this from the result
  // when printing.
  last_reset.new_count = recent.new_count;
  last_reset.new_size = recent.new_size;
  last_reset.new_external_size = recent.new_external_size;
  last_reset.old_count = recent.old_count;
  last_reset.old_size = recent.old_size;
  last_reset.old_external_size = recent.old_external_size;
  accumulated.Reset();
}

void ClassHeapStats::UpdatePromotedAfterNewGC() {
  promoted_count = recent.old_count - old_pre_new_gc_count_;
  promoted_size = recent.old_size - old_pre_new_gc_size_;
}

void ClassHeapStats::PrintToJSONObject(const Class& cls,
                                       JSONObject* obj) const {
  if (!FLAG_support_service) {
    return;
  }
  obj->AddProperty("type", "ClassHeapStats");
  obj->AddProperty("class", cls);
  {
    JSONArray new_stats(obj, "new");
    new_stats.AddValue(pre_gc.new_count);
    new_stats.AddValue(pre_gc.new_size + pre_gc.new_external_size);
    new_stats.AddValue(post_gc.new_count);
    new_stats.AddValue(post_gc.new_size + post_gc.new_external_size);
    new_stats.AddValue(recent.new_count);
    new_stats.AddValue(recent.new_size + recent.new_external_size);
    new_stats.AddValue64(accumulated.new_count + recent.new_count -
                         last_reset.new_count);
    new_stats.AddValue64(accumulated.new_size + accumulated.new_external_size +
                         recent.new_size + recent.new_external_size -
                         last_reset.new_size - last_reset.new_external_size);
  }
  {
    JSONArray old_stats(obj, "old");
    old_stats.AddValue(pre_gc.old_count);
    old_stats.AddValue(pre_gc.old_size + pre_gc.old_external_size);
    old_stats.AddValue(post_gc.old_count);
    old_stats.AddValue(post_gc.old_size + post_gc.old_external_size);
    old_stats.AddValue(recent.old_count);
    old_stats.AddValue(recent.old_size + recent.old_external_size);
    old_stats.AddValue64(accumulated.old_count + recent.old_count -
                         last_reset.old_count);
    old_stats.AddValue64(accumulated.old_size + accumulated.old_external_size +
                         recent.old_size + recent.old_external_size -
                         last_reset.old_size - last_reset.old_external_size);
  }
  obj->AddProperty("promotedInstances", promoted_count);
  obj->AddProperty("promotedBytes", promoted_size);
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

void ClassTable::UpdateAllocatedExternalNew(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  stats->recent.AddNewExternal(size);
}

void ClassTable::UpdateAllocatedExternalOld(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  stats->recent.AddOldExternal(size);
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
  if (!HasValidClassAt(cid) || (cid == kFreeListElement) ||
      (cid == kForwardingCorpse) || (cid == kSmiCid)) {
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
  stats->Verify();
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

void ClassTable::UpdatePromoted() {
  for (intptr_t i = 0; i < kNumPredefinedCids; i++) {
    predefined_class_heap_stats_table_[i].UpdatePromotedAfterNewGC();
  }
  for (intptr_t i = kNumPredefinedCids; i < top_; i++) {
    class_heap_stats_table_[i].UpdatePromotedAfterNewGC();
  }
}

ClassHeapStats** ClassTable::TableAddressFor(intptr_t cid) {
  return (cid < kNumPredefinedCids) ? &predefined_class_heap_stats_table_
                                    : &class_heap_stats_table_;
}

intptr_t ClassTable::TableOffsetFor(intptr_t cid) {
  return (cid < kNumPredefinedCids)
             ? OFFSET_OF(ClassTable, predefined_class_heap_stats_table_)
             : OFFSET_OF(ClassTable, class_heap_stats_table_);
}

intptr_t ClassTable::ClassOffsetFor(intptr_t cid) {
  return cid * sizeof(ClassHeapStats);  // NOLINT
}

intptr_t ClassTable::CounterOffsetFor(intptr_t cid, bool is_new_space) {
  const intptr_t class_offset = ClassOffsetFor(cid);
  const intptr_t count_field_offset =
      is_new_space ? ClassHeapStats::allocated_since_gc_new_space_offset()
                   : ClassHeapStats::allocated_since_gc_old_space_offset();
  return class_offset + count_field_offset;
}

intptr_t ClassTable::StateOffsetFor(intptr_t cid) {
  return ClassOffsetFor(cid) + ClassHeapStats::state_offset();
}

intptr_t ClassTable::SizeOffsetFor(intptr_t cid, bool is_new_space) {
  const uword class_offset = ClassOffsetFor(cid);
  const uword size_field_offset =
      is_new_space ? ClassHeapStats::allocated_size_since_gc_new_space_offset()
                   : ClassHeapStats::allocated_size_since_gc_old_space_offset();
  return class_offset + size_field_offset;
}

void ClassTable::AllocationProfilePrintJSON(JSONStream* stream) {
  if (!FLAG_support_service) {
    return;
  }
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  Heap* heap = isolate->heap();
  ASSERT(heap != NULL);
  JSONObject obj(stream);
  obj.AddProperty("type", "AllocationProfile");
  if (isolate->last_allocationprofile_accumulator_reset_timestamp() != 0) {
    obj.AddPropertyF(
        "dateLastAccumulatorReset", "%" Pd64 "",
        isolate->last_allocationprofile_accumulator_reset_timestamp());
  }
  if (isolate->last_allocationprofile_gc_timestamp() != 0) {
    obj.AddPropertyF("dateLastServiceGC", "%" Pd64 "",
                     isolate->last_allocationprofile_gc_timestamp());
  }

  {
    JSONObject heaps(&obj, "heaps");
    { heap->PrintToJSONObject(Heap::kNew, &heaps); }
    { heap->PrintToJSONObject(Heap::kOld, &heaps); }
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

void ClassTable::UpdateLiveOld(intptr_t cid, intptr_t size, intptr_t count) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  ASSERT(count >= 0);
  stats->post_gc.AddOld(size, count);
}

void ClassTable::UpdateLiveNew(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  stats->post_gc.AddNew(size);
}

void ClassTable::UpdateLiveOldExternal(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  stats->post_gc.AddOldExternal(size);
}

void ClassTable::UpdateLiveNewExternal(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  stats->post_gc.AddNewExternal(size);
}
#endif  // !PRODUCT

}  // namespace dart
