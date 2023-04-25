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

ClassTable::ClassTable(ClassTableAllocator* allocator)
    : allocator_(allocator),
      classes_(allocator),
      top_level_classes_(allocator) {
  if (Dart::vm_isolate() == nullptr) {
    classes_.SetNumCidsAndCapacity(kNumPredefinedCids, kInitialCapacity);
  } else {
    // Duplicate the class table from the VM isolate.
    ClassTable* vm_class_table = Dart::vm_isolate_group()->class_table();
    classes_.SetNumCidsAndCapacity(kNumPredefinedCids,
                                   vm_class_table->classes_.capacity());

    const auto copy_info_for_cid = [&](intptr_t cid) {
      classes_.At<kClassIndex>(cid) = vm_class_table->At(cid);
      classes_.At<kSizeIndex>(cid) = vm_class_table->SizeAt(cid);
    };

    // The following cids don't have a corresponding class object in Dart code.
    // We therefore need to initialize them eagerly.
    COMPILE_ASSERT(kFirstInternalOnlyCid == kObjectCid + 1);
    for (intptr_t i = kObjectCid; i <= kLastInternalOnlyCid; i++) {
      copy_info_for_cid(i);
    }
    copy_info_for_cid(kTypeArgumentsCid);
    copy_info_for_cid(kFreeListElement);
    copy_info_for_cid(kForwardingCorpse);
    copy_info_for_cid(kDynamicCid);
    copy_info_for_cid(kVoidCid);
  }
  UpdateCachedAllocationTracingStateTablePointer();
}

ClassTable::~ClassTable() {
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  for (intptr_t i = 1; i < classes_.num_cids(); i++) {
    const char* name = UserVisibleNameFor(i);
    if (name != nullptr) {
      free(const_cast<char*>(name));
    }
  }
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
}

void ClassTable::Register(const Class& cls) {
  ASSERT(Thread::Current()->IsDartMutatorThread());
  ASSERT(cls.id() == kIllegalCid || cls.id() < kNumPredefinedCids);
  bool did_grow = false;
  const classid_t cid =
      cls.id() != kIllegalCid ? cls.id() : classes_.AddRow(&did_grow);
  ASSERT(!IsTopLevelCid(cid));

  const intptr_t instance_size =
      cls.is_abstract() ? 0 : Class::host_instance_size(cls.ptr());

  cls.set_id(cid);
  classes_.At<kClassIndex>(cid) = cls.ptr();
  classes_.At<kSizeIndex>(cid) = static_cast<int32_t>(instance_size);
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  classes_.At<kClassNameIndex>(cid) = nullptr;
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)

  if (did_grow) {
    IsolateGroup::Current()->set_cached_class_table_table(
        classes_.GetColumn<kClassIndex>());
    UpdateCachedAllocationTracingStateTablePointer();
  } else {
    std::atomic_thread_fence(std::memory_order_release);
  }
}

void ClassTable::RegisterTopLevel(const Class& cls) {
  ASSERT(Thread::Current()->IsDartMutatorThread());
  ASSERT(cls.id() == kIllegalCid);

  bool did_grow = false;
  const intptr_t index = top_level_classes_.AddRow(&did_grow);
  cls.set_id(ClassTable::CidFromTopLevelIndex(index));
  top_level_classes_.At<kClassIndex>(index) = cls.ptr();
}

void ClassTable::AllocateIndex(intptr_t index) {
  bool did_grow = false;
  if (IsTopLevelCid(index)) {
    top_level_classes_.AllocateIndex(IndexFromTopLevelCid(index), &did_grow);
    return;
  }

  classes_.AllocateIndex(index, &did_grow);
  if (did_grow) {
    IsolateGroup::Current()->set_cached_class_table_table(table());
    UpdateCachedAllocationTracingStateTablePointer();
  }
}

