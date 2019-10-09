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

SharedClassTable::SharedClassTable()
    : top_(kNumPredefinedCids),
      capacity_(0),
      table_(NULL),
      old_tables_(new MallocGrowableArray<intptr_t*>()) {
  if (Dart::vm_isolate() == NULL) {
    ASSERT(kInitialCapacity >= kNumPredefinedCids);
    capacity_ = kInitialCapacity;
    // Note that [calloc] will zero-initialize the memory.
    table_ = static_cast<intptr_t*>(calloc(capacity_, sizeof(intptr_t)));
  } else {
    // Duplicate the class table from the VM isolate.
    auto vm_shared_class_table = Dart::vm_isolate()->shared_class_table();
    capacity_ = vm_shared_class_table->capacity_;
    // Note that [calloc] will zero-initialize the memory.
    table_ = static_cast<intptr_t*>(calloc(capacity_, sizeof(RawClass*)));
    // The following cids don't have a corresponding class object in Dart code.
    // We therefore need to initialize them eagerly.
    for (intptr_t i = kObjectCid; i < kInstanceCid; i++) {
      table_[i] = vm_shared_class_table->SizeAt(i);
    }
    table_[kTypeArgumentsCid] =
        vm_shared_class_table->SizeAt(kTypeArgumentsCid);
    table_[kFreeListElement] = vm_shared_class_table->SizeAt(kFreeListElement);
    table_[kForwardingCorpse] =
        vm_shared_class_table->SizeAt(kForwardingCorpse);
    table_[kDynamicCid] = vm_shared_class_table->SizeAt(kDynamicCid);
    table_[kVoidCid] = vm_shared_class_table->SizeAt(kVoidCid);
  }
#ifndef PRODUCT
  class_heap_stats_table_ = static_cast<ClassHeapStats*>(
      malloc(capacity_ * sizeof(ClassHeapStats)));  // NOLINT
  for (intptr_t i = 0; i < capacity_; i++) {
    class_heap_stats_table_[i].Initialize();
  }
#endif  // !PRODUCT
}
SharedClassTable::~SharedClassTable() {
  if (old_tables_ != NULL) {
    FreeOldTables();
    delete old_tables_;
    free(table_);
  }
  NOT_IN_PRODUCT(free(class_heap_stats_table_));
}

ClassTable::ClassTable(SharedClassTable* shared_class_table)
    : top_(kNumPredefinedCids),
      capacity_(0),
      table_(NULL),
      old_tables_(new MallocGrowableArray<ClassAndSize*>()),
      old_class_tables_(new MallocGrowableArray<RawClass**>()),
      shared_class_table_(shared_class_table) {
  if (Dart::vm_isolate() == NULL) {
    ASSERT(kInitialCapacity >= kNumPredefinedCids);
    capacity_ = kInitialCapacity;
    // Note that [calloc] will zero-initialize the memory.
    table_ = static_cast<RawClass**>(calloc(capacity_, sizeof(RawClass*)));
  } else {
    // Duplicate the class table from the VM isolate.
    ClassTable* vm_class_table = Dart::vm_isolate()->class_table();
    capacity_ = vm_class_table->capacity_;
    // Note that [calloc] will zero-initialize the memory.
    table_ = static_cast<RawClass**>(calloc(capacity_, sizeof(RawClass*)));
    // The following cids don't have a corresponding class object in Dart code.
    // We therefore need to initialize them eagerly.
    for (intptr_t i = kObjectCid; i < kInstanceCid; i++) {
      table_[i] = vm_class_table->At(i);
    }
    table_[kTypeArgumentsCid] = vm_class_table->At(kTypeArgumentsCid);
    table_[kFreeListElement] = vm_class_table->At(kFreeListElement);
    table_[kForwardingCorpse] = vm_class_table->At(kForwardingCorpse);
    table_[kDynamicCid] = vm_class_table->At(kDynamicCid);
    table_[kVoidCid] = vm_class_table->At(kVoidCid);
  }
}

