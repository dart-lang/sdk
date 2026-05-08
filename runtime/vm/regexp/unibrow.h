// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REGEXP_UNIBROW_H_
#define RUNTIME_VM_REGEXP_UNIBROW_H_

#include <sys/types.h>

#include "vm/globals.h"

/**
 * \file
 * Definitions and convenience functions for working with unicode.
 */

namespace unibrow {

using uchar = unsigned int;

/**
 * The max length of the result of converting the case of a single
 * character.
 */
const int kMaxMappingSize = 4;

// A cache used in case conversion.  It caches the value for characters
// that either have no mapping or map to a single character independent
// of context.  Characters that map to more than one character or that
// map differently depending on context are always looked up.
template <class T, int size = 256>
class Mapping {
 public:
  inline Mapping() = default;
  inline int get(uchar c, uchar n, uchar* result);

 private:
  friend class Test;
  int CalculateValue(uchar c, uchar n, uchar* result);
  struct CacheEntry {
    inline CacheEntry() : code_point_(kNoChar), offset_(0) {}
    inline CacheEntry(uchar code_point, signed offset)
        : code_point_(code_point), offset_(offset) {}
    uchar code_point_;
    signed offset_;
    static const int kNoChar = (1 << 21) - 1;
  };
  static const int kSize = size;
  static const int kMask = kSize - 1;
  CacheEntry entries_[kSize];
};

struct Letter {
  static bool Is(uchar c);
};
struct Ecma262Canonicalize {
  static const int kMaxWidth = 1;
  static int Convert(uchar c, uchar n, uchar* result, bool* allow_caching_ptr);
};
struct Ecma262UnCanonicalize {
  static const int kMaxWidth = 4;
  static int Convert(uchar c, uchar n, uchar* result, bool* allow_caching_ptr);
};
struct CanonicalizationRange {
  static const int kMaxWidth = 1;
  static int Convert(uchar c, uchar n, uchar* result, bool* allow_caching_ptr);
};

}  // namespace unibrow

#endif  // RUNTIME_VM_REGEXP_UNIBROW_H_
