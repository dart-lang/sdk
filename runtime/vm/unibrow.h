// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_UNIBROW_H_
#define VM_UNIBROW_H_

#include <sys/types.h>

#include "vm/globals.h"

/**
 * \file
 * Definitions and convenience functions for working with unicode.
 */

namespace unibrow {

// A cache used in case conversion.  It caches the value for characters
// that either have no mapping or map to a single character independent
// of context.  Characters that map to more than one character or that
// map differently depending on context are always looked up.
template <class T, intptr_t size = 256>
class Mapping {
 public:
  inline Mapping() { }
  inline intptr_t get(int32_t c, int32_t n, int32_t* result);
 private:
  friend class Test;
  intptr_t CalculateValue(int32_t c, int32_t n, int32_t* result);
  struct CacheEntry {
    inline CacheEntry() : code_point_(kNoChar), offset_(0) { }
    inline CacheEntry(int32_t code_point, signed offset)
      : code_point_(code_point),
        offset_(offset) { }
    int32_t code_point_;
    signed offset_;
    static const intptr_t kNoChar = (1 << 21) - 1;
  };
  static const intptr_t kSize = size;
  static const intptr_t kMask = kSize - 1;
  CacheEntry entries_[kSize];
};

struct Letter {
  static bool Is(int32_t c);
};
struct Ecma262Canonicalize {
  static const intptr_t kMaxWidth = 1;
  static intptr_t Convert(int32_t c,
                          int32_t n,
                          int32_t* result,
                          bool* allow_caching_ptr);
};
struct Ecma262UnCanonicalize {
  static const intptr_t kMaxWidth = 4;
  static intptr_t Convert(int32_t c,
                          int32_t n,
                          int32_t* result,
                          bool* allow_caching_ptr);
};
struct CanonicalizationRange {
  static const intptr_t kMaxWidth = 1;
  static intptr_t Convert(int32_t c,
                          int32_t n,
                          int32_t* result,
                          bool* allow_caching_ptr);
};

}  // namespace unibrow

#endif  // VM_UNIBROW_H_
