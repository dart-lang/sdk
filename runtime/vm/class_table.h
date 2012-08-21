// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CLASS_TABLE_H_
#define VM_CLASS_TABLE_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/globals.h"

namespace dart {

class Class;
class ObjectPointerVisitor;
class RawClass;

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

  void Register(const Class& cls);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void Print();

  static intptr_t table_offset() {
    return OFFSET_OF(ClassTable, table_);
  }

 private:
  static const int initial_capacity_ = 512;
  static const int capacity_increment_ = 256;

  intptr_t top_;
  intptr_t capacity_;

  RawClass** table_;

  DISALLOW_COPY_AND_ASSIGN(ClassTable);
};

}  // namespace dart

#endif  // VM_CLASS_TABLE_H_
