// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/field_table.h"

#include "platform/atomic.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/heap/heap.h"
#include "vm/object.h"
#include "vm/object_graph.h"
#include "vm/object_store.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

FieldTable::~FieldTable() {
  FreeOldTables();
  delete old_tables_;  // Allocated in FieldTable::FieldTable()
  free(table_);        // Allocated in FieldTable::Grow()
}

bool FieldTable::IsReadyToUse() const {
  DEBUG_ASSERT(
      IsolateGroup::Current()->IsReloading() ||
      IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
  return is_ready_to_use_;
}

void FieldTable::MarkReadyToUse() {
  // The isolate will mark it's field table ready-to-use upon initialization of
  // the isolate. Only after it was marked as ready-to-use will it participate
  // in new static field registrations.
  //
  // By requiring a read lock here we ensure no other thread is is registering a
  // new static field at this moment (it would need exclusive writer lock).
  DEBUG_ASSERT(
      IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
  ASSERT(!is_ready_to_use_);
  is_ready_to_use_ = true;
}

void FieldTable::FreeOldTables() {
  while (old_tables_->length() > 0) {
    free(old_tables_->RemoveLast());
  }
}

intptr_t FieldTable::FieldOffsetFor(intptr_t field_id) {
  return field_id * sizeof(ObjectPtr);  // NOLINT
}

bool FieldTable::Register(const Field& field, intptr_t expected_field_id) {
  DEBUG_ASSERT(
      IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  ASSERT(is_ready_to_use_);

  if (free_head_ < 0) {
    bool grown_backing_store = false;
    if (top_ == capacity_) {
      const intptr_t new_capacity = capacity_ + kCapacityIncrement;
      Grow(new_capacity);
      grown_backing_store = true;
    }

    ASSERT(top_ < capacity_);
    ASSERT(expected_field_id == -1 || expected_field_id == top_);
    field.set_field_id(top_);
    table_[top_] = Object::sentinel().ptr();

    ++top_;
    return grown_backing_store;
  }

  // Reuse existing free element. This is "slow path" that should only be
  // triggered after hot reload.
  intptr_t reused_free = free_head_;
  free_head_ = Smi::Value(Smi::RawCast(table_[free_head_]));
  field.set_field_id(reused_free);
  table_[reused_free] = Object::sentinel().ptr();
  return false;
}

void FieldTable::Free(intptr_t field_id) {
  table_[field_id] = Smi::New(free_head_);
  free_head_ = field_id;
}

void FieldTable::AllocateIndex(intptr_t index) {
  if (index >= capacity_) {
    const intptr_t new_capacity = index + kCapacityIncrement;
    Grow(new_capacity);
  }

  ASSERT(table_[index] == ObjectPtr());
  if (index >= top_) {
    top_ = index + 1;
  }
}

void FieldTable::Grow(intptr_t new_capacity) {
  ASSERT(new_capacity > capacity_);

  auto old_table = table_;
  auto new_table = static_cast<ObjectPtr*>(
      malloc(new_capacity * sizeof(ObjectPtr)));  // NOLINT
  intptr_t i;
  for (i = 0; i < top_; i++) {
    new_table[i] = old_table[i];
  }
  for (; i < new_capacity; i++) {
    new_table[i] = ObjectPtr();
  }
  capacity_ = new_capacity;
  old_tables_->Add(old_table);
  // Ensure that new_table_ is populated before it is published
  // via store to table_.
  reinterpret_cast<AcqRelAtomic<ObjectPtr*>*>(&table_)->store(new_table);
  if (isolate_ != nullptr && isolate_->mutator_thread() != nullptr) {
    isolate_->mutator_thread()->field_table_values_ = table_;
  }
}

FieldTable* FieldTable::Clone(Isolate* for_isolate) {
  DEBUG_ASSERT(
      IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());

  FieldTable* clone = new FieldTable(for_isolate);
  auto new_table =
      static_cast<ObjectPtr*>(malloc(capacity_ * sizeof(ObjectPtr)));  // NOLINT
  memmove(new_table, table_, capacity_ * sizeof(ObjectPtr));
  ASSERT(clone->table_ == nullptr);
  clone->table_ = new_table;
  clone->capacity_ = capacity_;
  clone->top_ = top_;
  clone->free_head_ = free_head_;
  return clone;
}

void FieldTable::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  // GC might try to visit field table before it's isolate done setting it up.
  if (table_ == nullptr) {
    return;
  }

  ASSERT(visitor != nullptr);
  visitor->set_gc_root_type("static fields table");
  visitor->VisitPointers(&table_[0], &table_[top_ - 1]);
  visitor->clear_gc_root_type();
}

}  // namespace dart
