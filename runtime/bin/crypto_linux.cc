// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)

#include <errno.h>
#include <sys/syscall.h>

#include "bin/crypto.h"
#include "platform/memory_sanitizer.h"

namespace dart {
namespace bin {

bool Crypto::GetRandomBytes(intptr_t count, uint8_t* buffer) {
  intptr_t bytes_read = 0;
  do {
    ssize_t res;
    do {
      res = syscall(__NR_getrandom, buffer + bytes_read, count - bytes_read,
                    /*flags=*/0);
    } while (res == -1 && errno == EINTR);
    if (res == -1) {
      return false;
    }
    bytes_read += res;
  } while (bytes_read < count);
  // Not using the libc wrapper `getrandom`, which MSAN is missing an
  // interceptor for anyway.
  MSAN_UNPOISON(buffer, count);
  return true;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
