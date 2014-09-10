// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_UTILS_MACOS_H_
#define PLATFORM_UTILS_MACOS_H_

#include <libkern/OSByteOrder.h>  // NOLINT

namespace dart {

inline int Utils::CountLeadingZeros(uword x) {
#if defined(ARCH_IS_32_BIT)
  return __builtin_clzl(x);
#elif defined(ARCH_IS_64_BIT)
  return __builtin_clzll(x);
#else
#error Architecture is not 32-bit or 64-bit.
#endif
}


inline int Utils::CountTrailingZeros(uword x) {
#if defined(ARCH_IS_32_BIT)
  return __builtin_ctzl(x);
#elif defined(ARCH_IS_64_BIT)
  return __builtin_ctzll(x);
#else
#error Architecture is not 32-bit or 64-bit.
#endif
}


inline uint16_t Utils::HostToBigEndian16(uint16_t value) {
  return OSSwapHostToBigInt16(value);
}


inline uint32_t Utils::HostToBigEndian32(uint32_t value) {
  return OSSwapHostToBigInt32(value);
}


inline uint64_t Utils::HostToBigEndian64(uint64_t value) {
  return OSSwapHostToBigInt64(value);
}


inline uint16_t Utils::HostToLittleEndian16(uint16_t value) {
  return OSSwapHostToLittleInt16(value);
}


inline uint32_t Utils::HostToLittleEndian32(uint32_t value) {
  return OSSwapHostToLittleInt32(value);
}


inline uint64_t Utils::HostToLittleEndian64(uint64_t value) {
  return OSSwapHostToLittleInt64(value);
}

}  // namespace dart

#endif  // PLATFORM_UTILS_MACOS_H_
