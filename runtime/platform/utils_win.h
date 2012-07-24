// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_UTILS_WIN_H_
#define PLATFORM_UTILS_WIN_H_

#include <intrin.h>

namespace dart {

inline int Utils::CountTrailingZeros(uword x) {
  unsigned long result;  // NOLINT
#if defined(ARCH_IS_32_BIT)
  _BitScanReverse(&result, x);
#elif defined(ARCH_IS_64_BIT)
  _BitScanReverse64(&result, x);
#else
#error Architecture is not 32-bit or 64-bit.
#endif
  return static_cast<int>(result);
};

}  // namespace dart

#endif  // PLATFORM_UTILS_WIN_H_
