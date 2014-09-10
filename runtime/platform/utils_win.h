// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_UTILS_WIN_H_
#define PLATFORM_UTILS_WIN_H_

#include <intrin.h>
#include <stdlib.h>

namespace dart {

inline int Utils::CountLeadingZeros(uword x) {
  unsigned long position;  // NOLINT
#if defined(ARCH_IS_32_BIT)
  _BitScanReverse(&position, x);
#elif defined(ARCH_IS_64_BIT)
  _BitScanReverse64(&position, x);
#else
#error Architecture is not 32-bit or 64-bit.
#endif
  return kBitsPerWord - static_cast<int>(position) - 1;
}


inline int Utils::CountTrailingZeros(uword x) {
  unsigned long result;  // NOLINT
#if defined(ARCH_IS_32_BIT)
  _BitScanForward(&result, x);
#elif defined(ARCH_IS_64_BIT)
  _BitScanForward64(&result, x);
#else
#error Architecture is not 32-bit or 64-bit.
#endif
  return static_cast<int>(result);
}


inline uint16_t Utils::HostToBigEndian16(uint16_t value) {
  return _byteswap_ushort(value);
}


inline uint32_t Utils::HostToBigEndian32(uint32_t value) {
  return _byteswap_ulong(value);
}


inline uint64_t Utils::HostToBigEndian64(uint64_t value) {
  return _byteswap_uint64(value);
}


inline uint16_t Utils::HostToLittleEndian16(uint16_t value) {
  return value;
}


inline uint32_t Utils::HostToLittleEndian32(uint32_t value) {
  return value;
}


inline uint64_t Utils::HostToLittleEndian64(uint64_t value) {
  return value;
}

}  // namespace dart

#endif  // PLATFORM_UTILS_WIN_H_
