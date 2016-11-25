// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UTILS_LINUX_H_
#define RUNTIME_PLATFORM_UTILS_LINUX_H_

#include <endian.h>  // NOLINT

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
  return htobe16(value);
}


inline uint32_t Utils::HostToBigEndian32(uint32_t value) {
  return htobe32(value);
}


inline uint64_t Utils::HostToBigEndian64(uint64_t value) {
  return htobe64(value);
}


inline uint16_t Utils::HostToLittleEndian16(uint16_t value) {
  return htole16(value);
}


inline uint32_t Utils::HostToLittleEndian32(uint32_t value) {
  return htole32(value);
}


inline uint64_t Utils::HostToLittleEndian64(uint64_t value) {
  return htole64(value);
}


inline char* Utils::StrError(int err, char* buffer, size_t bufsize) {
#if !defined(__GLIBC__) ||                                                     \
    ((_POSIX_C_SOURCE >= 200112L || _XOPEN_SOURCE >= 600) && !_GNU_SOURCE)
  // Use the XSI version.
  if (strerror_r(err, buffer, bufsize) != 0) {
    snprintf(buffer, bufsize, "%s", "strerror_r failed");
  }
  return buffer;
#else
  // Use the GNU specific version.
  return strerror_r(err, buffer, bufsize);
#endif
}

}  // namespace dart

#endif  // RUNTIME_PLATFORM_UTILS_LINUX_H_
