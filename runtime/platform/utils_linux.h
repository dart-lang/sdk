// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_UTILS_LINUX_H_
#define PLATFORM_UTILS_LINUX_H_

namespace dart {

inline int Utils::CountTrailingZeros(uint32_t x) {
  return __builtin_ctzl(x);
};

inline int Utils::CountTrailingZeros(uint64_t x) {
  return __builtin_ctzll(x);
};

}  // namespace dart

#endif  // PLATFORM_UTILS_LINUX_H_