ClassTable::ClassTable(ClassTable* original,
                       SharedClassTable* shared_class_table)
    : top_(original->top_),
      capacity_(original->top_),
      table_(original->table_),
      old_tables_(nullptr),
      old_class_tables_(nullptr),
      shared_class_table_(shared_class_table) {}

ClassTable::~ClassTable() {
  if (old_tables_ != nullptr || old_class_tables_ != nullptr) {
    FreeOldTables();
    delete old_tables_;
    delete old_class_tables_;
  }
  free(table_);
}

void ClassTable::AddOldTable(ClassAndSize* old_table) {
  ASSERT(Thread::Current()->IsMutatorThread());
  old_tables_->Add(old_table);
}

void ClassTable::FreeOldTables() {
  while (old_tables_->length() > 0) {
    free(old_tables_->RemoveLast());
  }
  while (old_class_tables_->length() > 0) {
    free(old_class_tables_->RemoveLast());
  }
}

void SharedClassTable::FreeOldTables() {
  while (old_tables_->length() > 0) {
    free(old_tables_->RemoveLast());
  }
}

void ClassTable::Register(const Class& cls) {
  ASSERT(Thread::Current()->IsMutatorThread());

  const intptr_t index = cls.id();

  // During the transition period we would like [SharedClassTable] to operate in
  // parallel to [ClassTable].
  const intptr_t expected_cid =
      shared_class_table_->Register(index, Class::instance_size(cls.raw()));

  if (index != kIllegalCid) {
    ASSERT(index > 0 && index < kNumPredefinedCids && index < top_);
    ASSERT(table_[index] == nullptr);
    table_[index] = cls.raw();

    // Add the vtable for this predefined class into the static vtable registry
    // if it has not been setup yet.
    cpp_vtable cls_vtable = cls.handle_vtable();
    cpp_vtable old_cls_vtable = 0;
    if (!Object::builtin_vtables_[index].compare_exchange_strong(old_cls_vtable,
                                                                 cls_vtable)) {
      // Lost the race, but the other thread installed the same value.
      ASSERT(old_cls_vtable == cls_vtable);
    }
  } else {
    if (top_ == capacity_) {
      const intptr_t new_capacity = capacity_ + kCapacityIncrement;
      Grow(new_capacity);
    }
    ASSERT(top_ < capacity_);
    cls.set_id(top_);
    table_[top_] = cls.raw();
    top_++;  // Increment next index.
  }
  ASSERT(expected_cid == cls.id());
}

intptr_t SharedClassTable::Register(intptr_t index, intptr_t size) {
  if (!Class::is_valid_id(top_)) {
    FATAL1("Fatal error in SharedClassTable::Register: invalid index %" Pd "\n",
           top_);
  }

  ASSERT(Thread::Current()->IsMutatorThread());
  if (index != kIllegalCid) {
    // We are registring the size of a predefined class.
    ASSERT(index > 0 && index < kNumPredefinedCids);
    SetSizeAt(index, size);
    return index;
  } else {
    if (top_ == capacity_) {
      const intptr_t new_capacity = capacity_ + kCapacityIncrement;
      Grow(new_capacity);
    }
    ASSERT(top_ < capacity_);
    table_[top_] = size;
    return top_++;  // Increment next index.
  }
}

void ClassTable::AllocateIndex(intptr_t index) {
  // This is called by a snapshot reader.
  shared_class_table_->AllocateIndex(index);
  ASSERT(Class::is_valid_id(index));

  if (index >= capacity_) {
    const intptr_t new_capacity = index + kCapacityIncrement;
    Grow(new_capacity);
  }

  ASSERT(table_[index] == nullptr);
  if (index >= top_) {
    top_ = index + 1;
  }

  ASSERT(top_ == shared_class_table_->top_);
  ASSERT(capacity_ == shared_class_table_->capacity_);
}

void ClassTable::Grow(intptr_t new_capacity) {
  ASSERT(new_capacity > capacity_);

  auto new_table = static_cast<RawClass**>(
      malloc(new_capacity * sizeof(RawClass*)));  // NOLINT
  memmove(new_table, table_, top_ * sizeof(RawClass*));
  memset(new_table + top_, 0, (new_capacity - top_) * sizeof(RawClass*));
  capacity_ = new_capacity;
  old_class_tables_->Add(table_);
  table_ = new_table;  // TODO(koda): This should use atomics.
}

