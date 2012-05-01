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
    : top_(kNumPredefinedKinds), capacity_(initial_capacity_), table_(NULL) {
  table_ = reinterpret_cast<RawClass**>(calloc(capacity_,
                                               sizeof(RawClass*)));  // NOLINT
  // Duplicate the class table from the VM isolate.
  if (Dart::vm_isolate() != NULL) {
    ClassTable* vm_class_table = Dart::vm_isolate()->class_table();
    for (int i = kObject; i < kInstance; i++) {
      table_[i] = vm_class_table->At(i);
    }
    table_[kNullClassIndex] = vm_class_table->At(kNullClassIndex);
    table_[kDynamicClassIndex] = vm_class_table->At(kDynamicClassIndex);
    table_[kVoidClassIndex] = vm_class_table->At(kVoidClassIndex);
  }
}


ClassTable::~ClassTable() {
  free(table_);
}


void ClassTable::Register(const Class& cls) {
  intptr_t index = cls.index();
  if (index != kIllegalObjectKind) {
    ASSERT(index > 0);
    ASSERT(index < kNumPredefinedKinds);
    ASSERT(table_[index] == 0);
    table_[index] = cls.raw();
  } else {
    cls.set_index(top_);
    table_[top_] = cls.raw();
    top_++;  // Increment next index.
    ASSERT(top_ < capacity_);
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
