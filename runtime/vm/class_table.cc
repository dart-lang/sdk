// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_table.h"

#include <limits>
#include <memory>

#include "platform/atomic.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/heap/heap.h"
#include "vm/object.h"
#include "vm/object_graph.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, print_class_table, false, "Print initial class table.");

SharedClassTable::SharedClassTable()
    : top_(kNumPredefinedCids),
      capacity_(0),
      old_tables_(new MallocGrowableArray<void*>()) {
  if (Dart::vm_isolate() == NULL) {
    ASSERT(kInitialCapacity >= kNumPredefinedCids);
    capacity_ = kInitialCapacity;
    // Note that [calloc] will zero-initialize the memory.
    table_.store(reinterpret_cast<RelaxedAtomic<intptr_t>*>(
        calloc(capacity_, sizeof(RelaxedAtomic<intptr_t>))));
  } else {
    // Duplicate the class table from the VM isolate.
    auto vm_shared_class_table =
        Dart::vm_isolate()->group()->shared_class_table();
    capacity_ = vm_shared_class_table->capacity_;
    // Note that [calloc] will zero-initialize the memory.
    RelaxedAtomic<intptr_t>* table = reinterpret_cast<RelaxedAtomic<intptr_t>*>(
        calloc(capacity_, sizeof(RelaxedAtomic<intptr_t>)));
    // The following cids don't have a corresponding class object in Dart code.
    // We therefore need to initialize them eagerly.
    for (intptr_t i = kObjectCid; i < kInstanceCid; i++) {
      table[i] = vm_shared_class_table->SizeAt(i);
    }
    table[kTypeArgumentsCid] = vm_shared_class_table->SizeAt(kTypeArgumentsCid);
    table[kFreeListElement] = vm_shared_class_table->SizeAt(kFreeListElement);
    table[kForwardingCorpse] = vm_shared_class_table->SizeAt(kForwardingCorpse);
    table[kDynamicCid] = vm_shared_class_table->SizeAt(kDynamicCid);
    table[kVoidCid] = vm_shared_class_table->SizeAt(kVoidCid);
    table_.store(table);
  }
#if defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
  // Note that [calloc] will zero-initialize the memory.
  unboxed_fields_map_ = static_cast<UnboxedFieldBitmap*>(
      calloc(capacity_, sizeof(UnboxedFieldBitmap)));
#endif  // defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
#ifndef PRODUCT
  // Note that [calloc] will zero-initialize the memory.
  trace_allocation_table_.store(
      static_cast<uint8_t*>(calloc(capacity_, sizeof(uint8_t))));
#endif  // !PRODUCT
}
SharedClassTable::~SharedClassTable() {
  if (old_tables_ != NULL) {
    FreeOldTables();
    delete old_tables_;
  }
  free(table_.load());
  free(unboxed_fields_map_);

  NOT_IN_PRODUCT(free(trace_allocation_table_.load()));
}

void ClassTable::set_table(ClassPtr* table) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != nullptr);
  table_.store(table);
  isolate->set_cached_class_table_table(table);
}

ClassTable::ClassTable(SharedClassTable* shared_class_table)
    : top_(kNumPredefinedCids),
      capacity_(0),
      tlc_top_(0),
      tlc_capacity_(0),
      table_(nullptr),
      tlc_table_(nullptr),
      old_class_tables_(new MallocGrowableArray<ClassPtr*>()),
      shared_class_table_(shared_class_table) {
  if (Dart::vm_isolate() == NULL) {
    ASSERT(kInitialCapacity >= kNumPredefinedCids);
    capacity_ = kInitialCapacity;
    // Note that [calloc] will zero-initialize the memory.
    // Don't use set_table because caller is supposed to set up isolates
    // cached copy when constructing ClassTable. Isolate::Current might not
    // be available at this point yet.
    table_.store(static_cast<ClassPtr*>(calloc(capacity_, sizeof(ClassPtr))));
  } else {
    // Duplicate the class table from the VM isolate.
    ClassTable* vm_class_table = Dart::vm_isolate()->class_table();
    capacity_ = vm_class_table->capacity_;
    // Note that [calloc] will zero-initialize the memory.
    ClassPtr* table =
        static_cast<ClassPtr*>(calloc(capacity_, sizeof(ClassPtr)));
    // The following cids don't have a corresponding class object in Dart code.
    // We therefore need to initialize them eagerly.
    for (intptr_t i = kObjectCid; i < kInstanceCid; i++) {
      table[i] = vm_class_table->At(i);
    }
    table[kTypeArgumentsCid] = vm_class_table->At(kTypeArgumentsCid);
    table[kFreeListElement] = vm_class_table->At(kFreeListElement);
    table[kForwardingCorpse] = vm_class_table->At(kForwardingCorpse);
    table[kDynamicCid] = vm_class_table->At(kDynamicCid);
    table[kVoidCid] = vm_class_table->At(kVoidCid);
    // Don't use set_table because caller is supposed to set up isolates
    // cached copy when constructing ClassTable. Isolate::Current might not
    // be available at this point yet.
    table_.store(table);
  }
}

