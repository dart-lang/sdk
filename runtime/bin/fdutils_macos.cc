// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>

#include "bin/fdutils.h"


bool FDUtils::SetCloseOnExec(intptr_t fd) {
  intptr_t status;
  status = TEMP_FAILURE_RETRY(fcntl(fd, F_GETFD));
  if (status < 0) {
    perror("fcntl F_GETFD failed");
    return false;
  }
  status |= FD_CLOEXEC;
  if (TEMP_FAILURE_RETRY(fcntl(fd, F_SETFD, status)) < 0) {
    perror("fcntl F_SETFD failed");
    return false;
  }
  return true;
}


static bool SetBlockingHelper(intptr_t fd, bool blocking) {
  intptr_t status;
  status = TEMP_FAILURE_RETRY(fcntl(fd, F_GETFL));
  if (status < 0) {
    perror("fcntl F_GETFL failed");
    return false;
  }
  status = blocking ? (status & ~O_NONBLOCK) : (status | O_NONBLOCK);
  if (TEMP_FAILURE_RETRY(fcntl(fd, F_SETFL, status)) < 0) {
    perror("fcntl F_SETFL failed");
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
  status = TEMP_FAILURE_RETRY(fcntl(fd, F_GETFL));
  if (status < 0) {
    perror("fcntl F_GETFL failed");
    return false;
  }
  *is_blocking = (status & O_NONBLOCK) == 0;
  return true;
}


intptr_t FDUtils::AvailableBytes(intptr_t fd) {
  int available;  // ioctl for FIONREAD expects an 'int*' argument.
  int result = TEMP_FAILURE_RETRY(ioctl(fd, FIONREAD, &available));
  if (result < 0) {
    perror("ioctl FIONREAD failed");
    return result;
  }
#ifdef DEBUG
  ASSERT(available >= 0);
#endif
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
      ASSERT((bytes_read > 0));
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
