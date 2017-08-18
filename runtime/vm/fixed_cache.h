// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_FIXED_CACHE_H_
#define RUNTIME_VM_FIXED_CACHE_H_

#include <stddef.h>
#include <stdint.h>

namespace dart {

// A simple sorted fixed size Key-Value storage.
//
// Assumes both Key and Value are default-constructible objects.
//
// Keys must be comparable with operator<.
//
// Duplicates are not allowed - check with Lookup before insertion.
//
template <class K, class V, intptr_t kCapacity>
class FixedCache {
 public:
  struct Entry {
    K key;
    V value;
  };

  FixedCache() : length_(0) {}

  ~FixedCache() { Clear(); }

  V* Lookup(K key) {
    intptr_t i = LowerBound(key);
    if (i != length_ && pairs_[i].key == key) return &pairs_[i].value;
    return NULL;
  }

  void Insert(K key, V value) {
    intptr_t i = LowerBound(key);

    if (length_ == kCapacity) {
      length_ = kCapacity - 1;
      if (i == kCapacity) i = kCapacity - 1;
    }

    for (intptr_t j = length_ - 1; j >= i; j--) {
      pairs_[j + 1] = pairs_[j];
    }

    length_ += 1;
    pairs_[i].key = key;
    pairs_[i].value = value;
  }

  void Clear() { length_ = 0; }

 private:
  intptr_t LowerBound(K key) {
    intptr_t low = 0, high = length_;
    while (low != high) {
      intptr_t mid = low + (high - low) / 2;
      if (key < pairs_[mid].key) {
        high = mid;
      } else if (key > pairs_[mid].key) {
        low = mid + 1;
      } else {
        low = high = mid;
      }
    }
    return low;
  }

  Entry pairs_[kCapacity];  // Sorted array of pairs.
  intptr_t length_;
};

}  // namespace dart

#endif  // RUNTIME_VM_FIXED_CACHE_H_