ClassTable::~ClassTable() {
  if (old_class_tables_ != nullptr) {
    FreeOldTables();
    delete old_class_tables_;
  }
  free(table_.load());
  free(tlc_table_.load());
}

void ClassTable::AddOldTable(ClassPtr* old_class_table) {
  ASSERT(Thread::Current()->IsMutatorThread());
  old_class_tables_->Add(old_class_table);
}

void ClassTable::FreeOldTables() {
  while (old_class_tables_->length() > 0) {
    free(old_class_tables_->RemoveLast());
  }
}

void SharedClassTable::AddOldTable(intptr_t* old_table) {
  ASSERT(Thread::Current()->IsMutatorThread());
  old_tables_->Add(old_table);
}

void SharedClassTable::FreeOldTables() {
  while (old_tables_->length() > 0) {
    free(old_tables_->RemoveLast());
  }
}

void ClassTable::Register(const Class& cls) {
  ASSERT(Thread::Current()->IsMutatorThread());

  const classid_t cid = cls.id();
  ASSERT(!IsTopLevelCid(cid));

  // During the transition period we would like [SharedClassTable] to operate in
  // parallel to [ClassTable].

  const intptr_t instance_size =
      cls.is_abstract() ? 0 : Class::host_instance_size(cls.raw());

  const intptr_t expected_cid =
      shared_class_table_->Register(cid, instance_size);

  if (cid != kIllegalCid) {
    ASSERT(cid > 0 && cid < kNumPredefinedCids && cid < top_);
    ASSERT(table_.load()[cid] == nullptr);
    table_.load()[cid] = cls.raw();
  } else {
    if (top_ == capacity_) {
      const intptr_t new_capacity = capacity_ + kCapacityIncrement;
      Grow(new_capacity);
    }
    ASSERT(top_ < capacity_);
    cls.set_id(top_);
    table_.load()[top_] = cls.raw();
    top_++;  // Increment next index.
  }
  ASSERT(expected_cid == cls.id());
}

void ClassTable::RegisterTopLevel(const Class& cls) {
  if (top_ >= std::numeric_limits<classid_t>::max()) {
    FATAL1("Fatal error in ClassTable::RegisterTopLevel: invalid index %" Pd
           "\n",
           top_);
  }

  ASSERT(Thread::Current()->IsMutatorThread());

  const intptr_t index = cls.id();
  ASSERT(index == kIllegalCid);

  if (tlc_top_ == tlc_capacity_) {
    const intptr_t new_capacity = tlc_capacity_ + kCapacityIncrement;
    GrowTopLevel(new_capacity);
  }
  ASSERT(tlc_top_ < tlc_capacity_);
  cls.set_id(ClassTable::CidFromTopLevelIndex(tlc_top_));
  tlc_table_.load()[tlc_top_] = cls.raw();
  tlc_top_++;  // Increment next index.
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
    ASSERT(size == 0);
    if (top_ == capacity_) {
      const intptr_t new_capacity = capacity_ + kCapacityIncrement;
      Grow(new_capacity);
    }
    ASSERT(top_ < capacity_);
    table_.load()[top_] = size;
    return top_++;  // Increment next index.
  }
}

