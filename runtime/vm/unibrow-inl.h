// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_UNIBROW_INL_H_
#define VM_UNIBROW_INL_H_

#include "vm/unibrow.h"

#include "platform/assert.h"

namespace unibrow {

template <class T, intptr_t s> intptr_t Mapping<T, s>::get(
    int32_t c, int32_t n, int32_t* result) {
  CacheEntry entry = entries_[c & kMask];
  if (entry.code_point_ == c) {
    if (entry.offset_ == 0) {
      return 0;
    } else {
      result[0] = c + entry.offset_;
      return 1;
    }
  } else {
    return CalculateValue(c, n, result);
  }
}

template <class T, intptr_t s> intptr_t Mapping<T, s>::CalculateValue(
    int32_t c, int32_t n, int32_t* result) {
  bool allow_caching = true;
  intptr_t length = T::Convert(c, n, result, &allow_caching);
  if (allow_caching) {
    if (length == 1) {
      entries_[c & kMask] = CacheEntry(c, result[0] - c);
      return 1;
    } else {
      entries_[c & kMask] = CacheEntry(c, 0);
      return 0;
    }
  } else {
    return length;
  }
}

}  // namespace unibrow

#endif  // VM_UNIBROW_INL_H_