void ClassTable::UnregisterTopLevel(intptr_t cid) {
  ASSERT(IsTopLevelCid(cid));
  const intptr_t tlc_index = IndexFromTopLevelCid(cid);
  top_level_classes_.At<kClassIndex>(tlc_index) = nullptr;
}

void ClassTable::Remap(intptr_t* old_to_new_cid) {
  ASSERT(Thread::Current()->OwnsSafepoint());
  classes_.Remap(old_to_new_cid);
}

void ClassTable::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != nullptr);
  visitor->set_gc_root_type("class table");

  const auto visit = [&](ClassPtr* table, intptr_t num_cids) {
    if (num_cids == 0) {
      return;
    }
    ObjectPtr* from = reinterpret_cast<ObjectPtr*>(&table[0]);
    ObjectPtr* to = reinterpret_cast<ObjectPtr*>(&table[num_cids - 1]);
    visitor->VisitPointers(from, to);
  };

  visit(classes_.GetColumn<kClassIndex>(), classes_.num_cids());
  visit(top_level_classes_.GetColumn<kClassIndex>(),
        top_level_classes_.num_cids());
  visitor->clear_gc_root_type();
}

void ClassTable::CopySizesFromClassObjects() {
  ASSERT(kIllegalCid == 0);
  for (intptr_t i = 1; i < classes_.num_cids(); i++) {
    UpdateClassSize(i, classes_.At<kClassIndex>(i));
  }
}

void ClassTable::SetAt(intptr_t cid, ClassPtr raw_cls) {
  if (IsTopLevelCid(cid)) {
    top_level_classes_.At<kClassIndex>(IndexFromTopLevelCid(cid)) = raw_cls;
    return;
  }

  // This is called by snapshot reader and class finalizer.
  UpdateClassSize(cid, raw_cls);
  classes_.At<kClassIndex>(cid) = raw_cls;
}

void ClassTable::UpdateClassSize(intptr_t cid, ClassPtr raw_cls) {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  ASSERT(!IsTopLevelCid(cid));  // "top-level" classes don't get instantiated
  const intptr_t size =
      raw_cls == nullptr ? 0 : Class::host_instance_size(raw_cls);
  classes_.At<kSizeIndex>(cid) = static_cast<int32_t>(size);
}

void ClassTable::Validate() {
  Class& cls = Class::Handle();
  for (intptr_t cid = kNumPredefinedCids; cid < classes_.num_cids(); cid++) {
    // Some of the class table entries maybe nullptr as we create some
    // top level classes but do not add them to the list of anonymous
    // classes in a library if there are no top level fields or functions.
    // Since there are no references to these top level classes they are
    // not written into a full snapshot and will not be recreated when
    // we read back the full snapshot. These class slots end up with nullptr
    // entries.
    if (HasValidClassAt(cid)) {
      cls = At(cid);
      ASSERT(cls.IsClass());
#if defined(DART_PRECOMPILER)
      // Precompiler can drop classes and set their id() to kIllegalCid.
      // It still leaves them in the class table so dropped program
      // structure could still be accessed while writing debug info.
      ASSERT((cls.id() == cid) || (cls.id() == kIllegalCid));
#else
      ASSERT(cls.id() == cid);
#endif  // defined(DART_PRECOMPILER)
    }
  }
}

void ClassTable::Print() {
  Class& cls = Class::Handle();
  String& name = String::Handle();

  for (intptr_t i = 1; i < classes_.num_cids(); i++) {
    if (!HasValidClassAt(i)) {
      continue;
    }
    cls = At(i);
    if (cls.ptr() != nullptr) {
      name = cls.Name();
      OS::PrintErr("%" Pd ": %s\n", i, name.ToCString());
    }
  }
}

