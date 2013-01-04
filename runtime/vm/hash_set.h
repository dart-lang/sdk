// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_HASH_SET_H_
#define VM_HASH_SET_H_

#include "vm/allocation.h"
#include "platform/utils.h"

namespace dart {

class HashSet {
 public:
  HashSet(intptr_t size, intptr_t fill_ratio)
      : keys_(new uword[size]),
        size_mask_(size - 1),
        growth_limit_((size * fill_ratio) / 100),
        count_(0),
        fill_ratio_(fill_ratio) {
    ASSERT(Utils::IsPowerOfTwo(size));
    ASSERT(fill_ratio < 100);
    memset(keys_, 0, size * sizeof(*keys_));
  }

  ~HashSet() {
    delete[] keys_;
  }

  intptr_t Size() const {
    return size_mask_ + 1;
  }

  intptr_t Count() const {
    return count_;
  }

  uword At(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < Size());
    return keys_[i];
  }

  // Returns false if the caller should stop adding entries to this HashSet.
  bool Add(uword value) {
    ASSERT(value != 0);
    ASSERT(count_ < growth_limit_);
    intptr_t hash = Hash(value);
    while (true) {
      if (keys_[hash] == value) {
        return true;
      } else if (SlotIsEmpty(hash)) {
        keys_[hash] = value;
        count_++;
        return (count_ < growth_limit_);
      }
      hash = (hash + 1) & size_mask_;
      // Ensure that we do not end up looping forever.
      ASSERT(hash != Hash(value));
    }
    UNREACHABLE();
  }

  bool Contains(uword value) const {
    if (value == 0) {
      return false;
    }
    intptr_t hash = Hash(value);
    while (true) {
      if (keys_[hash] == value) {
        return true;
      } else if (SlotIsEmpty(hash)) {
        return false;
      }
      hash = (hash + 1) & size_mask_;
      // Ensure that we do not end up looping forever.
      ASSERT(hash != Hash(value));
    }
    UNREACHABLE();
  }

 private:
  intptr_t Hash(uword value) const {
    return value & size_mask_;
  }

  // Returns true if the given slot does not contain a value.
  bool SlotIsEmpty(intptr_t index) const {
    return keys_[index] == 0;
  }

  uword* keys_;
  intptr_t size_mask_;
  intptr_t growth_limit_;
  intptr_t count_;
  intptr_t fill_ratio_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(HashSet);
};

}  // namespace dart

#endif  // VM_HASH_SET_H_
