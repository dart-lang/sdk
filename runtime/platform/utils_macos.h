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

// Returns the running system's Mac OS X version which matches the encoding
// of MAC_OS_X_VERSION_* defines in AvailabilityMacros.h
int32_t MacOSXVersion();

}  // namespace internal

// Run-time OS version checks.
#define DEFINE_IS_OS_FUNCS(VERSION)                                            \
  inline bool IsAtLeastOS##VERSION() {                                         \
    return (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_##VERSION) ||    \
           (internal::MacOSXVersion() >= MAC_OS_X_VERSION_##VERSION);          \
  }

DEFINE_IS_OS_FUNCS(10_14)

// Returns |nullptr| if the current Mac OS X version satisfies minimum required
// Mac OS X version set during compilation (MAC_OS_X_VERSION_MIN_REQUIRED).
//
// Otherwise returns a malloc allocated error string with human readable
// current and expected versions.
char* CheckIsAtLeastMinRequiredMacOSVersion();

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
