// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_FIELD_TABLE_H_
#define RUNTIME_VM_FIELD_TABLE_H_

#include "platform/assert.h"
#include "platform/atomic.h"

#include "vm/bitfield.h"
#include "vm/class_id.h"
#include "vm/globals.h"
#include "vm/growable_array.h"

namespace dart {

class Field;
class RawInstance;

class FieldTable {
 public:
  FieldTable()
      : top_(0),
        capacity_(0),
        free_head_(-1),
        table_(nullptr),
        old_tables_(new MallocGrowableArray<RawInstance**>()) {}

  ~FieldTable();

  intptr_t NumFieldIds() const { return top_; }
  intptr_t Capacity() const { return capacity_; }

  RawInstance** table() { return table_; }

  void FreeOldTables();

  // Used by the generated code.
  static intptr_t FieldOffsetFor(intptr_t field_id);

  bool IsValidIndex(intptr_t index) const { return index >= 0 && index < top_; }

  void Register(const Field& field);
  void AllocateIndex(intptr_t index);

  // Static field elements are being freed only during isolate reload
  // when initially created static field have to get remapped to point
  // to an existing static field value.
  void Free(intptr_t index);

  RawInstance* At(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_[index];
  }
  void SetAt(intptr_t index, RawInstance* raw_instance);

  FieldTable* Clone();

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  static const int kInitialCapacity = 512;
  static const int kCapacityIncrement = 256;

 private:
  friend class GCMarker;
  friend class MarkingWeakVisitor;
  friend class Scavenger;
  friend class ScavengerWeakVisitor;

  void Grow(intptr_t new_capacity);

  intptr_t top_;
  intptr_t capacity_;
  // -1 if free list is empty, otherwise index of first empty element. Empty
  // elements are organized into linked list - they contain index of next
  // element, last element contains -1.
  intptr_t free_head_;

  RawInstance** table_;
  // When table_ grows and have to reallocated, keep the old one here
  // so it will get freed when its are no longer in use.
  MallocGrowableArray<RawInstance**>* old_tables_;

  DISALLOW_COPY_AND_ASSIGN(FieldTable);
};

}  // namespace dart

#endif  // RUNTIME_VM_FIELD_TABLE_H_