void ClassTable::AllocateIndex(intptr_t index) {
  if (IsTopLevelCid(index)) {
    AllocateTopLevelIndex(index);
    return;
  }

  // This is called by a snapshot reader.
  shared_class_table_->AllocateIndex(index);
  ASSERT(Class::is_valid_id(index));

  if (index >= capacity_) {
    const intptr_t new_capacity = index + kCapacityIncrement;
    Grow(new_capacity);
  }

  ASSERT(table_.load()[index] == nullptr);
  if (index >= top_) {
    top_ = index + 1;
  }

  ASSERT(top_ == shared_class_table_->top_);
  ASSERT(capacity_ == shared_class_table_->capacity_);
}

void ClassTable::AllocateTopLevelIndex(intptr_t cid) {
  ASSERT(IsTopLevelCid(cid));
  const intptr_t tlc_index = IndexFromTopLevelCid(cid);

  if (tlc_index >= tlc_capacity_) {
    const intptr_t new_capacity = tlc_index + kCapacityIncrement;
    GrowTopLevel(new_capacity);
  }

  ASSERT(tlc_table_.load()[tlc_index] == nullptr);
  if (tlc_index >= tlc_top_) {
    tlc_top_ = tlc_index + 1;
  }
}

void ClassTable::Grow(intptr_t new_capacity) {
  ASSERT(new_capacity > capacity_);

  auto old_table = table_.load();
  auto new_table = static_cast<ClassPtr*>(
      malloc(new_capacity * sizeof(ClassPtr)));  // NOLINT
  intptr_t i;
  for (i = 0; i < capacity_; i++) {
    // Don't use memmove, which changes this from a relaxed atomic operation
    // to a non-atomic operation.
    new_table[i] = old_table[i];
  }
  for (; i < new_capacity; i++) {
    // Don't use memset, which changes this from a relaxed atomic operation
    // to a non-atomic operation.
    new_table[i] = 0;
  }
  old_class_tables_->Add(old_table);
  set_table(new_table);

  capacity_ = new_capacity;
}

void ClassTable::GrowTopLevel(intptr_t new_capacity) {
  ASSERT(new_capacity > tlc_capacity_);

  auto old_table = tlc_table_.load();
  auto new_table = static_cast<ClassPtr*>(
      malloc(new_capacity * sizeof(ClassPtr)));  // NOLINT
  intptr_t i;
  for (i = 0; i < tlc_capacity_; i++) {
    // Don't use memmove, which changes this from a relaxed atomic operation
    // to a non-atomic operation.
    new_table[i] = old_table[i];
  }
  for (; i < new_capacity; i++) {
    // Don't use memset, which changes this from a relaxed atomic operation
    // to a non-atomic operation.
    new_table[i] = 0;
  }
  old_class_tables_->Add(old_table);

  tlc_table_.store(new_table);
  tlc_capacity_ = new_capacity;
}

void SharedClassTable::AllocateIndex(intptr_t index) {
  // This is called by a snapshot reader.
  ASSERT(Class::is_valid_id(index));

  if (index >= capacity_) {
    const intptr_t new_capacity = index + kCapacityIncrement;
    Grow(new_capacity);
  }

  ASSERT(table_.load()[index] == 0);
  if (index >= top_) {
    top_ = index + 1;
  }
}

