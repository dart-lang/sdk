// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)

#include <errno.h>
#include <fcntl.h>
#include <sys/syscall.h>

#include "bin/crypto.h"
#include "bin/fdutils.h"
#include "platform/memory_sanitizer.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

static bool GetRandomFromDev(intptr_t count, uint8_t* buffer) {
  ThreadSignalBlocker signal_blocker(SIGPROF);
  intptr_t fd = TEMP_FAILURE_RETRY_NO_SIGNAL_BLOCKER(
      open("/dev/urandom", O_RDONLY | O_CLOEXEC));
  if (fd < 0) {
    return false;
  }
  intptr_t bytes_read = 0;
  do {
    int res = TEMP_FAILURE_RETRY_NO_SIGNAL_BLOCKER(
        read(fd, buffer + bytes_read, count - bytes_read));
    if (res < 0) {
      int err = errno;
      close(fd);
      errno = err;
      return false;
    }
    bytes_read += res;
  } while (bytes_read < count);
  close(fd);
  return true;
}

bool Crypto::GetRandomBytes(intptr_t count, uint8_t* buffer) {
  intptr_t bytes_read = 0;
  do {
    ssize_t res;
    do {
      res = syscall(__NR_getrandom, buffer + bytes_read, count - bytes_read,
                    /*flags=*/0);
    } while (res == -1 && errno == EINTR);
    if (res == -1) {
      if (errno == ENOSYS) {
        return GetRandomFromDev(count, buffer);
      }
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