void SharedClassTable::AllocateIndex(intptr_t index) {
  // This is called by a snapshot reader.
  ASSERT(Class::is_valid_id(index));

  if (index >= capacity_) {
    const intptr_t new_capacity = index + kCapacityIncrement;
    Grow(new_capacity);
  }

  ASSERT(table_[index] == 0);
  if (index >= top_) {
    top_ = index + 1;
  }
}

void SharedClassTable::Grow(intptr_t new_capacity) {
  ASSERT(new_capacity >= capacity_);

#ifndef PRODUCT
  // Wait for any marking tasks to complete. Allocation stats in the
  // marker rely on the class table size not changing.
  Thread* thread = Thread::Current();
  thread->heap()->WaitForMarkerTasks(thread);
#endif

  intptr_t* new_table = static_cast<intptr_t*>(
      malloc(new_capacity * sizeof(intptr_t)));  // NOLINT
  memmove(new_table, table_, top_ * sizeof(intptr_t));
  memset(new_table + top_, 0, (new_capacity - top_) * sizeof(intptr_t));
#ifndef PRODUCT
  auto new_stats_table = static_cast<ClassHeapStats*>(
      realloc(class_heap_stats_table_,
              new_capacity * sizeof(ClassHeapStats)));  // NOLINT
#endif
  for (intptr_t i = capacity_; i < new_capacity; i++) {
    new_table[i] = 0;
    NOT_IN_PRODUCT(new_stats_table[i].Initialize());
  }
  capacity_ = new_capacity;
  old_tables_->Add(table_);
  table_ = new_table;  // TODO(koda): This should use atomics.
  NOT_IN_PRODUCT(class_heap_stats_table_ = new_stats_table);
}

void ClassTable::Unregister(intptr_t index) {
  shared_class_table_->Unregister(index);
  table_[index] = nullptr;
}

void SharedClassTable::Unregister(intptr_t index) {
  table_[index] = 0;
}

void ClassTable::Remap(intptr_t* old_to_new_cid) {
  ASSERT(Thread::Current()->IsAtSafepoint());
  shared_class_table_->Remap(old_to_new_cid);

  const intptr_t num_cids = NumCids();
  auto cls_by_old_cid = new RawClass*[num_cids];
  memmove(cls_by_old_cid, table_, sizeof(RawClass*) * num_cids);
  for (intptr_t i = 0; i < num_cids; i++) {
    table_[old_to_new_cid[i]] = cls_by_old_cid[i];
  }
  delete[] cls_by_old_cid;
}

