// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UTILS_MACOS_H_
#define RUNTIME_PLATFORM_UTILS_MACOS_H_

#if !defined(RUNTIME_PLATFORM_UTILS_H_)
#error Do not include utils_macos.h directly; use utils.h instead.
#endif

#include <AvailabilityMacros.h>
#include <libkern/OSByteOrder.h>  // NOLINT

namespace dart {

namespace internal {

// Returns the system's Mac OS X minor version. This is the |y| value
// in 10.y or 10.y.z.
int32_t MacOSXMinorVersion();

}  // namespace internal

// Run-time OS version checks.
#define DEFINE_IS_OS_FUNCS(V, TEST_DEPLOYMENT_TARGET)                          \
  inline bool IsOS10_##V() {                                                   \
    TEST_DEPLOYMENT_TARGET(>, V, false)                                        \
    return internal::MacOSXMinorVersion() == V;                                \
  }                                                                            \
  inline bool IsAtLeastOS10_##V() {                                            \
    TEST_DEPLOYMENT_TARGET(>=, V, true)                                        \
    return internal::MacOSXMinorVersion() >= V;                                \
  }                                                                            \
  inline bool IsAtMostOS10_##V() {                                             \
    TEST_DEPLOYMENT_TARGET(>, V, false)                                        \
    return internal::MacOSXMinorVersion() <= V;                                \
  }

#define TEST_DEPLOYMENT_TARGET(OP, V, RET)                                     \
  if (MAC_OS_X_VERSION_MIN_REQUIRED OP MAC_OS_X_VERSION_10_##V) return RET;
#define IGNORE_DEPLOYMENT_TARGET(OP, V, RET)

DEFINE_IS_OS_FUNCS(9, TEST_DEPLOYMENT_TARGET)
DEFINE_IS_OS_FUNCS(10, TEST_DEPLOYMENT_TARGET)

#ifdef MAC_OS_X_VERSION_10_11
DEFINE_IS_OS_FUNCS(11, TEST_DEPLOYMENT_TARGET)
#else
DEFINE_IS_OS_FUNCS(11, IGNORE_DEPLOYMENT_TARGET)
#endif

#ifdef MAC_OS_X_VERSION_10_12
DEFINE_IS_OS_FUNCS(12, TEST_DEPLOYMENT_TARGET)
#else
DEFINE_IS_OS_FUNCS(12, IGNORE_DEPLOYMENT_TARGET)
#endif

#ifdef MAC_OS_X_VERSION_10_13
DEFINE_IS_OS_FUNCS(13, TEST_DEPLOYMENT_TARGET)
#else
DEFINE_IS_OS_FUNCS(13, IGNORE_DEPLOYMENT_TARGET)
#endif

#ifdef MAC_OS_X_VERSION_10_14
DEFINE_IS_OS_FUNCS(14, TEST_DEPLOYMENT_TARGET)
#else
DEFINE_IS_OS_FUNCS(14, IGNORE_DEPLOYMENT_TARGET)
#endif

#ifdef MAC_OS_X_VERSION_10_15
DEFINE_IS_OS_FUNCS(15, TEST_DEPLOYMENT_TARGET)
#else
DEFINE_IS_OS_FUNCS(15, IGNORE_DEPLOYMENT_TARGET)
#endif

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

inline char* Utils::StrError(int err, char* buffer, size_t bufsize) {
  if (strerror_r(err, buffer, bufsize) != 0) {
    snprintf(buffer, bufsize, "%s", "strerror_r failed");
  }
  return buffer;
}

}  // namespace dart

#endif  // RUNTIME_PLATFORM_UTILS_MACOS_H_
