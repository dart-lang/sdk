// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_WEAK_TABLE_H_
#define VM_WEAK_TABLE_H_

#include "vm/globals.h"

#include "platform/assert.h"
#include "vm/raw_object.h"

namespace dart {

class WeakTable {
 public:
  explicit WeakTable(intptr_t size) : used_(0), count_(0) {
    ASSERT(size >= 0);
    if (size < kMinSize) {
      size = kMinSize;
    }
    data_ = reinterpret_cast<intptr_t*>(calloc(size, kEntrySize * kWordSize));
    size_ = size;
  }

  static WeakTable* NewFrom(WeakTable* original) {
    intptr_t cnt = original->count();
    intptr_t sz = original->size();
    intptr_t new_sz = sz;

    if (cnt <= (sz / 4)) {
      // Reduce the capacity.
      new_sz = sz / 2;
    } else if (cnt > (sz / 2)) {
      // Increase the capacity.
      new_sz = sz * 2;
      if (new_sz < sz) {
        FATAL("Reached impossible state of having more weak table entries"
              " than memory available for heap objects.");
      }
    }
    return new WeakTable(new_sz);
  }

  intptr_t size() const { return size_; }
  intptr_t used() const { return used_; }
  intptr_t count() const { return count_; }

  bool IsValidEntryAt(intptr_t i) const {
    ASSERT(((ValueAt(i) == 0) &&
            ((ObjectAt(i) == NULL) ||
             (data_[ObjectIndex(i)] == kDeletedEntry))) ||
           ((ValueAt(i) != 0) &&
            (ObjectAt(i) != NULL) &&
            (data_[ObjectIndex(i)] != kDeletedEntry)));
    return (data_[ValueIndex(i)] != 0);
  }

  void InvalidateAt(intptr_t i) {
    ASSERT(IsValidEntryAt(i));
    SetValueAt(i, 0);
  }

  RawObject* ObjectAt(intptr_t i) const {
    return reinterpret_cast<RawObject*>(data_[ObjectIndex(i)]);
  }

  intptr_t ValueAt(intptr_t i) const {
    return data_[ValueIndex(i)];
  }

  WeakTable* SetValue(RawObject* key, intptr_t val);

  intptr_t GetValue(RawObject* key) const {
    intptr_t sz = size();
    intptr_t idx = Hash(key) % sz;
    RawObject* obj = ObjectAt(idx);
    while (obj != NULL) {
      if (obj == key) {
        return ValueAt(idx);
      }
      idx = (idx + 1) % sz;
      obj = ObjectAt(idx);
    }
    ASSERT(ValueAt(idx) == 0);
    return 0;
  }

 private:
  enum {
    kObjectOffset = 0,
    kValueOffset,
    kEntrySize,
  };

  static const intptr_t kDeletedEntry = 1;  // Equivalent to a tagged NULL.
  static const intptr_t kMinSize = 8;

  static intptr_t LimitFor(intptr_t size) {
    // Maintain a maximum of 75% fill rate.
    return 3 * (size / 4);
  }
  intptr_t limit() const { return LimitFor(size()); }

  intptr_t index(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < size());
    return i * kEntrySize;
  }

  void set_used(intptr_t val) {
    ASSERT(val <= limit());
    used_ = val;
  }

  void set_count(intptr_t val) {
    ASSERT(val <= limit());
    ASSERT(val <= used());
    count_ = val;
  }

  intptr_t ObjectIndex(intptr_t i) const {
    return index(i) + kObjectOffset;
  }

  intptr_t ValueIndex(intptr_t i) const {
    return index(i) + kValueOffset;
  }

  void SetObjectAt(intptr_t i, RawObject* key) {
    data_[ObjectIndex(i)] = reinterpret_cast<intptr_t>(key);
  }

  void SetValueAt(intptr_t i, intptr_t val) {
    // Setting a value of 0 is equivalent to invalidating the entry.
    if (val == 0) {
      data_[ObjectIndex(i)] = kDeletedEntry;
      set_count(count() - 1);
    }
    data_[ValueIndex(i)] = val;
  }

  WeakTable* Rehash();

  static intptr_t Hash(RawObject* key) {
    return reinterpret_cast<intptr_t>(key) >> kObjectAlignmentLog2;
  }

  // data_ contains size_ tuples of key/value.
  intptr_t* data_;
  // size_ keeps the number of entries in data_. used_ maintains the number of
  // non-NULL entries and will trigger rehashing if needed. count_ stores the
  // number valid entries, and will determine the size_ after rehashing.
  intptr_t size_;
  intptr_t used_;
  intptr_t count_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(WeakTable);
};

}  // namespace dart

#endif  // VM_WEAK_TABLE_H_
