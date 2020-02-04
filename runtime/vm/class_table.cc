// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_table.h"

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
      table_(NULL),
      old_tables_(new MallocGrowableArray<intptr_t*>()),
      unboxed_fields_map_(nullptr),
      old_unboxed_fields_maps_(new MallocGrowableArray<UnboxedFieldBitmap*>()) {
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
    table_[kNeverCid] = vm_shared_class_table->SizeAt(kNeverCid);
  }
#if defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
  unboxed_fields_map_ = static_cast<UnboxedFieldBitmap*>(
      malloc(capacity_ * sizeof(UnboxedFieldBitmap)));
  memset(unboxed_fields_map_, 0, sizeof(UnboxedFieldBitmap) * capacity_);
#endif  // defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
#ifndef PRODUCT
  trace_allocation_table_ =
      static_cast<uint8_t*>(malloc(capacity_ * sizeof(uint8_t)));  // NOLINT
  for (intptr_t i = 0; i < capacity_; i++) {
    trace_allocation_table_[i] = 0;
  }
#endif  // !PRODUCT
}
SharedClassTable::~SharedClassTable() {
  if (old_tables_ != NULL) {
    FreeOldTables();
    delete old_tables_;
    free(table_);
  }

  if (old_unboxed_fields_maps_ != nullptr) {
    FreeOldUnboxedFieldsMaps();
    delete old_unboxed_fields_maps_;
  }

  if (unboxed_fields_map_ != nullptr) {
    free(unboxed_fields_map_);
  }

  NOT_IN_PRODUCT(free(trace_allocation_table_));
}

ClassTable::ClassTable(SharedClassTable* shared_class_table)
    : top_(kNumPredefinedCids),
      capacity_(0),
      table_(NULL),
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
    table_[kNeverCid] = vm_class_table->At(kNeverCid);
  }
}

ClassTable::ClassTable(ClassTable* original,
                       SharedClassTable* shared_class_table)
    : top_(original->top_),
      capacity_(original->top_),
      table_(original->table_),
      old_class_tables_(nullptr),
      shared_class_table_(shared_class_table) {}

ClassTable::~ClassTable() {
  if (old_class_tables_ != nullptr) {
    FreeOldTables();
    delete old_class_tables_;
  }
  free(table_);
}

void ClassTable::AddOldTable(RawClass** old_class_table) {
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

void SharedClassTable::FreeOldUnboxedFieldsMaps() {
  while (old_unboxed_fields_maps_->length() > 0) {
    free(old_unboxed_fields_maps_->RemoveLast());
  }
}

void ClassTable::Register(const Class& cls) {
  ASSERT(Thread::Current()->IsMutatorThread());

  const intptr_t index = cls.id();

  // During the transition period we would like [SharedClassTable] to operate in
  // parallel to [ClassTable].

  const intptr_t instance_size =
      cls.is_abstract() ? 0 : Class::host_instance_size(cls.raw());

  const intptr_t expected_cid =
      shared_class_table_->Register(index, instance_size);

  if (index != kIllegalCid) {
    ASSERT(index > 0 && index < kNumPredefinedCids && index < top_);
    ASSERT(table_[index] == nullptr);
    table_[index] = cls.raw();
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
    ASSERT(size == 0);
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

  intptr_t* new_table = static_cast<intptr_t*>(
      malloc(new_capacity * sizeof(intptr_t)));  // NOLINT

  memmove(new_table, table_, top_ * sizeof(intptr_t));
  memset(new_table + top_, 0, (new_capacity - top_) * sizeof(intptr_t));
#ifndef PRODUCT
  auto new_stats_table =
      static_cast<uint8_t*>(realloc(trace_allocation_table_,
                                    new_capacity * sizeof(uint8_t)));  // NOLINT
#endif
  for (intptr_t i = capacity_; i < new_capacity; i++) {
    new_table[i] = 0;
    NOT_IN_PRODUCT(new_stats_table[i] = 0);
  }

  capacity_ = new_capacity;
  old_tables_->Add(table_);
  table_ = new_table;  // TODO(koda): This should use atomics.
  NOT_IN_PRODUCT(trace_allocation_table_ = new_stats_table);

#if defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
  auto new_unboxed_fields_map = static_cast<UnboxedFieldBitmap*>(
      malloc(new_capacity * sizeof(UnboxedFieldBitmap)));
  memmove(new_unboxed_fields_map, unboxed_fields_map_,
          top_ * sizeof(UnboxedFieldBitmap));
  memset(new_unboxed_fields_map + top_, 0,
         (new_capacity - top_) * sizeof(UnboxedFieldBitmap));
  old_unboxed_fields_maps_->Add(unboxed_fields_map_);
  unboxed_fields_map_ = new_unboxed_fields_map;
#endif  // defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
}

void ClassTable::Unregister(intptr_t index) {
  shared_class_table_->Unregister(index);
  table_[index] = nullptr;
}

void SharedClassTable::Unregister(intptr_t index) {
  table_[index] = 0;
#if defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
  unboxed_fields_map_[index].Reset();
#endif  // defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
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
  std::unique_ptr<intptr_t[]> cls_by_old_cid(new intptr_t[num_cids]);
  for (intptr_t i = 0; i < num_cids; i++) {
    cls_by_old_cid[i] = table_[i];
  }
  for (intptr_t i = 0; i < num_cids; i++) {
    table_[old_to_new_cid[i]] = cls_by_old_cid[i];
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
  const intptr_t size =
      raw_cls == nullptr ? 0 : Class::host_instance_size(raw_cls);
  shared_class_table_->SetSizeAt(index, size);
  table_[index] = raw_cls;
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
  return !RawObject::IsVariableSizeClassId(cid);
}

intptr_t SharedClassTable::ClassOffsetFor(intptr_t cid) {
  return cid * sizeof(uint8_t);  // NOLINT
}


void ClassTable::AllocationProfilePrintJSON(JSONStream* stream, bool internal) {
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

  Thread* thread = Thread::Current();
  CountObjectsVisitor visitor(thread, NumCids());
  {
    HeapIterationScope iter(thread);
    iter.IterateObjects(&visitor);
    isolate->VisitWeakPersistentHandles(&visitor);
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
