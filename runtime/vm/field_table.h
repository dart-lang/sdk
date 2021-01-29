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
#include "vm/tagged_pointer.h"

namespace dart {

class Isolate;
class Field;

class FieldTable {
 public:
  explicit FieldTable(Isolate* isolate)
      : top_(0),
        capacity_(0),
        free_head_(-1),
        table_(nullptr),
        old_tables_(new MallocGrowableArray<InstancePtr*>()),
        isolate_(isolate),
        is_ready_to_use_(isolate == nullptr) {}

  ~FieldTable();

  bool IsReadyToUse() const;
  void MarkReadyToUse();

  intptr_t NumFieldIds() const { return top_; }
  intptr_t Capacity() const { return capacity_; }

  InstancePtr* table() { return table_; }

  void FreeOldTables();

  // Used by the generated code.
  static intptr_t FieldOffsetFor(intptr_t field_id);

  bool IsValidIndex(intptr_t index) const { return index >= 0 && index < top_; }

  // Returns whether registering this field caused a growth in the backing
  // store.
  bool Register(const Field& field, intptr_t expected_field_id = -1);
  void AllocateIndex(intptr_t index);

  // Static field elements are being freed only during isolate reload
  // when initially created static field have to get remapped to point
  // to an existing static field value.
  void Free(intptr_t index);

  InstancePtr At(intptr_t index) const {
    ASSERT(IsValidIndex(index));
    return table_[index];
  }
  void SetAt(intptr_t index, InstancePtr raw_instance);

  FieldTable* Clone(Isolate* for_isolate);

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

  InstancePtr* table_;
  // When table_ grows and have to reallocated, keep the old one here
  // so it will get freed when its are no longer in use.
  MallocGrowableArray<InstancePtr*>* old_tables_;

  // If non-NULL, it will specify the isolate this field table belongs to.
  // Growing the field table will keep the cached field table on the isolate's
  // mutator thread up-to-date.
  Isolate* isolate_;

  // Whether this field table is ready to use by e.g. registering new static
  // fields.
  bool is_ready_to_use_ = false;

  DISALLOW_COPY_AND_ASSIGN(FieldTable);
};

}  // namespace dart

#endif  // RUNTIME_VM_FIELD_TABLE_H_