void SharedClassTable::Grow(intptr_t new_capacity) {
  ASSERT(new_capacity >= capacity_);

  RelaxedAtomic<intptr_t>* old_table = table_.load();
  RelaxedAtomic<intptr_t>* new_table =
      reinterpret_cast<RelaxedAtomic<intptr_t>*>(
          malloc(new_capacity * sizeof(RelaxedAtomic<intptr_t>)));  // NOLINT

  intptr_t i;
  for (i = 0; i < capacity_; i++) {
    // Don't use memmove, which changes this from a relaxed atomic operation
    // to a non-atomic operation.
    new_table[i] = old_table[i];
  }
  for (; i < new_capacity; i++) {
    // Don't use memset, which changes this from a relaxed atomic operation
    // to a non-atomic operation.
    new_table[i] = 0;
  }

#if !defined(PRODUCT)
  auto old_trace_table = trace_allocation_table_.load();
  auto new_trace_table =
      static_cast<uint8_t*>(malloc(new_capacity * sizeof(uint8_t)));  // NOLINT
  for (i = 0; i < capacity_; i++) {
    // Don't use memmove, which changes this from a relaxed atomic operation
    // to a non-atomic operation.
    new_trace_table[i] = old_trace_table[i];
  }
  for (; i < new_capacity; i++) {
    // Don't use memset, which changes this from a relaxed atomic operation
    // to a non-atomic operation.
    new_trace_table[i] = 0;
  }
#endif

  old_tables_->Add(old_table);
  table_.store(new_table);
  NOT_IN_PRODUCT(old_tables_->Add(old_trace_table));
  NOT_IN_PRODUCT(trace_allocation_table_.store(new_trace_table));

#if defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
  auto old_unboxed_fields_map = unboxed_fields_map_;
  auto new_unboxed_fields_map = static_cast<UnboxedFieldBitmap*>(
      malloc(new_capacity * sizeof(UnboxedFieldBitmap)));
  for (i = 0; i < capacity_; i++) {
    // Don't use memmove, which changes this from a relaxed atomic operation
    // to a non-atomic operation.
    new_unboxed_fields_map[i] = old_unboxed_fields_map[i];
  }
  for (; i < new_capacity; i++) {
    // Don't use memset, which changes this from a relaxed atomic operation
    // to a non-atomic operation.
    new_unboxed_fields_map[i] = UnboxedFieldBitmap(0);
  }
  old_tables_->Add(old_unboxed_fields_map);
  unboxed_fields_map_ = new_unboxed_fields_map;
#endif  // defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)

  capacity_ = new_capacity;
}

void ClassTable::Unregister(intptr_t cid) {
  ASSERT(!IsTopLevelCid(cid));
  shared_class_table_->Unregister(cid);
  table_.load()[cid] = nullptr;
}

void ClassTable::UnregisterTopLevel(intptr_t cid) {
  ASSERT(IsTopLevelCid(cid));
  const intptr_t tlc_index = IndexFromTopLevelCid(cid);
  tlc_table_.load()[tlc_index] = nullptr;
}

void SharedClassTable::Unregister(intptr_t index) {
  table_.load()[index] = 0;
#if defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
  unboxed_fields_map_[index].Reset();
#endif  // defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
}

void ClassTable::Remap(intptr_t* old_to_new_cid) {
  ASSERT(Thread::Current()->IsAtSafepoint());
  const intptr_t num_cids = NumCids();
  std::unique_ptr<ClassPtr[]> cls_by_old_cid(new ClassPtr[num_cids]);
  auto* table = table_.load();
  memmove(cls_by_old_cid.get(), table, sizeof(ClassPtr) * num_cids);
  for (intptr_t i = 0; i < num_cids; i++) {
    table[old_to_new_cid[i]] = cls_by_old_cid[i];
  }
}

void SharedClassTable::Remap(intptr_t* old_to_new_cid) {
  ASSERT(Thread::Current()->IsAtSafepoint());
  const intptr_t num_cids = NumCids();
  std::unique_ptr<intptr_t[]> size_by_old_cid(new intptr_t[num_cids]);
  auto* table = table_.load();
  for (intptr_t i = 0; i < num_cids; i++) {
    size_by_old_cid[i] = table[i];
  }
  for (intptr_t i = 0; i < num_cids; i++) {
    table[old_to_new_cid[i]] = size_by_old_cid[i];
  }

#if defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
  std::unique_ptr<UnboxedFieldBitmap[]> unboxed_fields_by_old_cid(
      new UnboxedFieldBitmap[num_cids]);
  for (intptr_t i = 0; i < num_cids; i++) {
    unboxed_fields_by_old_cid[i] = unboxed_fields_map_[i];
  }
  for (intptr_t i = 0; i < num_cids; i++) {
    unboxed_fields_map_[old_to_new_cid[i]] = unboxed_fields_by_old_cid[i];
  }
#endif  // defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
}

