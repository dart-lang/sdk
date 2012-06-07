// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_table.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, print_class_table, false, "Print initial class table.");

ClassTable::ClassTable()
    : top_(kNumPredefinedKinds), capacity_(0), table_(NULL) {
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
    for (intptr_t i = kObject; i < kInstance; i++) {
      table_[i] = vm_class_table->At(i);
    }
    table_[kNullClassId] = vm_class_table->At(kNullClassId);
    table_[kDynamicClassId] = vm_class_table->At(kDynamicClassId);
    table_[kVoidClassId] = vm_class_table->At(kVoidClassId);
  }
}


ClassTable::~ClassTable() {
  free(table_);
}


void ClassTable::Register(const Class& cls) {
  intptr_t index = cls.id();
  if (index != kIllegalObjectKind) {
    ASSERT(index > 0);
    ASSERT(index < kNumPredefinedKinds);
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

}  // namespace dart
