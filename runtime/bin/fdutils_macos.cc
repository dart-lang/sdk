// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include "bin/fdutils.h"

#include <errno.h>      // NOLINT
#include <fcntl.h>      // NOLINT
#include <sys/ioctl.h>  // NOLINT
#include <unistd.h>     // NOLINT

#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

bool FDUtils::SetCloseOnExec(intptr_t fd) {
  intptr_t status;
  status = NO_RETRY_EXPECTED(fcntl(fd, F_GETFD));
  if (status < 0) {
    perror("fcntl(F_GETFD) failed");
    return false;
  }
  status |= FD_CLOEXEC;
  if (NO_RETRY_EXPECTED(fcntl(fd, F_SETFD, status)) < 0) {
    perror("fcntl(F_SETFD, FD_CLOEXEC) failed");
    return false;
  }
  return true;
}

static bool SetBlockingHelper(intptr_t fd, bool blocking) {
  intptr_t status;
  status = NO_RETRY_EXPECTED(fcntl(fd, F_GETFL));
  if (status < 0) {
    perror("fcntl(F_GETFL) failed");
    return false;
  }
  status = blocking ? (status & ~O_NONBLOCK) : (status | O_NONBLOCK);
  if (NO_RETRY_EXPECTED(fcntl(fd, F_SETFL, status)) < 0) {
    perror("fcntl(F_SETFL, O_NONBLOCK) failed");
    return false;
  }
  return true;
}

bool FDUtils::SetNonBlocking(intptr_t fd) {
  return SetBlockingHelper(fd, false);
}

bool FDUtils::SetBlocking(intptr_t fd) {
  return SetBlockingHelper(fd, true);
}

bool FDUtils::IsBlocking(intptr_t fd, bool* is_blocking) {
  intptr_t status;
  status = NO_RETRY_EXPECTED(fcntl(fd, F_GETFL));
  if (status < 0) {
    return false;
  }
  *is_blocking = (status & O_NONBLOCK) == 0;
  return true;
}

intptr_t FDUtils::AvailableBytes(intptr_t fd) {
  int available;  // ioctl for FIONREAD expects an 'int*' argument.
  int result = NO_RETRY_EXPECTED(ioctl(fd, FIONREAD, &available));
  if (result < 0) {
    return result;
  }
  ASSERT(available >= 0);
  return static_cast<intptr_t>(available);
}

ssize_t FDUtils::ReadFromBlocking(int fd, void* buffer, size_t count) {
#ifdef DEBUG
  bool is_blocking = false;
  ASSERT(FDUtils::IsBlocking(fd, &is_blocking));
  ASSERT(is_blocking);
#endif
  size_t remaining = count;
  char* buffer_pos = reinterpret_cast<char*>(buffer);
  while (remaining > 0) {
    ssize_t bytes_read = TEMP_FAILURE_RETRY(read(fd, buffer_pos, remaining));
    if (bytes_read == 0) {
      return count - remaining;
    } else if (bytes_read == -1) {
      ASSERT(EAGAIN == EWOULDBLOCK);
      // Error code EWOULDBLOCK should only happen for non blocking
      // file descriptors.
      ASSERT(errno != EWOULDBLOCK);
      return -1;
    } else {
      ASSERT(bytes_read > 0);
      remaining -= bytes_read;
      buffer_pos += bytes_read;
    }
  }
  return count;
}

ssize_t FDUtils::WriteToBlocking(int fd, const void* buffer, size_t count) {
#ifdef DEBUG
  bool is_blocking = false;
  ASSERT(FDUtils::IsBlocking(fd, &is_blocking));
  ASSERT(is_blocking);
#endif
  size_t remaining = count;
  char* buffer_pos = const_cast<char*>(reinterpret_cast<const char*>(buffer));
  while (remaining > 0) {
    ssize_t bytes_written =
        TEMP_FAILURE_RETRY(write(fd, buffer_pos, remaining));
    if (bytes_written == 0) {
      return count - remaining;
    } else if (bytes_written == -1) {
      ASSERT(EAGAIN == EWOULDBLOCK);
      // Error code EWOULDBLOCK should only happen for non blocking
      // file descriptors.
      ASSERT(errno != EWOULDBLOCK);
      return -1;
    } else {
      ASSERT(bytes_written > 0);
      remaining -= bytes_written;
      buffer_pos += bytes_written;
    }
  }
  return count;
}

void FDUtils::SaveErrorAndClose(intptr_t fd) {
  int err = errno;
  VOID_TEMP_FAILURE_RETRY(close(fd));
  errno = err;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_MACOS)