void SharedClassTable::Remap(intptr_t* old_to_new_cid) {
  ASSERT(Thread::Current()->IsAtSafepoint());
  const intptr_t num_cids = NumCids();
  intptr_t* cls_by_old_cid = new intptr_t[num_cids];
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
  visitor->set_gc_root_type("class table");
  for (intptr_t i = 0; i < top_; i++) {
    visitor->VisitPointer(reinterpret_cast<RawObject**>(&(table_[i])));
  }
  visitor->clear_gc_root_type();
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
  // This is called by snapshot reader and class finalizer.
  ASSERT(index < capacity_);
  const intptr_t size = raw_cls == nullptr ? 0 : Class::instance_size(raw_cls);
  shared_class_table_->SetSizeAt(index, size);
  table_[index] = raw_cls;
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
  pre_gc.old_external_size =
      post_gc.old_external_size + recent.old_external_size;
  // Accumulate allocations.
  accumulated.new_count += recent.new_count - last_reset.new_count;
  accumulated.new_size += recent.new_size - last_reset.new_size;
  accumulated.new_external_size +=
      recent.new_external_size - last_reset.new_external_size;
  accumulated.old_external_size +=
      recent.old_external_size - last_reset.old_external_size;
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
  pre_gc.new_external_size =
      post_gc.new_external_size + recent.new_external_size;
  // Accumulate allocations.
  accumulated.old_count += recent.old_count - last_reset.old_count;
  accumulated.old_size += recent.old_size - last_reset.old_size;
  accumulated.old_external_size +=
      recent.old_external_size - last_reset.old_external_size;
  accumulated.new_external_size +=
      recent.new_external_size - last_reset.new_external_size;
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
                                       JSONObject* obj,
                                       bool internal) const {
  if (!FLAG_support_service) {
    return;
  }
  obj->AddProperty("type", "ClassHeapStats");
  obj->AddProperty("class", cls);
  int64_t accumulated_new =
      accumulated.new_count + recent.new_count - last_reset.new_count;
  int64_t accumulated_old =
      accumulated.old_count + recent.old_count - last_reset.old_count;
  int64_t accumulated_new_size =
      accumulated.new_size + accumulated.new_external_size + recent.new_size +
      recent.new_external_size - last_reset.new_size -
      last_reset.new_external_size;
  int64_t accumulated_old_size =
      accumulated.old_size + accumulated.old_external_size + recent.old_size +
      recent.old_external_size - last_reset.old_size -
      last_reset.old_external_size;
  int64_t instances_new = post_gc.new_count + recent.new_count;
  int64_t instances_old = post_gc.old_count + recent.old_count;
  int64_t live_after_gc_size_new = post_gc.new_size + post_gc.new_external_size;
  int64_t live_after_gc_size_old = post_gc.old_size + post_gc.old_external_size;
  int64_t allocated_since_gc_size_new =
      recent.new_size + recent.new_external_size;
  int64_t allocated_since_gc_size_old =
      recent.old_size + recent.old_external_size;
  int64_t bytes_current = live_after_gc_size_new + live_after_gc_size_old +
                          allocated_since_gc_size_new +
                          allocated_since_gc_size_old;
  if (internal) {
    {
      JSONArray new_stats(obj, "_new");
      new_stats.AddValue(pre_gc.new_count);
      new_stats.AddValue(pre_gc.new_size + pre_gc.new_external_size);
      new_stats.AddValue(post_gc.new_count);
      new_stats.AddValue64(live_after_gc_size_new);
      new_stats.AddValue(recent.new_count);
      new_stats.AddValue64(allocated_since_gc_size_new);
      new_stats.AddValue64(accumulated_new);
      new_stats.AddValue64(accumulated_new_size);
    }
    {
      JSONArray old_stats(obj, "_old");
      old_stats.AddValue(pre_gc.old_count);
      old_stats.AddValue(pre_gc.old_size + pre_gc.old_external_size);
      old_stats.AddValue(post_gc.old_count);
      old_stats.AddValue64(live_after_gc_size_old);
      old_stats.AddValue(recent.old_count);
      old_stats.AddValue64(allocated_since_gc_size_old);
      old_stats.AddValue64(accumulated_old);
      old_stats.AddValue64(accumulated_old_size);
    }
    obj->AddProperty("_promotedInstances", promoted_count);
    obj->AddProperty("_promotedBytes", promoted_size);
  }
  obj->AddProperty64("instancesAccumulated", accumulated_new + accumulated_old);
  obj->AddProperty64("accumulatedSize",
                     accumulated_new_size + accumulated_old_size);
  obj->AddProperty64("instancesCurrent", instances_new + instances_old);
  obj->AddProperty64("bytesCurrent", bytes_current);
}

void SharedClassTable::UpdateAllocatedOldGC(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size != 0);
  stats->recent.AddOldGC(size);
}

void SharedClassTable::UpdateAllocatedExternalNew(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  stats->recent.AddNewExternal(size);
}

void SharedClassTable::UpdateAllocatedExternalOld(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  stats->recent.AddOldExternal(size);
}

bool SharedClassTable::ShouldUpdateSizeForClassId(intptr_t cid) {
  return !RawObject::IsVariableSizeClassId(cid);
}

ClassHeapStats* ClassTable::StatsWithUpdatedSize(intptr_t cid) {
  if (!HasValidClassAt(cid) || cid == kFreeListElement ||
      cid == kForwardingCorpse || cid == kSmiCid) {
    return NULL;
  }
  Class& cls = Class::Handle(At(cid));
  if (!(cls.is_finalized() || cls.is_prefinalized())) {
    // Not finalized.
    return NULL;
  }
  return shared_class_table_->StatsWithUpdatedSize(cid, cls.instance_size());
}

