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

void FieldTable::FreeOldTables() {
  while (old_tables_->length() > 0) {
    free(old_tables_->RemoveLast());
  }
}

intptr_t FieldTable::FieldOffsetFor(intptr_t field_id) {
  return field_id * sizeof(RawInstance*);  // NOLINT
}

void FieldTable::Register(const Field& field) {
  ASSERT(Thread::Current()->IsMutatorThread());
  if (free_head_ < 0) {
    if (top_ == capacity_) {
      const intptr_t new_capacity = capacity_ + kCapacityIncrement;
      Grow(new_capacity);
    }

    ASSERT(top_ < capacity_);

    field.set_field_id(top_);
    table_[top_] = Object::sentinel().raw();

    ++top_;
    return;
  }

  // Reuse existing free element. This is "slow path" that should only be
  // triggered after hot reload.
  intptr_t reused_free = free_head_;
  free_head_ = Smi::Value(Smi::RawCast(table_[free_head_]));
  field.set_field_id(reused_free);
  table_[reused_free] = Object::sentinel().raw();
}

void FieldTable::Free(intptr_t field_id) {
  table_[field_id] = Smi::New(free_head_);
  free_head_ = field_id;
}

void FieldTable::SetAt(intptr_t index, RawInstance* raw_instance) {
  ASSERT(index < capacity_);
  table_[index] = raw_instance;
}

void FieldTable::AllocateIndex(intptr_t index) {
  if (index >= capacity_) {
    const intptr_t new_capacity = index + kCapacityIncrement;
    Grow(new_capacity);
  }

  ASSERT(table_[index] == nullptr);
  if (index >= top_) {
    top_ = index + 1;
  }
}

void FieldTable::Grow(intptr_t new_capacity) {
  ASSERT(new_capacity > capacity_);

  auto new_table = static_cast<RawInstance**>(
      malloc(new_capacity * sizeof(RawInstance*)));  // NOLINT
  memmove(new_table, table_, top_ * sizeof(RawInstance*));
  memset(new_table + top_, 0, (new_capacity - top_) * sizeof(RawInstance*));
  capacity_ = new_capacity;
  old_tables_->Add(table_);
  // Ensure that new_table_ is populated before it is published
  // via store to table_.
  std::atomic_thread_fence(std::memory_order_release);
  table_ = new_table;
  Thread::Current()->field_table_values_ = table_;
}

void FieldTable::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->set_gc_root_type("static fields table");
  visitor->VisitPointers(reinterpret_cast<RawObject**>(&table_[0]),
                         reinterpret_cast<RawObject**>(&table_[top_ - 1]));
  visitor->clear_gc_root_type();
}

}  // namespace dart
