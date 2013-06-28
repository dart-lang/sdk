// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/weak_table.h"

#include "platform/assert.h"
#include "vm/raw_object.h"

namespace dart {

WeakTable* WeakTable::SetValue(RawObject* key, intptr_t val) {
  intptr_t sz = size();
  intptr_t idx = Hash(key) % sz;
  intptr_t empty_idx = -1;
  RawObject* obj = ObjectAt(idx);

  while (obj != NULL) {
    if (obj == key) {
      SetValueAt(idx, val);
      return this;
    } else if ((empty_idx < 0) &&
               (reinterpret_cast<intptr_t>(obj) == kDeletedEntry)) {
      empty_idx = idx;  // Insert at this location if not found.
    }
    idx = (idx + 1) % sz;
    obj = ObjectAt(idx);
  }

  if (val == 0) {
    // Do not enter an invalid value. Associating 0 with a key deletes it from
    // this weak table above in SetValueAt. If the key was not present in the
    // weak table we are done.
    return this;
  }

  if (empty_idx >= 0) {
    // We will be reusing a slot below.
    set_used(used() - 1);
    idx = empty_idx;
  }

  ASSERT(!IsValidEntryAt(idx));
  // Set the key and value.
  SetObjectAt(idx, key);
  SetValueAt(idx, val);
  // Update the counts.
  set_used(used() + 1);
  set_count(count() + 1);

  // Rehash if needed to ensure that there are empty slots available.
  if (used_ >= limit()) {
    return Rehash();
  }
  return this;
}


WeakTable* WeakTable::Rehash() {
  intptr_t sz = size();
  WeakTable* result = NewFrom(this);

  for (intptr_t i = 0; i < sz; i++) {
    if (IsValidEntryAt(i)) {
      WeakTable* temp = result->SetValue(ObjectAt(i), ValueAt(i));
      ASSERT(temp == result);
    }
  }
  return result;
}

}  // namespace dart
