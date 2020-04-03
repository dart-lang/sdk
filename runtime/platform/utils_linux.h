// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UTILS_LINUX_H_
#define RUNTIME_PLATFORM_UTILS_LINUX_H_

#if !defined(RUNTIME_PLATFORM_UTILS_H_)
#error Do not include utils_linux.h directly; use utils.h instead.
#endif

#include <endian.h>  // NOLINT

namespace dart {

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
