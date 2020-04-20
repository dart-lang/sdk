// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_LINUX)

#include <errno.h>  // NOLINT
#include <fcntl.h>  // NOLINT

#include "bin/crypto.h"
#include "bin/fdutils.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

bool Crypto::GetRandomBytes(intptr_t count, uint8_t* buffer) {
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

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_LINUX)
