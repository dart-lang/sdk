// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_UTILS_FUCHSIA_H_
#define PLATFORM_UTILS_FUCHSIA_H_

#include "platform/assert.h"

namespace dart {

inline int Utils::CountLeadingZeros(uword x) {
  UNIMPLEMENTED();
  return 0;
}


inline int Utils::CountTrailingZeros(uword x) {
  UNIMPLEMENTED();
  return 0;
}


inline uint16_t Utils::HostToBigEndian16(uint16_t value) {
  UNIMPLEMENTED();
  return 0;
}


inline uint32_t Utils::HostToBigEndian32(uint32_t value) {
  UNIMPLEMENTED();
  return 0;
}


inline uint64_t Utils::HostToBigEndian64(uint64_t value) {
  UNIMPLEMENTED();
  return 0;
}


inline uint16_t Utils::HostToLittleEndian16(uint16_t value) {
  UNIMPLEMENTED();
  return 0;
}


inline uint32_t Utils::HostToLittleEndian32(uint32_t value) {
  UNIMPLEMENTED();
  return 0;
}


inline uint64_t Utils::HostToLittleEndian64(uint64_t value) {
  UNIMPLEMENTED();
  return 0;
}


inline char* Utils::StrError(int err, char* buffer, size_t bufsize) {
  UNIMPLEMENTED();
  return NULL;
}

}  // namespace dart

#endif  // PLATFORM_UTILS_FUCHSIA_H_
