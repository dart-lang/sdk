// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_UTILS_ANDROID_H_
#define PLATFORM_UTILS_ANDROID_H_

namespace dart {

inline int Utils::CountTrailingZeros(uword x) {
#if defined(ARCH_IS_32_BIT)
  return __builtin_ctzl(x);
#elif defined(ARCH_IS_64_BIT)
  return __builtin_ctzll(x);
#else
#error Architecture is not 32-bit or 64-bit.
#endif
};

}  // namespace dart

#endif  // PLATFORM_UTILS_ANDROID_H_
