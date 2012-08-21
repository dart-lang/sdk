// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_table.h"
#include "vm/flags.h"
#include "vm/freelist.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, print_class_table, false, "Print initial class table.");

ClassTable::ClassTable()
    : top_(kNumPredefinedCids), capacity_(0), table_(NULL) {
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
    table_[kNullCid] = vm_class_table->At(kNullCid);
    table_[kDynamicCid] = vm_class_table->At(kDynamicCid);
    table_[kVoidCid] = vm_class_table->At(kVoidCid);
  }
}


ClassTable::~ClassTable() {
  free(table_);
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
      for (intptr_t i = capacity_; i < new_capacity; i++) {
        new_table[i] = NULL;
      }
      capacity_ = new_capacity;
      table_ = new_table;
    }
    ASSERT(top_ < capacity_);
    cls.set_id(top_);
    table_[top_] = cls.raw();
    top_++;  // Increment next index.
  }
}


void ClassTable::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->VisitPointers(reinterpret_cast<RawObject**>(&table_[0]), top_);
}


void ClassTable::Print() {
  Class& cls = Class::Handle();
  String& name = String::Handle();

  for (intptr_t i = 1; i < top_; i++) {
    cls = At(i);
    if (cls.raw() != reinterpret_cast<RawClass*>(0)) {
      name = cls.Name();
      OS::Print("%d: %s\n", i, name.ToCString());
    }
  }
}


bool ClassTable::HasSubclasses(intptr_t cid) const {
  const Class& cls = Class::Handle(At(cid));
  ASSERT(!cls.IsNull());
  // TODO(regis): Replace assert below with ASSERT(cid > kDartObjectCid).
  ASSERT(!cls.IsObjectClass());
  const GrowableObjectArray& cls_direct_subclasses =
      GrowableObjectArray::Handle(cls.direct_subclasses());
  return
      !cls_direct_subclasses.IsNull() && (cls_direct_subclasses.Length() > 0);
}


// Returns true if the given array of cids contains the given cid.
static bool ContainsCid(ZoneGrowableArray<intptr_t>* cids, intptr_t cid) {
  for (intptr_t i = 0; i < cids->length(); i++) {
    if ((*cids)[i] == cid) {
      return true;
    }
  }
  return false;
}


// Recursively collect direct and indirect subclass ids of cls.
static void CollectSubclassIds(ZoneGrowableArray<intptr_t>* cids,
                               const Class& cls) {
  const GrowableObjectArray& cls_direct_subclasses =
      GrowableObjectArray::Handle(cls.direct_subclasses());
  if (cls_direct_subclasses.IsNull()) {
    return;
  }
  Class& direct_subclass = Class::Handle();
  for (intptr_t i = 0; i < cls_direct_subclasses.Length(); i++) {
    direct_subclass ^= cls_direct_subclasses.At(i);
    intptr_t direct_subclass_id = direct_subclass.id();
    if (!ContainsCid(cids, direct_subclass_id)) {
      cids->Add(direct_subclass_id);
      CollectSubclassIds(cids, direct_subclass);
    }
  }
}


ZoneGrowableArray<intptr_t>* ClassTable::GetSubclassIdsOf(intptr_t cid) const {
  const Class& cls = Class::Handle(At(cid));
  ASSERT(!cls.IsNull());
  // TODO(regis): Replace assert below with ASSERT(cid > kDartObjectCid).
  ASSERT(!cls.IsObjectClass());
  ZoneGrowableArray<intptr_t>* ids = new ZoneGrowableArray<intptr_t>();
  CollectSubclassIds(ids, cls);
  return ids;
}


ZoneGrowableArray<Function*>* ClassTable::GetNamedInstanceFunctionsOf(
    const ZoneGrowableArray<intptr_t>& cids,
    const String& function_name) const {
  ASSERT(!function_name.IsNull());
  ZoneGrowableArray<Function*>* functions = new ZoneGrowableArray<Function*>();
  Class& cls = Class::Handle();
  Function& cls_function = Function::Handle();
  for (intptr_t i = 0; i < cids.length(); i++) {
    const intptr_t cid = cids[i];
    cls = At(cid);
    // TODO(regis): Replace assert below with ASSERT(cid > kDartObjectCid).
    ASSERT(!cls.IsObjectClass());
    cls_function = cls.LookupDynamicFunction(function_name);
    if (!cls_function.IsNull()) {
      functions->Add(&Function::ZoneHandle(cls_function.raw()));
    }
  }
  return functions;
}


ZoneGrowableArray<Function*>* ClassTable::GetOverridesOf(
    const Function& function) const {
  ASSERT(!function.IsNull());
  ASSERT(function.IsDynamicFunction());
  const Class& function_owner = Class::Handle(function.Owner());
  const String& function_name = String::Handle(function.name());
  ZoneGrowableArray<intptr_t>* cids = new ZoneGrowableArray<intptr_t>();
  CollectSubclassIds(cids, function_owner);
  return GetNamedInstanceFunctionsOf(*cids, function_name);
}

}  // namespace dart
