// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_UTILS_WIN_H_
#define PLATFORM_UTILS_WIN_H_

#include <intrin.h>

namespace dart {

inline int Utils::CountTrailingZeros(uint32_t x) {
  unsigned long result;  // NOLINT
  _BitScanReverse(&result, x);
  return reinterpret_cast<int>(result);
};

inline int Utils::CountTrailingZeros(uint64_t x) {
  unsigned long result;  // NOLINT
  _BitScanReverse64(&result, x);
  return reinterpret_cast<int>(result);
};

}  // namespace dart

#endif  // PLATFORM_UTILS_WIN_H_