#if defined(DART_PRECOMPILER)
void ClassTable::PrintObjectLayout(const char* filename) {
  Class& cls = Class::Handle();
  Array& fields = Array::Handle();
  Field& field = Field::Handle();

  JSONWriter js;
  js.OpenArray();
  for (intptr_t i = ClassId::kObjectCid; i < classes_.num_cids(); i++) {
    if (!HasValidClassAt(i)) {
      continue;
    }
    cls = At(i);
    ASSERT(!cls.IsNull());
    ASSERT(cls.id() != kIllegalCid);
    ASSERT(cls.is_finalized());  // Precompiler already finalized all classes.
    ASSERT(!cls.IsTopLevel());
    js.OpenObject();
    js.PrintProperty("class", cls.UserVisibleNameCString());
    js.PrintProperty("size", cls.target_instance_size());
    js.OpenArray("fields");
    fields = cls.fields();
    if (!fields.IsNull()) {
      for (intptr_t i = 0, n = fields.Length(); i < n; ++i) {
        field ^= fields.At(i);
        js.OpenObject();
        js.PrintProperty("field", field.UserVisibleNameCString());
        if (field.is_static()) {
          js.PrintPropertyBool("static", true);
        } else {
          js.PrintProperty("offset", field.TargetOffset());
        }
        js.CloseObject();
      }
    }
    js.CloseArray();
    js.CloseObject();
  }
  js.CloseArray();

  auto file_open = Dart::file_open_callback();
  auto file_write = Dart::file_write_callback();
  auto file_close = Dart::file_close_callback();
  if ((file_open == nullptr) || (file_write == nullptr) ||
      (file_close == nullptr)) {
    OS::PrintErr("warning: Could not access file callbacks.");
    return;
  }

  void* file = file_open(filename, /*write=*/true);
  if (file == nullptr) {
    OS::PrintErr("warning: Failed to write object layout: %s\n", filename);
    return;
  }

  char* output = nullptr;
  intptr_t output_length = 0;
  js.Steal(&output, &output_length);
  file_write(output, output_length, file);
  free(output);
  file_close(file);
}
#endif  // defined(DART_PRECOMPILER)

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
void ClassTable::PopulateUserVisibleNames() {
  Class& cls = Class::Handle();
  for (intptr_t i = 0; i < classes_.num_cids(); ++i) {
    if (HasValidClassAt(i) && UserVisibleNameFor(i) == nullptr) {
      cls = At(i);
      cls.SetUserVisibleNameInClassTable();
    }
  }
}
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)

#if !defined(PRODUCT)

void ClassTable::PrintToJSONObject(JSONObject* object) {
  Class& cls = Class::Handle();
  object->AddProperty("type", "ClassList");
  {
    JSONArray members(object, "classes");
    for (intptr_t i = ClassId::kObjectCid; i < classes_.num_cids(); i++) {
      if (HasValidClassAt(i)) {
        cls = At(i);
        members.AddValue(cls);
      }
    }
  }
}

void ClassTable::AllocationProfilePrintJSON(JSONStream* stream, bool internal) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != nullptr);
  auto isolate_group = isolate->group();
  Heap* heap = isolate_group->heap();
  ASSERT(heap != nullptr);
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
    for (intptr_t i = 3; i < classes_.num_cids(); i++) {
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

ClassTableAllocator::ClassTableAllocator()
    : pending_freed_(new MallocGrowableArray<std::pair<void*, Deleter>>()) {}

ClassTableAllocator::~ClassTableAllocator() {
  FreePending();
  delete pending_freed_;
}

void ClassTableAllocator::Free(ClassTable* ptr) {
  if (ptr != nullptr) {
    pending_freed_->Add(std::make_pair(
        ptr, [](void* ptr) { delete static_cast<ClassTable*>(ptr); }));
  }
}

void ClassTableAllocator::Free(void* ptr) {
  if (ptr != nullptr) {
    pending_freed_->Add(std::make_pair(ptr, nullptr));
  }
}

void ClassTableAllocator::FreePending() {
  while (!pending_freed_->is_empty()) {
    auto [ptr, deleter] = pending_freed_->RemoveLast();
    if (deleter == nullptr) {
      free(ptr);
    } else {
      deleter(ptr);
    }
  }
}

}  // namespace dart
