// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/weak_table.h"

#include "platform/assert.h"
#include "vm/raw_object.h"

namespace dart {

intptr_t WeakTable::SizeFor(intptr_t count, intptr_t size) {
  intptr_t result = size;
  if (count <= (size / 4)) {
    // Reduce the capacity.
    result = size / 2;
  } else {
    // Increase the capacity.
    result = size * 2;
    if (result < size) {
      FATAL(
          "Reached impossible state of having more weak table entries"
          " than memory available for heap objects.");
    }
  }
  if (result < kMinSize) {
    result = kMinSize;
  }
  return result;
}

void WeakTable::SetValueExclusive(ObjectPtr key, intptr_t val) {
  intptr_t mask = size() - 1;
  intptr_t idx = Hash(key) & mask;
  intptr_t empty_idx = -1;
  ObjectPtr obj = ObjectAtExclusive(idx);

  while (obj != static_cast<ObjectPtr>(kNoEntry)) {
    if (obj == key) {
      SetValueAt(idx, val);
      return;
    } else if ((empty_idx < 0) &&
               (static_cast<intptr_t>(obj) == kDeletedEntry)) {
      empty_idx = idx;  // Insert at this location if not found.
    }
    idx = (idx + 1) & mask;
    obj = ObjectAtExclusive(idx);
  }

  if (val == 0) {
    // Do not enter an invalid value. Associating 0 with a key deletes it from
    // this weak table above in SetValueAt. If the key was not present in the
    // weak table we are done.
    return;
  }

  if (empty_idx >= 0) {
    // We will be reusing a slot below.
    set_used(used() - 1);
    idx = empty_idx;
  }

  ASSERT(!IsValidEntryAtExclusive(idx));
  // Set the key and value.
  SetObjectAt(idx, key);
  SetValueAt(idx, val);
  // Update the counts.
  set_used(used() + 1);
  set_count(count() + 1);

  // Rehash if needed to ensure that there are empty slots available.
  if (used_ >= limit()) {
    Rehash();
  }
}

void WeakTable::Reset() {
  intptr_t* old_data = data_;
  used_ = 0;
  count_ = 0;
  size_ = kMinSize;
  free(old_data);
  data_ = reinterpret_cast<intptr_t*>(malloc(size_ * kEntrySize * kWordSize));
  for (intptr_t i = 0; i < size_; i++) {
    data_[ObjectIndex(i)] = kNoEntry;
    data_[ValueIndex(i)] = kNoValue;
  }
}

void WeakTable::Forward(ObjectPointerVisitor* visitor) {
  if (used_ == 0) return;

  for (intptr_t i = 0; i < size_; i++) {
    if (IsValidEntryAtExclusive(i)) {
      visitor->VisitPointer(ObjectPointerAt(i));
    }
  }

  Rehash();
}

void WeakTable::Rehash() {
  intptr_t old_size = size();
  intptr_t* old_data = data_;

  intptr_t new_size = SizeFor(count(), size());
  ASSERT(Utils::IsPowerOfTwo(new_size));
  intptr_t* new_data =
      reinterpret_cast<intptr_t*>(malloc(new_size * kEntrySize * kWordSize));
  for (intptr_t i = 0; i < new_size; i++) {
    new_data[ObjectIndex(i)] = kNoEntry;
    new_data[ValueIndex(i)] = kNoValue;
  }

  intptr_t mask = new_size - 1;
  set_used(0);
  for (intptr_t i = 0; i < old_size; i++) {
    if (IsValidEntryAtExclusive(i)) {
      // Find the new hash location for this entry.
      ObjectPtr key = ObjectAtExclusive(i);
      intptr_t idx = Hash(key) & mask;
      ObjectPtr obj = static_cast<ObjectPtr>(new_data[ObjectIndex(idx)]);
      while (obj != static_cast<ObjectPtr>(kNoEntry)) {
        ASSERT(obj != key);  // Duplicate entry is not expected.
        idx = (idx + 1) & mask;
        obj = static_cast<ObjectPtr>(new_data[ObjectIndex(idx)]);
      }

      new_data[ObjectIndex(idx)] = static_cast<intptr_t>(key);
      new_data[ValueIndex(idx)] = ValueAtExclusive(i);
      set_used(used() + 1);
    }
  }
  // We should only have used valid entries.
  ASSERT(used() == count());

  // Switch to using the newly allocated backing store.
  size_ = new_size;
  data_ = new_data;
  free(old_data);
}

}  // namespace dart