ClassHeapStats* SharedClassTable::StatsWithUpdatedSize(intptr_t cid,
                                                       intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  if (ShouldUpdateSizeForClassId(cid)) {
    stats->UpdateSize(size);
  }
  stats->Verify();
  return stats;
}

void SharedClassTable::ResetCountersOld() {
  for (intptr_t i = 0; i < top_; i++) {
    class_heap_stats_table_[i].ResetAtOldGC();
  }
}

void SharedClassTable::ResetCountersNew() {
  for (intptr_t i = 0; i < top_; i++) {
    class_heap_stats_table_[i].ResetAtNewGC();
  }
}

void SharedClassTable::UpdatePromoted() {
  for (intptr_t i = 0; i < top_; i++) {
    class_heap_stats_table_[i].UpdatePromotedAfterNewGC();
  }
}

intptr_t SharedClassTable::ClassOffsetFor(intptr_t cid) {
  return cid * sizeof(ClassHeapStats);  // NOLINT
}

intptr_t SharedClassTable::NewSpaceCounterOffsetFor(intptr_t cid) {
  const intptr_t class_offset = ClassOffsetFor(cid);
  const intptr_t count_field_offset =
      ClassHeapStats::allocated_since_gc_new_space_offset();
  return class_offset + count_field_offset;
}

intptr_t SharedClassTable::StateOffsetFor(intptr_t cid) {
  return ClassOffsetFor(cid) + ClassHeapStats::state_offset();
}

intptr_t SharedClassTable::NewSpaceSizeOffsetFor(intptr_t cid) {
  const uword class_offset = ClassOffsetFor(cid);
  const uword size_field_offset =
      ClassHeapStats::allocated_size_since_gc_new_space_offset();
  return class_offset + size_field_offset;
}

void ClassTable::AllocationProfilePrintJSON(JSONStream* stream, bool internal) {
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

  if (internal) {
    JSONObject heaps(&obj, "_heaps");
    { heap->PrintToJSONObject(Heap::kNew, &heaps); }
    { heap->PrintToJSONObject(Heap::kOld, &heaps); }
  }

  {
    JSONObject memory(&obj, "memoryUsage");
    { heap->PrintMemoryUsageJSON(&memory); }
  }

  {
    JSONArray arr(&obj, "members");
    Class& cls = Class::Handle();
    for (intptr_t i = 1; i < top_; i++) {
      const ClassHeapStats* stats = StatsWithUpdatedSize(i);
      if (stats != NULL) {
        JSONObject obj(&arr);
        cls = At(i);
        stats->PrintToJSONObject(cls, &obj, internal);
      }
    }
  }
}

void SharedClassTable::ResetAllocationAccumulators() {
  for (intptr_t i = 1; i < top_; i++) {
    if (HasValidClassAt(i)) {
      const intptr_t size = table_[i];
      ClassHeapStats* stats = StatsWithUpdatedSize(i, size);
      if (stats != NULL) {
        stats->ResetAccumulator();
      }
    }
  }
}

void SharedClassTable::UpdateLiveOld(intptr_t cid,
                                     intptr_t size,
                                     intptr_t count) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  ASSERT(count >= 0);
  stats->post_gc.AddOld(size, count);
}

void SharedClassTable::UpdateLiveNew(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  stats->post_gc.AddNew(size);
}

void SharedClassTable::UpdateLiveNewGC(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  stats->post_gc.AddNewGC(size);
}

void SharedClassTable::UpdateLiveOldExternal(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  stats->post_gc.AddOldExternal(size);
}

void SharedClassTable::UpdateLiveNewExternal(intptr_t cid, intptr_t size) {
  ClassHeapStats* stats = PreliminaryStatsAt(cid);
  ASSERT(stats != NULL);
  ASSERT(size >= 0);
  stats->post_gc.AddNewExternal(size);
}
#endif  // !PRODUCT

}  // namespace dart
