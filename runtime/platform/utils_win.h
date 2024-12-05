// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UTILS_WIN_H_
#define RUNTIME_PLATFORM_UTILS_WIN_H_

#if !defined(RUNTIME_PLATFORM_UTILS_H_)
#error Do not include utils_win.h directly; use utils.h instead.
#endif

#include <intrin.h>
#include <stdlib.h>

namespace dart {

// WARNING: The below functions assume host is always Little Endian!

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

inline char* Utils::StrError(int err, char* buffer, size_t bufsize) {
  DWORD message_size =
      FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                     nullptr, err, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                     buffer, static_cast<DWORD>(bufsize), nullptr);
  if (message_size == 0) {
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      snprintf(buffer, bufsize,
               "FormatMessage failed for error code %d (error %d)\n", err,
               GetLastError());
    }
    snprintf(buffer, bufsize, "OS Error %d", err);
  }
  // Ensure string termination.
  buffer[bufsize - 1] = 0;
  return buffer;
}

}  // namespace dart

#endif  // RUNTIME_PLATFORM_UTILS_WIN_H_