void ClassTable::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->set_gc_root_type("class table");
  if (top_ != 0) {
    auto* table = table_.load();
    ObjectPtr* from = reinterpret_cast<ObjectPtr*>(&table[0]);
    ObjectPtr* to = reinterpret_cast<ObjectPtr*>(&table[top_ - 1]);
    visitor->VisitPointers(from, to);
  }
  if (tlc_top_ != 0) {
    auto* tlc_table = tlc_table_.load();
    ObjectPtr* from = reinterpret_cast<ObjectPtr*>(&tlc_table[0]);
    ObjectPtr* to = reinterpret_cast<ObjectPtr*>(&tlc_table[tlc_top_ - 1]);
    visitor->VisitPointers(from, to);
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
    if (cls.raw() != nullptr) {
      name = cls.Name();
      OS::PrintErr("%" Pd ": %s\n", i, name.ToCString());
    }
  }
}

void ClassTable::SetAt(intptr_t cid, ClassPtr raw_cls) {
  if (IsTopLevelCid(cid)) {
    tlc_table_.load()[IndexFromTopLevelCid(cid)] = raw_cls;
    return;
  }

  // This is called by snapshot reader and class finalizer.
  ASSERT(cid < capacity_);
  const intptr_t size =
      raw_cls == nullptr ? 0 : Class::host_instance_size(raw_cls);
  shared_class_table_->SetSizeAt(cid, size);
  table_.load()[cid] = raw_cls;
}

#ifndef PRODUCT
void ClassTable::PrintToJSONObject(JSONObject* object) {
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

bool SharedClassTable::ShouldUpdateSizeForClassId(intptr_t cid) {
  return !IsVariableSizeClassId(cid);
}

intptr_t SharedClassTable::ClassOffsetFor(intptr_t cid) {
  return cid * sizeof(uint8_t);  // NOLINT
}


void ClassTable::AllocationProfilePrintJSON(JSONStream* stream, bool internal) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  auto isolate_group = isolate->group();
  Heap* heap = isolate_group->heap();
  ASSERT(heap != NULL);
  JSONObject obj(stream);
  obj.AddProperty("type", "AllocationProfile");
  if (isolate_group->last_allocationprofile_accumulator_reset_timestamp() !=
      0) {
    obj.AddPropertyF(
        "dateLastAccumulatorReset", "%" Pd64 "",
        isolate_group->last_allocationprofile_accumulator_reset_timestamp());
  }
  if (isolate_group->last_allocationprofile_gc_timestamp() != 0) {
    obj.AddPropertyF("dateLastServiceGC", "%" Pd64 "",
                     isolate_group->last_allocationprofile_gc_timestamp());
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

  Thread* thread = Thread::Current();
  CountObjectsVisitor visitor(thread, NumCids());
  {
    HeapIterationScope iter(thread);
    iter.IterateObjects(&visitor);
    isolate->group()->VisitWeakPersistentHandles(&visitor);
  }

  {
    JSONArray arr(&obj, "members");
    Class& cls = Class::Handle();
    for (intptr_t i = 3; i < top_; i++) {
      if (!HasValidClassAt(i)) continue;

      cls = At(i);
      if (cls.IsNull()) continue;

      JSONObject obj(&arr);
      obj.AddProperty("type", "ClassHeapStats");
      obj.AddProperty("class", cls);
      intptr_t count = visitor.new_count_[i] + visitor.old_count_[i];
      intptr_t size = visitor.new_size_[i] + visitor.old_size_[i];
      obj.AddProperty64("instancesAccumulated", count);
      obj.AddProperty64("accumulatedSize", size);
      obj.AddProperty64("instancesCurrent", count);
      obj.AddProperty64("bytesCurrent", size);

      if (internal) {
        {
          JSONArray new_stats(&obj, "_new");
          new_stats.AddValue(visitor.new_count_[i]);
          new_stats.AddValue(visitor.new_size_[i]);
          new_stats.AddValue(visitor.new_external_size_[i]);
        }
        {
          JSONArray old_stats(&obj, "_old");
          old_stats.AddValue(visitor.old_count_[i]);
          old_stats.AddValue(visitor.old_size_[i]);
          old_stats.AddValue(visitor.old_external_size_[i]);
        }
      }
    }
  }
}
#endif  // !PRODUCT

}  // namespace dart
